import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/services/order_statuses.dart';

void main() {
  group('toOrderStatuses', () {
    test('returns null when the backend had nothing (keep the built-in wording)', () {
      expect(toOrderStatuses({'labels': null, 'stages': null}), isNull);
      expect(toOrderStatuses(null), isNull);
    });

    test('normalises labels, filling a missing language from the other', () {
      final data = toOrderStatuses({
        'labels': {
          'payment': {
            'captured': {'ar': 'مدفوع', 'en': '', 'tone': 'pink'},
            'blank': {'ar': '', 'en': ''},
          },
        },
        'stages': [
          {'key': 'new', 'label_ar': 'جديد', 'label_en': 'New', 'color': 'gold', 'kind': 'open', 'rank': 0},
          {'key': ''},
        ],
      });
      expect(data, isNotNull);
      final payment = data!.labels['payment']!;
      expect(payment.keys, ['captured']);
      expect(payment['captured']!.ar, 'مدفوع');
      expect(payment['captured']!.en, 'مدفوع');
      expect(payment['captured']!.tone, 'grey');
      expect(data.stages.map((s) => s.key), ['new']);
      expect(remoteStatusLabel(data, 'payment', 'captured', 'en'), 'مدفوع');
      expect(remoteStatusLabel(data, 'payment', 'refunded', 'ar'), isNull);
      expect(remoteStatusLabel(null, 'payment', 'captured', 'ar'), isNull);
      expect(remoteStatusLabel(data, 'payment', null, 'ar'), isNull);
    });

    test('an empty tones map keeps the built-in palette', () {
      final data = toOrderStatuses({'labels': {}, 'stages': []});
      expect(data!.tones['gold']!.dot, kDefaultTones['gold']!.dot);
      expect(data.tones.keys.toSet(), kDefaultTones.keys.toSet());
    });

    test('backend tones override the built-in palette, invalid ones are ignored', () {
      final data = toOrderStatuses({
        'labels': {},
        'tones': {
          'gold': {'bg': '#000000', 'fg': '#ffffff', 'dot': '#123456'},
          'red': {'bg': 'nope', 'fg': '#ffffff', 'dot': '#123456'},
        },
      });
      expect(data!.tones['gold']!.bg, const Color(0xFF000000));
      expect(data.tones['gold']!.dot, const Color(0xFF123456));
      expect(data.tones['red']!.bg, kDefaultTones['red']!.bg);
    });

    test('tone palette matches the website defaults', () {
      expect(kToneNames, ['grey', 'gold', 'blue', 'green', 'orange', 'red', 'purple']);
      expect(kDefaultTones.keys.toList(), kToneNames);
      expect(kDefaultTones['green']!.fg, const Color(0xFF1F6B3A));
    });

    test('toneColorsFor falls back to grey for an unknown tone', () {
      expect(toneColorsFor(null, 'nope').dot, kDefaultTones['grey']!.dot);
    });
  });

  group('stages', () {
    test('reads a stage defensively', () {
      final stage = toStage({'key': 'x', 'kind': 'weird', 'color': 'nope', 'rank': 'a'});
      expect(stage, isNotNull);
      expect(stage!.key, 'x');
      expect(stage.labelAr, 'x');
      expect(stage.labelEn, 'x');
      expect(stage.color, 'grey');
      expect(stage.kind, 'open');
      expect(stage.rank, 0);
      expect(toStage(null), isNull);
      expect(toStage({'key': '  '}), isNull);
    });

    test('keeps the canceled and final kinds', () {
      expect(toStage({'key': 'c', 'kind': 'canceled'})!.kind, 'canceled');
      expect(toStage({'key': 'f', 'kind': 'final'})!.kind, 'final');
    });

    test('stageLabel picks the language', () {
      final stage = toStage({'key': 'shipped', 'label_ar': 'في الطريق إليك', 'label_en': 'On its way'})!;
      expect(stageLabel(stage, 'ar'), 'في الطريق إليك');
      expect(stageLabel(stage, 'en'), 'On its way');
    });

    test('reads an order progress, dropping bad dates', () {
      final p = toStageProgress({
        'current': {
          'key': 'shipped',
          'label_ar': 'في الطريق إليك',
          'label_en': 'On its way',
          'color': 'orange',
          'kind': 'open',
          'rank': 4,
        },
        'entered_at': '2026-10-29T10:00:00.000Z',
        'progress': [
          {'key': 'new', 'label_ar': 'تم استلام الطلب', 'label_en': 'Order received'},
          {'key': 'shipped'},
        ],
        'reached_at': {'new': '2026-10-28T10:00:00.000Z', 'shipped': 'garbage'},
      });
      expect(p, isNotNull);
      expect(p!.current!.key, 'shipped');
      expect(p.enteredAt, '2026-10-29T10:00:00.000Z');
      expect(p.progress.map((s) => s.key), ['new', 'shipped']);
      expect(p.reachedAt, {'new': '2026-10-28T10:00:00.000Z'});
      expect(toStageProgress({}), isNull);
    });

    test('a progress with no current stage still reads', () {
      final p = toStageProgress({'current': null, 'progress': [], 'reached_at': null});
      expect(p, isNotNull);
      expect(p!.current, isNull);
      expect(p.progress, isEmpty);
      expect(p.reachedAt, isEmpty);
    });
  });
}
