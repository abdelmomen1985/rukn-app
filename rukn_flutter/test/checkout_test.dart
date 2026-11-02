import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/services/checkout_service.dart';
import 'package:rukn_thamin/services/ups_coverage.dart';

void main() {
  group('coverageQuery', () {
    test('asks nothing for an empty address', () {
      expect(coverageQuery(' ', ''), isNull);
      expect(coverageQuery(null, null), isNull);
    });

    test('carries city and district', () {
      final q = Uri.splitQueryString(coverageQuery('فرسان', 'حي النور')!);
      expect(q['city'], 'فرسان');
      expect(q['district'], 'حي النور');
    });
  });

  group('uncoveredMessage', () {
    test('is null when covered or unknown', () {
      expect(uncoveredMessage(null, 'ar'), isNull);
      expect(uncoveredMessage(const UpsCoverage(covered: true), 'en'), isNull);
    });

    test('uses the backend wording in the page language', () {
      const c = UpsCoverage(covered: false, messageAr: 'غير متاح', messageEn: 'Not available');
      expect(uncoveredMessage(c, 'ar'), 'غير متاح');
      expect(uncoveredMessage(c, 'en'), 'Not available');
    });

    test('falls back to a generic message', () {
      expect(uncoveredMessage(const UpsCoverage(covered: false), 'en'), contains('UPS'));
      expect(uncoveredMessage(const UpsCoverage(covered: false), 'ar'), contains('UPS'));
    });
  });

  group('deliveryCarrier', () {
    const uncovered = UpsCoverage(covered: false, area: 'فرسان', fallback: 'smsa');

    test('is SMSA only where UPS does not deliver and SMSA is offered', () {
      expect(deliveryCarrier(uncovered, true), 'smsa');
      expect(deliveryCarrier(uncovered, false), 'ups');
      expect(deliveryCarrier(const UpsCoverage(covered: false, area: 'فرسان'), true), 'ups');
    });

    test('stays UPS when covered, unknown, or on an older backend', () {
      expect(deliveryCarrier(const UpsCoverage(covered: true), true), 'ups');
      expect(deliveryCarrier(null, true), 'ups');
      expect(deliveryCarrier(const UpsCoverage(covered: false, area: 'فرسان'), true), 'ups');
    });
  });

  group('UpsCoverage.fromJson', () {
    test('reads the backend shape, including the SMSA fallback', () {
      final c = UpsCoverage.fromJson({
        'covered': false,
        'area': 'فرسان',
        'parent': null,
        'message_ar': 'م',
        'message_en': 'm',
        'fallback': 'smsa',
      });
      expect(c.covered, isFalse);
      expect(c.area, 'فرسان');
      expect(c.parent, isNull);
      expect(c.messageEn, 'm');
      expect(c.fallback, 'smsa');
    });

    test('an older backend without fallback has none', () {
      expect(UpsCoverage.fromJson({'covered': false}).fallback, isNull);
    });
  });

  group('DeliveryOptions smsa', () {
    Map<String, dynamic> payload({bool withSmsa = true}) => {
          'pickup': {'available': false},
          'ups': [
            {'option_id': 'so_ups', 'name': 'UPS', 'amount': 29, 'free_shipping_threshold': 1000},
          ],
          if (withSmsa)
            'smsa': [
              {'option_id': 'so_smsa', 'name': 'SMSA', 'amount': 30, 'free_shipping_threshold': null},
            ],
        };

    test('parses smsa options alongside ups', () {
      final d = DeliveryOptions.fromJson(payload());
      expect(d.ups.single.optionId, 'so_ups');
      expect(d.ups.single.freeOver, 1000);
      expect(d.smsa.single.optionId, 'so_smsa');
      expect(d.smsa.single.amount, 30);
      expect(d.smsa.single.freeOver, isNull);
    });

    test('is empty on an older backend', () {
      final d = DeliveryOptions.fromJson(payload(withSmsa: false));
      expect(d.smsa, isEmpty);
      expect(d.ups, hasLength(1));
    });
  });
}
