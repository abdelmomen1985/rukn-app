/// «تحليلات الزوار» — the store's own first-party analytics, sent to Medusa
/// (`POST /store/analytics/collect`). Port of rukn-site/src/lib/site-analytics.ts.
///
/// - **vid** — a random id kept in shared_preferences. The server hashes it under a daily salt,
///   so a visitor is one visitor for one day only.
/// - **sid** — a random session id, rotated after 30 minutes without an event.
/// - Events are queued and sent every 5 s, at 10 events, and when the app goes to the background.
/// - **Every public call is wrapped.** Analytics must never be able to break a screen or a checkout,
///   and no call waits on the network: a failed batch is dropped, as on the site.
///
/// The pure parts ([buildAnalyticsPayload], [AnalyticsSession], [EventQueue]) take their clock,
/// id source and transport from the caller, so tests do no I/O.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';

const String analyticsPath = '/store/analytics/collect';

const String _vidKey = 'rukn_analytics_vid';
const String _sidKey = 'rukn_analytics_sid';
const String _currency = 'SAR';

/// One queued event. Field names are the wire names (`product_id`, `event_id`…).
class SiteEvent {
  const SiteEvent({
    required this.name,
    required this.ts,
    this.page,
    this.productId,
    this.variantId,
    this.value,
    this.currency,
    this.eventId,
    this.props,
  });

  final String name;
  final int ts;
  final String? page;
  final String? productId;
  final String? variantId;
  final double? value;
  final String? currency;
  final String? eventId;
  final Map<String, Object>? props;

  Map<String, dynamic> toJson() => {
        'name': name,
        'ts': ts,
        if (page != null) 'page': page,
        if (productId != null) 'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        if (value != null) 'value': value,
        if (currency != null) 'currency': currency,
        if (eventId != null) 'event_id': eventId,
        if (props != null && props!.isNotEmpty) 'props': props,
      };
}

/// The request body for one batch — the same shape the site sends. The app has no ad attribution,
/// so [attribution] is omitted. `platform` names the device the events came from.
Map<String, dynamic> buildAnalyticsPayload({
  required List<SiteEvent> events,
  required String sid,
  required String vid,
  required String platform,
  Map<String, dynamic>? attribution,
}) =>
    {
      'v': 1,
      'platform': platform,
      'vid': vid,
      'sid': sid,
      'attribution': ?attribution,
      'events': [for (final e in events) e.toJson()],
    };

/// The session id, rotated after [idle] without activity. Touching it extends the session.
/// Port of `sessionId()` in site-analytics.ts; the clock is the caller's `now` argument.
class AnalyticsSession {
  AnalyticsSession({required this.newId, this.idle = const Duration(minutes: 30)});

  final String Function() newId;
  final Duration idle;
  String? _id;
  DateTime? _last;

  String? get id => _id;
  DateTime? get last => _last;

  /// The session id for activity at [now].
  String touch(DateTime now) {
    final id = _id;
    final last = _last;
    if (id == null || last == null || now.difference(last) >= idle) {
      _id = newId();
    }
    _last = now;
    return _id!;
  }

  /// Continues a session stored by an earlier run of the app.
  void restore(String id, DateTime last) {
    _id = id;
    _last = last;
  }
}

/// The unsent events, oldest first. When full, the oldest event makes room for the newest.
class EventQueue {
  EventQueue({this.maxLength = 100});

  final int maxLength;
  final List<SiteEvent> _items = [];

  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;

  void add(SiteEvent event) {
    if (_items.length >= maxLength) _items.removeAt(0);
    _items.add(event);
  }

  /// Removes and returns up to [max] of the oldest events.
  List<SiteEvent> take(int max) {
    final n = min(max, _items.length);
    final batch = _items.sublist(0, n);
    _items.removeRange(0, n);
    return batch;
  }
}

/// Where the visitor and session ids live between launches. shared_preferences in the app.
abstract class AnalyticsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PrefsAnalyticsStore implements AnalyticsStore {
  @override
  Future<String?> read(String key) async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
}

String randomId() {
  Random rng;
  try {
    rng = Random.secure();
  } catch (_) {
    rng = Random(DateTime.now().microsecondsSinceEpoch);
  }
  return List.generate(16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

double _money(double n) => (n * 100).round() / 100;

class SiteAnalytics {
  SiteAnalytics({
    required Future<void> Function(Map<String, dynamic> body) send,
    required AnalyticsStore store,
    DateTime Function()? now,
    String Function()? newId,
    this.platform = 'android',
    this.flushInterval = const Duration(seconds: 5),
    this.flushAt = 10,
    this.batchSize = 25,
    this.maxQueue = 100,
    bool listenToLifecycle = false,
  })  : _send = send,
        _store = store,
        _now = now ?? DateTime.now,
        _newId = newId ?? randomId,
        _session = AnalyticsSession(newId: newId ?? randomId),
        _queue = EventQueue(maxLength: maxQueue) {
    if (listenToLifecycle) {
      try {
        _lifecycle = AppLifecycleListener(onHide: () => unawaited(flush()), onPause: () => unawaited(flush()));
      } catch (_) {
        // no widgets binding (plain Dart): the timer and the flush-at-10 still work
      }
    }
  }

  static SiteAnalytics? _shared;

  /// The app-wide instance, wired to the real API. Created on first use.
  static SiteAnalytics get shared => _shared ??= SiteAnalytics(
        send: (body) async {
          // The web build is for development and store screenshots only; keep it out of the stats.
          if (kIsWeb) return;
          await Api.post(analyticsPath, body);
        },
        store: PrefsAnalyticsStore(),
        platform: _platformName(),
        listenToLifecycle: true,
      );

  static String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'other',
    };
  }

  final Future<void> Function(Map<String, dynamic> body) _send;
  final AnalyticsStore _store;
  final DateTime Function() _now;
  final String Function() _newId;
  final String platform;
  final Duration flushInterval;
  final int flushAt;
  final int batchSize;
  final int maxQueue;
  final AnalyticsSession _session;
  final EventQueue _queue;

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  String _page = '';
  Future<String>? _vidFuture;
  Future<void>? _sessionRestore;

  // ── Hooks: one line per storefront event ──────────────────────────────────

  /// A page view. Repeats of the same location in a row are not counted twice.
  void pageView(String location) => _guard(() {
        if (location.isEmpty || location == _page) return;
        _page = location;
        _enqueue(SiteEvent(name: 'page_view', ts: _ts(), page: location));
      });

  void productViewed({required String productId, required String variantId, required double value}) =>
      _commerce('product_viewed', productId: productId, variantId: variantId, value: value);

  void addedToCart({required String productId, required String variantId, required double value}) =>
      _commerce('added_to_cart', productId: productId, variantId: variantId, value: value);

  void checkoutStarted(double value) => _commerce('checkout_started', value: value);

  void paymentInfoSubmitted(double value) => _commerce('payment_info_submitted', value: value);

  /// The purchase. [orderId] is the event id, so a repeat of the same order is one purchase.
  void checkoutCompleted({required String orderId, required double value}) =>
      _commerce('checkout_completed', value: value, eventId: orderId);

  void search(String query) => _guard(() {
        final q = query.trim();
        if (q.isEmpty) return;
        _enqueue(SiteEvent(
          name: 'search',
          ts: _ts(),
          page: _page.isEmpty ? null : _page,
          props: {'query': q.length > 120 ? q.substring(0, 120) : q},
        ));
      });

  void _commerce(
    String name, {
    String? productId,
    String? variantId,
    required double value,
    String? eventId,
  }) =>
      _guard(() {
        _enqueue(SiteEvent(
          name: name,
          ts: _ts(),
          page: _page.isEmpty ? null : _page,
          productId: productId,
          variantId: variantId,
          value: value.isFinite ? _money(value) : null,
          currency: _currency,
          eventId: eventId,
        ));
      });

  // ── Queue and flush ───────────────────────────────────────────────────────

  void _enqueue(SiteEvent event) {
    _queue.add(event);
    if (_queue.length >= flushAt) {
      unawaited(flush());
    } else {
      _timer ??= Timer(flushInterval, () => unawaited(flush()));
    }
  }

  /// Sends everything queued, in batches. Never throws; a failed batch is dropped, not retried.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    try {
      while (!_queue.isEmpty) {
        final batch = _queue.take(batchSize);
        try {
          await _restoreSession();
          final vid = await _visitorId();
          final sid = _touchSession();
          await _send(buildAnalyticsPayload(events: batch, sid: sid, vid: vid, platform: platform));
        } catch (_) {
          // dropped: analytics never retries and never reaches the screen
        }
      }
    } catch (_) {
      // never the app's problem
    }
  }

  /// Stops the periodic flush and the lifecycle hook. For tests and for a torn-down app.
  void dispose() {
    _guard(() {
      _timer?.cancel();
      _timer = null;
      _lifecycle?.dispose();
      _lifecycle = null;
    });
  }

  // ── Ids ───────────────────────────────────────────────────────────────────

  Future<String> _visitorId() => _vidFuture ??= _loadOrCreateVid();

  Future<String> _loadOrCreateVid() async {
    try {
      final stored = await _store.read(_vidKey);
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {
      // storage blocked: fall through to a session-only id
    }
    final id = _newId();
    try {
      await _store.write(_vidKey, id);
    } catch (_) {
      // blocked: the id still holds for this run
    }
    return id;
  }

  /// Picks up the session an earlier run left behind, so a restart inside 30 minutes continues it.
  Future<void> _restoreSession() => _sessionRestore ??= () async {
        try {
          final raw = await _store.read(_sidKey);
          if (raw == null) return;
          final m = jsonDecode(raw);
          if (m is Map && m['id'] is String && m['last'] is int) {
            _session.restore(m['id'] as String, DateTime.fromMillisecondsSinceEpoch(m['last'] as int));
          }
        } catch (_) {
          // corrupt or blocked: start a new session
        }
      }();

  String _touchSession() {
    final sid = _session.touch(_now());
    final last = _session.last!;
    unawaited(_writeSession(sid, last));
    return sid;
  }

  Future<void> _writeSession(String id, DateTime last) async {
    try {
      await _store.write(_sidKey, jsonEncode({'id': id, 'last': last.millisecondsSinceEpoch}));
    } catch (_) {
      // blocked: the in-memory session carries the run
    }
  }

  int _ts() => _now().millisecondsSinceEpoch;

  void _guard(void Function() body) {
    try {
      body();
    } catch (_) {
      // analytics never throws into the caller
    }
  }
}
