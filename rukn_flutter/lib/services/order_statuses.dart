import 'package:flutter/material.dart';

import '../core/api.dart';

/// «حالات الطلب» — what the store calls each order status, as the operator set it in the admin
/// (Settings → حالات الطلب), published at `GET /store/order-statuses`; and one order's progress
/// through the operator's stage pipeline (`GET /store/customers/me/orders/:id/stages`).
///
/// Port of rukn-site/src/lib/orderStatuses.ts. Every reader falls back to the built-in wording
/// (`i18n.dart`) when the backend is unreachable, so a status never renders blank.

/// Tone names the backend may send. Anything else reads as `grey`.
const List<String> kToneNames = ['grey', 'gold', 'blue', 'green', 'orange', 'red', 'purple'];

class ToneColors {
  const ToneColors({required this.bg, required this.fg, required this.dot});
  final Color bg;
  final Color fg;
  final Color dot;
}

/// The tone palette, mirrored from the backend so a chip renders before (or without) the fetch.
const Map<String, ToneColors> kDefaultTones = {
  'grey': ToneColors(bg: Color(0xFFEEF1F0), fg: Color(0xFF4B5F5B), dot: Color(0xFF7C938F)),
  'gold': ToneColors(bg: Color(0xFFFFF4CC), fg: Color(0xFF7A5C00), dot: Color(0xFFFFC508)),
  'blue': ToneColors(bg: Color(0xFFE3EFFD), fg: Color(0xFF1D4F91), dot: Color(0xFF3B82F6)),
  'green': ToneColors(bg: Color(0xFFE3F5EA), fg: Color(0xFF1F6B3A), dot: Color(0xFF22A35A)),
  'orange': ToneColors(bg: Color(0xFFFDEEDD), fg: Color(0xFF8A4B0B), dot: Color(0xFFF08A24)),
  'red': ToneColors(bg: Color(0xFFFDE5E3), fg: Color(0xFF9B1C1C), dot: Color(0xFFE5484D)),
  'purple': ToneColors(bg: Color(0xFFEFE7FB), fg: Color(0xFF5B2A9B), dot: Color(0xFF8B5CF6)),
};

/// Scopes: order, payment, fulfillment, carrier, vault.
class StatusLabel {
  const StatusLabel({required this.ar, required this.en, required this.tone});
  final String ar;
  final String en;
  final String tone;
}

class PublicStage {
  const PublicStage({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.color,
    required this.kind,
    required this.rank,
  });
  final String key;
  final String labelAr;
  final String labelEn;
  final String color;

  /// `open`, `final` or `canceled`.
  final String kind;
  final int rank;
}

class OrderStatusesData {
  const OrderStatusesData({required this.labels, required this.stages, required this.tones});

  /// scope → status code → label.
  final Map<String, Map<String, StatusLabel>> labels;
  final List<PublicStage> stages;
  final Map<String, ToneColors> tones;
}

class OrderStageProgress {
  const OrderStageProgress({
    required this.current,
    required this.enteredAt,
    required this.progress,
    required this.reachedAt,
  });
  final PublicStage? current;
  final String? enteredAt;
  final List<PublicStage> progress;

  /// stage key → ISO timestamp.
  final Map<String, String> reachedAt;
}

String _text(Object? v) => v is String ? v.trim() : '';

String _tone(Object? v) => v is String && kToneNames.contains(v) ? v : 'grey';

Color? _hex(Object? v) {
  if (v is! String) return null;
  final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(v.trim());
  return m == null ? null : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

List<PublicStage> _stages(Object? raw) {
  if (raw is! List) return const [];
  final out = <PublicStage>[];
  for (final s in raw) {
    final stage = toStage(s);
    if (stage != null) out.add(stage);
  }
  return out;
}

/// Null when the stage has no key — the caller drops it.
PublicStage? toStage(Object? raw) {
  if (raw is! Map) return null;
  final key = _text(raw['key']);
  if (key.isEmpty) return null;
  final kind = raw['kind'] == 'final' || raw['kind'] == 'canceled' ? raw['kind'] as String : 'open';
  final ar = _text(raw['label_ar']);
  final en = _text(raw['label_en']);
  final rank = num.tryParse('${raw['rank']}');
  return PublicStage(
    key: key,
    labelAr: ar.isNotEmpty ? ar : (en.isNotEmpty ? en : key),
    labelEn: en.isNotEmpty ? en : (ar.isNotEmpty ? ar : key),
    color: _tone(raw['color']),
    kind: kind,
    rank: rank != null && rank.isFinite ? rank.toInt() : 0,
  );
}

/// Null when the backend answered nothing usable — the caller keeps its built-in wording.
OrderStatusesData? toOrderStatuses(Object? raw) {
  if (raw is! Map || raw['labels'] is! Map) return null;
  final labels = <String, Map<String, StatusLabel>>{};
  (raw['labels'] as Map).forEach((scope, codes) {
    if (codes is! Map) return;
    final out = <String, StatusLabel>{};
    codes.forEach((code, l) {
      final ar = _text(l is Map ? l['ar'] : null);
      final en = _text(l is Map ? l['en'] : null);
      if (ar.isNotEmpty || en.isNotEmpty) {
        out['$code'] = StatusLabel(
          ar: ar.isNotEmpty ? ar : en,
          en: en.isNotEmpty ? en : ar,
          tone: _tone(l is Map ? l['tone'] : null),
        );
      }
    });
    labels['$scope'] = out;
  });
  final stages = _stages(raw['stages']);
  final tones = Map<String, ToneColors>.of(kDefaultTones);
  if (raw['tones'] is Map) {
    (raw['tones'] as Map).forEach((name, v) {
      if (v is! Map) return;
      final bg = _hex(v['bg']);
      final fg = _hex(v['fg']);
      final dot = _hex(v['dot']);
      if (bg != null && fg != null && dot != null) tones['$name'] = ToneColors(bg: bg, fg: fg, dot: dot);
    });
  }
  return OrderStatusesData(labels: labels, stages: stages, tones: tones);
}

/// The operator's label entry for a status, or null to use the built-in translation.
StatusLabel? remoteStatusEntry(OrderStatusesData? data, String scope, String? code) {
  if (data == null || code == null || code.isEmpty) return null;
  return data.labels[scope]?[code];
}

/// The operator's text for a status, or null to use the built-in translation.
String? remoteStatusLabel(OrderStatusesData? data, String scope, String? code, String lang) {
  final entry = remoteStatusEntry(data, scope, code);
  if (entry == null) return null;
  return lang == 'ar' ? entry.ar : entry.en;
}

/// Palette for a tone name, falling back to the built-in palette.
ToneColors toneColorsFor(OrderStatusesData? data, String tone) =>
    data?.tones[tone] ?? kDefaultTones[tone] ?? kDefaultTones['grey']!;

String stageLabel(PublicStage stage, String lang) => lang == 'ar' ? stage.labelAr : stage.labelEn;

/// Null when the backend had no progress list for the order.
OrderStageProgress? toStageProgress(Object? raw) {
  if (raw is! Map || raw['progress'] is! List) return null;
  final reached = <String, String>{};
  if (raw['reached_at'] is Map) {
    (raw['reached_at'] as Map).forEach((k, v) {
      if (v is String && DateTime.tryParse(v) != null) reached['$k'] = v;
    });
  }
  return OrderStageProgress(
    current: toStage(raw['current']),
    enteredAt: raw['entered_at'] is String ? raw['entered_at'] as String : null,
    progress: _stages(raw['progress']),
    reachedAt: reached,
  );
}

Future<OrderStatusesData?>? _statusesCache;

/// Fetched once per app run. A failure clears the cache so the next call retries, rather than
/// pinning the built-in wording for the whole session.
Future<OrderStatusesData?> fetchOrderStatuses() {
  return _statusesCache ??= Api.get('/store/order-statuses').then<OrderStatusesData?>(toOrderStatuses).catchError((_) {
    _statusesCache = null;
    return null;
  });
}

Future<OrderStageProgress?> fetchOrderStageProgress(String orderId) async {
  try {
    return toStageProgress(await Api.get('/store/customers/me/orders/${Uri.encodeComponent(orderId)}/stages'));
  } catch (_) {
    return null;
  }
}
