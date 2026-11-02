import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/services/site_analytics.dart';

// Port of the pure parts of rukn-site/src/lib/site-analytics.test.ts. Clock, ids, storage and the
// network are all injected, so nothing here touches I/O.

class MemoryStore implements AnalyticsStore {
  final Map<String, String> data = {};
  bool blocked = false;

  @override
  Future<String?> read(String key) async {
    if (blocked) throw StateError('SecurityError');
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (blocked) throw StateError('SecurityError');
    data[key] = value;
  }
}

class Recorder {
  final List<Map<String, dynamic>> sent = [];
  bool failing = false;

  Future<void> send(Map<String, dynamic> body) async {
    if (failing) throw StateError('offline');
    sent.add(body);
  }

  List<Map<String, dynamic>> get events => [for (final b in sent) ...(b['events'] as List).cast<Map<String, dynamic>>()];
}

/// Lets the unawaited flushes run to completion.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late DateTime clock;
  late int idCounter;

  setUp(() {
    clock = DateTime(2026, 11, 2, 12);
    idCounter = 0;
  });

  String newId() => 'id${++idCounter}';

  SiteAnalytics make({
    AnalyticsStore? store,
    Recorder? recorder,
    Future<void> Function(Map<String, dynamic> body)? send,
    int flushAt = 10,
    int maxQueue = 100,
  }) =>
      SiteAnalytics(
        send: send ?? (recorder ?? Recorder()).send,
        store: store ?? MemoryStore(),
        now: () => clock,
        newId: newId,
        platform: 'ios',
        flushAt: flushAt,
        maxQueue: maxQueue,
      );

  group('payload', () {
    test('has the site wire shape, with snake_case event fields', () {
      final body = buildAnalyticsPayload(
        events: const [
          SiteEvent(
            name: 'product_viewed',
            ts: 5,
            page: '/product/x',
            productId: 'p1',
            variantId: 'v1',
            value: 40,
            currency: 'SAR',
          ),
        ],
        sid: 's',
        vid: 'v',
        platform: 'android',
      );
      expect(body['v'], 1);
      expect(body['platform'], 'android');
      expect(body['vid'], 'v');
      expect(body['sid'], 's');
      expect(body, isNot(contains('attribution')));
      expect((body['events'] as List).single, {
        'name': 'product_viewed',
        'ts': 5,
        'page': '/product/x',
        'product_id': 'p1',
        'variant_id': 'v1',
        'value': 40,
        'currency': 'SAR',
      });
    });

    test('omits unset optional fields', () {
      expect(const SiteEvent(name: 'page_view', ts: 1).toJson(), {'name': 'page_view', 'ts': 1});
    });

    test('carries attribution only when given', () {
      final without = buildAnalyticsPayload(events: const [], sid: 's', vid: 'v', platform: 'ios');
      expect(without, isNot(contains('attribution')));
      final withIt = buildAnalyticsPayload(
        events: const [],
        sid: 's',
        vid: 'v',
        platform: 'ios',
        attribution: {'source': 'google'},
      );
      expect(withIt['attribution'], {'source': 'google'});
    });

    test('sends search props as the event props', () {
      const e = SiteEvent(name: 'search', ts: 1, props: {'query': 'ring'});
      expect(e.toJson()['props'], {'query': 'ring'});
    });
  });

  group('session', () {
    test('keeps a session while active and rotates it after 30 idle minutes', () {
      final session = AnalyticsSession(newId: newId);
      final t0 = DateTime(2026, 11, 2, 12);
      final a = session.touch(t0);
      // Each touch extends the session, so 25 minutes after the last touch it still holds.
      expect(session.touch(t0.add(const Duration(minutes: 25))), a);
      expect(session.touch(t0.add(const Duration(minutes: 50))), a);
      // 30 idle minutes from the last touch: a new session.
      expect(session.touch(t0.add(const Duration(minutes: 80))), isNot(a));
    });

    test('restore continues a session an earlier run left behind', () {
      final session = AnalyticsSession(newId: newId);
      final t0 = DateTime(2026, 11, 2, 12);
      session.restore('kept', t0);
      expect(session.touch(t0.add(const Duration(minutes: 10))), 'kept');
    });
  });

  group('queue', () {
    SiteEvent ev(int i) => SiteEvent(name: 'e$i', ts: i);

    test('caps at the maximum, dropping the oldest', () {
      final queue = EventQueue(maxLength: 100);
      for (var i = 0; i < 105; i++) {
        queue.add(ev(i));
      }
      expect(queue.length, 100);
      final all = queue.take(1000);
      expect(all.first.name, 'e5');
      expect(all.last.name, 'e104');
      expect(queue.isEmpty, isTrue);
    });

    test('take returns the oldest events first, up to the batch size', () {
      final queue = EventQueue();
      for (var i = 0; i < 30; i++) {
        queue.add(ev(i));
      }
      expect(queue.take(25).map((e) => e.name), [for (var i = 0; i < 25; i++) 'e$i']);
      expect(queue.length, 5);
    });
  });

  group('SiteAnalytics', () {
    test('sends a batch on its own at ten events, with one visitor and one session', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      for (var i = 0; i < 10; i++) {
        analytics.search('q$i');
      }
      await settle();
      expect(rec.sent, hasLength(1));
      final body = rec.sent.single;
      expect(body['events'], hasLength(10));
      expect(body['vid'], 'id1');
      expect(body['sid'], 'id2');
      expect(body['platform'], 'ios');
    });

    test('queued events wait for flush, and flush sends them', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      analytics.pageView('/ar');
      await settle();
      expect(rec.sent, isEmpty);
      await analytics.flush();
      expect(rec.sent, hasLength(1));
    });

    test('counts a page view once per change of location', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      analytics.pageView('/ar');
      analytics.pageView('/ar');
      analytics.pageView('/ar/cart');
      await analytics.flush();
      expect(rec.events.map((e) => [e['name'], e['page']]), [
        ['page_view', '/ar'],
        ['page_view', '/ar/cart'],
      ]);
    });

    test('product view and add to cart carry the ids, the value rounded, and SAR', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      analytics.pageView('/product/ring');
      analytics.productViewed(productId: 'p1', variantId: 'v1', value: 40.456);
      analytics.addedToCart(productId: 'p1', variantId: 'v1', value: 80.5);
      await analytics.flush();
      final [_, viewed, added] = rec.events;
      expect(viewed, {
        'name': 'product_viewed',
        'ts': clock.millisecondsSinceEpoch,
        'page': '/product/ring',
        'product_id': 'p1',
        'variant_id': 'v1',
        'value': 40.46,
        'currency': 'SAR',
      });
      expect(added['name'], 'added_to_cart');
      expect(added['value'], 80.5);
    });

    test('a non-finite value is left out, not sent as NaN', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      analytics.addedToCart(productId: 'p1', variantId: 'v1', value: double.nan);
      await analytics.flush();
      expect(rec.events.single, isNot(contains('value')));
    });

    test('checkout events: started, payment submitted, and completed keyed by the order', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      analytics.checkoutStarted(120);
      analytics.paymentInfoSubmitted(135.5);
      analytics.checkoutCompleted(orderId: 'RK-1001', value: 135.5);
      await analytics.flush();
      final [started, payment, completed] = rec.events;
      expect([started['name'], started['value'], started['currency']], ['checkout_started', 120, 'SAR']);
      expect([payment['name'], payment['value']], ['payment_info_submitted', 135.5]);
      expect([completed['name'], completed['event_id'], completed['value']], ['checkout_completed', 'RK-1001', 135.5]);
    });

    test('search records the trimmed query as a prop, and ignores a blank one', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec);
      analytics.search('   ');
      analytics.search('  خاتم  ');
      analytics.search('x' * 200);
      await analytics.flush();
      expect(rec.events, hasLength(2));
      expect(rec.events.first['props'], {'query': 'خاتم'});
      expect((rec.events[1]['props'] as Map)['query'], hasLength(120));
    });

    test('a failed batch is dropped, never thrown and never retried', () async {
      final rec = Recorder()..failing = true;
      final analytics = make(recorder: rec);
      analytics.pageView('/ar');
      await expectLater(analytics.flush(), completes);
      rec.failing = false;
      await analytics.flush();
      expect(rec.sent, isEmpty);
    });

    test('a broken send function cannot break the caller', () async {
      final analytics = make(send: (_) async => throw StateError('boom'));
      analytics.pageView('/ar');
      analytics.search('ring');
      await expectLater(analytics.flush(), completes);
    });

    test('the queue is capped: a long unsent run keeps only the newest 100 events', () async {
      final rec = Recorder();
      final analytics = make(recorder: rec, flushAt: 1000, maxQueue: 100);
      for (var i = 0; i < 105; i++) {
        analytics.search('q$i');
      }
      await analytics.flush();
      expect(rec.sent, hasLength(4));
      expect(rec.sent.map((b) => (b['events'] as List).length), [25, 25, 25, 25]);
      expect(rec.events.first['props'], {'query': 'q5'});
      expect(rec.events.last['props'], {'query': 'q104'});
    });

    test('the visitor id is kept between runs', () async {
      final store = MemoryStore();
      final first = Recorder();
      final a = make(store: store, recorder: first);
      a.pageView('/ar');
      await a.flush();

      final second = Recorder();
      final b = make(store: store, recorder: second);
      b.pageView('/ar/cart');
      await b.flush();

      expect(second.sent.single['vid'], first.sent.single['vid']);
    });

    test('the session continues across runs within 30 minutes, and rotates after', () async {
      final store = MemoryStore();
      final first = Recorder();
      final a = make(store: store, recorder: first);
      a.pageView('/ar');
      await a.flush();
      final sid = first.sent.single['sid'];

      clock = clock.add(const Duration(minutes: 10));
      final second = Recorder();
      final again = make(store: store, recorder: second);
      again.pageView('/ar/orders');
      await again.flush();
      expect(second.sent.single['sid'], sid);

      clock = clock.add(const Duration(minutes: 60));
      final third = Recorder();
      final late = make(store: store, recorder: third);
      late.pageView('/ar');
      await late.flush();
      expect(third.sent.single['sid'], isNot(sid));
    });

    test('still works when storage is blocked: one visitor and one session for the run', () async {
      final store = MemoryStore()..blocked = true;
      final rec = Recorder();
      final analytics = make(store: store, recorder: rec);
      analytics.pageView('/ar');
      await analytics.flush();
      analytics.pageView('/ar/cart');
      await analytics.flush();
      expect(rec.sent, hasLength(2));
      expect(rec.sent[1]['vid'], rec.sent[0]['vid']);
      expect(rec.sent[1]['sid'], rec.sent[0]['sid']);
    });
  });
}
