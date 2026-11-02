import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/services/special_offers.dart';

Map<String, Object?> raw([Map<String, Object?> over = const {}]) => {
      'id': 'soff_1',
      'badge': {'ar': 'عرض خاص', 'en': ''},
      'text': {'ar': 'المصنعية 15 ريال بدلا من 40', 'en': 'Making 15 SAR instead of 40'},
      'product_ids': ['prod_1'],
      'category_ids': <String>[],
      ...over,
    };

Map<String, Object?> payload(List<Map<String, Object?>> offers) => {'offers': offers};

void main() {
  group('toSpecialOffers', () {
    test('answers no offers for an unusable payload', () {
      expect(toSpecialOffers(null), isEmpty);
      expect(toSpecialOffers({'offers': null}), isEmpty);
      expect(toSpecialOffers('not a map'), isEmpty);
    });

    test('falls back to Arabic and drops incomplete or unbound offers', () {
      final offers = toSpecialOffers(payload([
        raw(),
        raw({'id': 'no-text', 'text': {'ar': ''}}),
        raw({'id': 'unbound', 'product_ids': <String>[]}),
      ]));
      expect(offers, hasLength(1));
      expect(offers.first.badge.ar, 'عرض خاص');
      expect(offers.first.badge.en, 'عرض خاص');
      expect(offers.first.text.en, 'Making 15 SAR instead of 40');
    });

    test('keeps the bound ids and the offer id', () {
      final offers = toSpecialOffers(payload([raw({'product_ids': ['a', ''], 'category_ids': ['c1']})]));
      expect(offers.first.id, 'soff_1');
      expect(offers.first.productIds, ['a']);
      expect(offers.first.categoryIds, ['c1']);
    });

    test('an offer without an id is numbered by position', () {
      final offers = toSpecialOffers(payload([raw({'id': null})]));
      expect(offers.first.id, '0');
    });
  });

  group('offer colours', () {
    test('keeps a known scheme and reads a missing or unknown one as green', () {
      final offers = toSpecialOffers(payload([
        raw({'id': 'a', 'color': 'ruby'}),
        raw({'id': 'b'}),
        raw({'id': 'c', 'color': '#ff0000'}),
      ]));
      expect(offers.map((o) => o.color), [OfferColor.ruby, OfferColor.green, OfferColor.green]);
    });

    test('offerColorOf maps every key of the admin palette', () {
      expect(offerColorOf('green'), OfferColor.green);
      expect(offerColorOf('gold'), OfferColor.gold);
      expect(offerColorOf('emerald'), OfferColor.emerald);
      expect(offerColorOf('cream'), OfferColor.cream);
      expect(offerColorOf('amber'), OfferColor.amber);
      expect(offerColorOf('ruby'), OfferColor.ruby);
      expect(offerColorOf('charcoal'), OfferColor.charcoal);
      expect(offerColorOf(null), OfferColor.green);
      expect(offerColorOf(42), OfferColor.green);
    });

    test('every scheme has a palette, and green is the site’s dark green with gold ink', () {
      for (final c in OfferColor.values) {
        expect(offerPalettes[c], isNotNull, reason: c.name);
      }
      expect(offerPalettes[OfferColor.green]!.bg, const Color(0xFF041D18));
      expect(offerPalettes[OfferColor.green]!.ink, const Color(0xFFFFC508));
    });
  });

  group('offersForProduct', () {
    final offers = toSpecialOffers(payload([
      raw({'id': 'cat', 'product_ids': <String>[], 'category_ids': ['pcat_rings']}),
      raw({'id': 'pick', 'product_ids': ['prod_1']}),
      raw({'id': 'both', 'product_ids': ['prod_1'], 'category_ids': ['pcat_rings']}),
      raw({'id': 'other', 'product_ids': ['prod_2'], 'category_ids': ['pcat_bars']}),
    ]));

    test('shows every offer reaching the product, picked ones first, each once', () {
      expect(offersForProduct('prod_1', ['pcat_rings'], offers).map((o) => o.id), ['pick', 'both', 'cat']);
    });

    test('reaches a product through its category alone', () {
      expect(offersForProduct('prod_9', ['pcat_rings'], offers).map((o) => o.id), ['cat', 'both']);
      expect(offersForProduct('prod_9', null, offers), isEmpty);
      expect(offersForProduct('prod_9', const [], offers), isEmpty);
    });
  });

  group('offersForCategory', () {
    test('lists a category page’s own offers', () {
      final offers = toSpecialOffers(payload([
        raw({'id': 'other', 'product_ids': ['prod_2'], 'category_ids': ['pcat_bars']}),
        raw({'id': 'pick', 'product_ids': ['prod_1']}),
      ]));
      expect(offersForCategory('pcat_bars', offers).map((o) => o.id), ['other']);
      expect(offersForCategory('pcat_none', offers), isEmpty);
    });
  });
}
