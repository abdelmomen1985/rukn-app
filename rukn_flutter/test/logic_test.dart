import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/models/gold_prices.dart';
import 'package:rukn_thamin/models/portfolio.dart';
import 'package:rukn_thamin/models/price_alert.dart';
import 'package:rukn_thamin/models/product.dart';
import 'package:rukn_thamin/models/trips.dart';
import 'package:rukn_thamin/services/checkout_service.dart';
import 'package:rukn_thamin/services/content_service.dart';
import 'package:rukn_thamin/services/national_address.dart';
import 'package:rukn_thamin/services/phone.dart';
import 'package:rukn_thamin/services/store_settings.dart';
import 'package:rukn_thamin/state/gold_ticker.dart';

GoldPrices prices({double k21 = 437.05, double raw24 = 499.42}) => GoldPrices.fromJson({
      'currency': 'sar',
      'prices': {
        '21': {'raw': k21, 'retail': 505.63},
        '24': {'raw': raw24, 'retail': 577.78},
      },
      'silverPrices': {
        '999': {'raw': 7.27, 'retail': 8.36},
      },
      'ounce': {'gold': 15533.74, 'silver': 226.41},
      'marketOpen': false,
      'tickerIncludesTax': false,
    });

void main() {
  group('portfolio math', () {
    test('weight conversions round-trip', () {
      expect(weightInGrams(1, 'tolas'), closeTo(11.664, 1e-9));
      expect(convertWeight(31.1035, 'grams', 'ounces'), closeTo(1, 1e-9));
      expect(convertWeight(convertWeight(7, 'mithqal', 'tolas'), 'tolas', 'mithqal'), closeTo(7, 1e-9));
    });

    test('asset value uses purity factor and USD→SAR peg', () {
      final spot = SpotPrices({'XAU': 3110.35}, DateTime.now());
      final asset = PortfolioAsset.fromJson({
        'id': 'a',
        'metalType': 'gold',
        'name': 'Ring',
        'category': 'ring',
        'weightValue': 10,
        'weightUnit': 'grams',
        'karat': 21,
        'purchasePrice': 3000,
        'purchaseDate': '2026-01-01',
        'makingCharges': 0,
        'vatAmount': 0,
      });
      // Legacy asset without purityFactor is migrated from karat.
      expect(asset.purityLabel, '21K');
      expect(asset.purityFactor, closeTo(21 / 24, 1e-12));
      // 3110.35 USD/oz * 3.75 / 31.1035 = 375 SAR/g pure
      expect(purePerGramSar(spot, 'XAU'), closeTo(375, 1e-9));
      expect(currentValueSar(asset, spot), closeTo(10 * 375 * 21 / 24, 1e-9));
    });

    test('snake_case API rows parse', () {
      final a = PortfolioAsset.fromJson({
        'id': 'passet_1',
        'metal_type': 'silver',
        'name': 'Bar',
        'category': 'bar',
        'weight_value': 100,
        'weight_unit': 'grams',
        'purity_label': '999',
        'purity_factor': 0.999,
        'purchase_price': 800,
        'purchase_date': '2026-02-02',
        'making_charges': 10,
        'vat_amount': 0,
      });
      expect(a.isServerRow, isTrue);
      expect(a.totalCost, 810);
      expect(a.toApiBody()['weight_unit'], 'grams');
    });

    test('zakat applies 2.5% only above the 85 g nisab', () {
      final spot = SpotPrices({'XAU': 3110.35}, DateTime.now());
      PortfolioAsset gold(double g) => PortfolioAsset.fromJson({
            'id': 'x', 'metalType': 'gold', 'name': 'n', 'category': 'bar', 'weightValue': g, 'weightUnit': 'grams',
            'purityLabel': '24K', 'purityFactor': 1, 'purchasePrice': 0, 'purchaseDate': '2026-01-01', 'makingCharges': 0, 'vatAmount': 0,
          });
      expect(calculateZakat([gold(80)], spot).isAboveNisab, isFalse);
      final z = calculateZakat([gold(100)], spot);
      expect(z.isAboveNisab, isTrue);
      expect(z.zakatDue, closeTo(100 * 375 * 0.025, 1e-6));
    });
  });

  group('market trips', () {
    test('fair-price verdict bands', () {
      // 10 g of 24K at 300 SAR/g = 3000 gold value; making 20/g → excellent
      final r = evaluateFairPrice(totalPriceSar: 3200, weightGrams: 10, purityFactor: 1, vatIncluded: false, purePerGramSar: 300);
      expect(r.makingPerGram, closeTo(20, 1e-9));
      expect(r.verdict, 'excellent');
      expect(evaluateFairPrice(totalPriceSar: 3400, weightGrams: 10, purityFactor: 1, vatIncluded: false, purePerGramSar: 300).verdict, 'fair');
      expect(evaluateFairPrice(totalPriceSar: 3600, weightGrams: 10, purityFactor: 1, vatIncluded: false, purePerGramSar: 300).verdict, 'high');
    });

    test('VAT is stripped before judging workmanship', () {
      final r = evaluateFairPrice(totalPriceSar: 3680, weightGrams: 10, purityFactor: 1, vatIncluded: true, purePerGramSar: 300);
      expect(r.preTaxTotal, closeTo(3200, 1e-9));
      expect(r.vatAmount, closeTo(480, 1e-9));
    });

    test('gold bars are locked to 24K', () {
      expect(tripPuritiesFor('bar').map((p) => p.label), ['24K']);
      expect(tripPuritiesFor('ring').length, 5);
    });
  });

  group('price alerts', () {
    test('fires once per crossing and re-arms', () {
      var alerts = [
        createAlert(metal: 'gold', purityLabel: '21K', purityFactor: 21 / 24, direction: 'above', target: 440, repeat: true, currentPrice: 437.05),
      ];
      expect(alerts.first.armed, isTrue);
      var r = evaluateAlerts(alerts, prices(k21: 441));
      expect(r.fired, hasLength(1));
      alerts = r.next;
      r = evaluateAlerts(alerts, prices(k21: 442));
      expect(r.fired, isEmpty, reason: 'already fired, still above');
      alerts = r.next;
      r = evaluateAlerts(alerts, prices(k21: 430));
      expect(r.next.first.armed, isTrue, reason: 're-armed after falling back');
      r = evaluateAlerts(r.next, prices(k21: 445));
      expect(r.fired, hasLength(1));
    });

    test('a one-shot alert deactivates after firing', () {
      final a = createAlert(metal: 'gold', purityLabel: '21K', purityFactor: 21 / 24, direction: 'below', target: 430, repeat: false, currentPrice: 437);
      final r = evaluateAlerts([a], prices(k21: 420));
      expect(r.fired, hasLength(1));
      expect(r.next.first.active, isFalse);
    });

    test('an alert already met at creation starts disarmed', () {
      final a = createAlert(metal: 'gold', purityLabel: '21K', purityFactor: 21 / 24, direction: 'above', target: 400, repeat: false, currentPrice: 437);
      expect(a.armed, isFalse);
    });

    test('silver reads the per-gram silver block', () {
      expect(alertPerGramSar(prices(), 'silver', 0.999, '999'), 7.27);
    });
  });

  group('gold ticker', () {
    test('price scaler follows the 21K catalogue rate', () {
      final s = PriceScaler(500);
      expect(s.scale(1000, 510), 1020);
      expect(s.scale(1000, null), 1000);
      expect(PriceScaler(null).scale(1000, 510), 1000);
    });

    test('ticker uses the live block and raw rate by default', () {
      final p = GoldPrices.fromJson({
        'prices': {'21': {'raw': 1, 'retail': 2}},
        'live': {'21': {'raw': 3, 'retail': 4}},
      });
      expect(p.tickerKarat('21'), 3);
      expect(p.catalogPrice, 2);
    });
  });

  group('phone', () {
    test('normalizes Saudi mobiles in every common form', () {
      for (final input in ['0501234567', '501234567', '+966501234567', '00966501234567', '٠٥٠١٢٣٤٥٦٧']) {
        expect(normalizeOtpPhone(input), '+966501234567', reason: input);
      }
      expect(normalizeOtpPhone('0401234567'), isNull);
      expect(normalizeOtpPhone('50123456', '971'), isNull);
      expect(normalizeOtpPhone('501234567', '971'), '+971501234567');
      expect(nationalPhoneOf('+966501234567'), '0501234567');
    });
  });

  group('national address', () {
    test('short address normalization', () {
      expect(normalizeShortAddress('rrrd 2929'), 'RRRD2929');
      expect(normalizeShortAddress('RRRD-٢٩٢٩'), 'RRRD2929');
      expect(normalizeShortAddress('RRR2929'), isNull);
    });

    test('draft completeness and Medusa fields', () {
      final d = NationalAddressDraft(
        shortAddress: 'RRRD2929',
        buildingNumber: '1234',
        street: 'King Fahd Rd',
        district: 'Olaya',
        city: 'Riyadh',
        postalCode: '12345',
      );
      expect(d.isComplete, isTrue);
      final f = d.toMedusaAddressFields();
      expect(f['address_1'], '1234 King Fahd Rd');
      expect(f['address_2'], 'Olaya - RRRD2929');
      expect((f['metadata'] as Map)['national_address']['short_address'], 'RRRD2929');
      expect((d..postalCode = '123').problem, 'postal_code');
    });
  });

  group('checkout', () {
    test('card fee matches the backend formula in halalas', () {
      const m = PaymentMethods(
        bankTransferEnabled: true, bankUnavailableReason: null, bankAccounts: [], codEnabled: false,
        paymobAvailable: true, paymobNameAr: '', paymobNameEn: '', cardFeePercent: 2.5, cardFeeFixed: 1,
      );
      expect(m.cardFee(1000), 26);
      expect(m.cardFee(577.42), 15.44);
      expect(m.cardFee(-1), 0);
    });

    test('free shipping threshold', () {
      const c = DeliveryChoice(optionId: 'so', kind: 'ups', name: 'UPS', amount: 29, freeOver: 1000);
      expect(c.feeFor(999), 29);
      expect(c.feeFor(1000), 0);
    });

    test('VAT extraction from a VAT-inclusive price', () {
      expect(VatInfo.extract(115, 15), 15);
      const info = VatInfo(taxRate: 15, exempt: {'bar': true});
      expect(info.lineVat('bar', 1000), isNull);
      expect(info.lineVat('ring', 1150), 150);
    });

    test('branch-exclusive products cannot share a cart', () {
      const catalog = BranchCatalog(
        configured: true,
        branches: [CatalogBranch(id: 'jed', name: 'فرع جدة', nameEn: 'Jeddah', city: 'جدة'), CatalogBranch(id: 'ruh', name: 'فرع الرياض', nameEn: 'Riyadh', city: 'الرياض')],
        exclusive: {'p1': ['jed'], 'p2': ['ruh']},
      );
      expect(catalog.addToCartConflict(['p1'], 'p2', 'en'), contains('Riyadh'));
      expect(catalog.addToCartConflict(['p1'], 'p3', 'en'), isNull);
      expect(catalog.addToCartConflict(['p3'], 'p2', 'en'), isNull);
    });
  });

  group('catalogue mapping', () {
    test('maps a Medusa product with size and weight options', () {
      Map<String, dynamic> variant(String id, String size, String weight, double price) => {
            'id': id,
            'title': '$size / $weight',
            'metadata': {'weight_grams': weight},
            'options': [
              {'value': size, 'option': {'title': 'المقاس'}},
              {'value': weight, 'option': {'title': 'الوزن'}},
            ],
            'calculated_price': {'calculated_amount': price},
          };
      final p = mapProduct({
        'id': 'prod_1',
        'title': 'خاتم',
        'handle': 'ring',
        'thumbnail': 'https://x/y.jpg',
        'metadata': {'karat': '21', 'title_en': 'Ring'},
        'variants': [variant('v3', '20', '3', 1500), variant('v1', '9', '2', 1000), variant('v2', '10', '2', 1100)],
      });
      expect(p.name.of('en'), 'Ring');
      expect(p.metaLabel.of('ar'), 'ذهب عيار 21');
      expect(p.variantId, 'v1', reason: 'cheapest priced variant is the default');
      expect(p.basePrice, 1000);
      expect(p.options.first.kind, ProductOptionKind.size);
      expect(p.options.first.values, ['9', '10', '20'], reason: 'sizes sort numerically');
      expect(p.isBar, isFalse);
    });

    test('bars carry their certificate serial', () {
      final p = mapProduct({
        'id': 'prod_bar',
        'title': 'سبيكة',
        'metadata': {'metal': 'gold'},
        'variants': [
          {'id': 'v', 'sku': 'RT-0001', 'calculated_price': {'calculated_amount': 577.42}},
        ],
      });
      expect(p.isBar, isTrue);
      expect(p.certificateSerial, 'RT-0001');
    });

    test('serial normalization', () {
      expect(normalizeSerial(' rt 0001.a '), 'RT-0001-A');
      expect(formatSerial('RT-0001'), 'RT · 0001');
    });
  });
}
