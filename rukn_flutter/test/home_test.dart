import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/core/config.dart';
import 'package:rukn_thamin/services/home_content_service.dart';

String describe(HomeLinkTarget t) => switch (t) {
      InAppLink(:final route) => 'app:$route',
      ExternalLink(:final url) => 'web:$url',
    };

Map<String, dynamic> tile({
  Object? image = '/categories/ctg-rings.jpg',
  Object? link,
  Object? category,
  Object? titleAr = 'خواتم',
  Object? titleEn = 'Rings',
  String? id,
}) =>
    {
      'id': ?id,
      'image_url': image,
      'link_url': link,
      'category': category,
      'title_ar': titleAr,
      'title_en': titleEn,
    };

void main() {
  group('safeLink', () {
    test('accepts anchors, site paths, http(s); refuses everything else', () {
      expect(safeLink('#collections'), '#collections');
      expect(safeLink('  /ar/category/abc  '), '/ar/category/abc');
      expect(safeLink('https://example.com/x'), 'https://example.com/x');
      expect(safeLink('HTTP://example.com'), 'HTTP://example.com');
      expect(safeLink('//evil.example'), isNull);
      expect(safeLink('javascript:alert(1)'), isNull);
      expect(safeLink('mailto:a@b.c'), isNull);
      expect(safeLink('#has space'), isNull);
      expect(safeLink('   '), isNull);
      expect(safeLink(42), isNull);
      expect(safeLink(null), isNull);
    });
  });

  group('toHomeCategorySections', () {
    test('null when the payload has no sections list (keep the built-in rails)', () {
      expect(toHomeCategorySections(null), isNull);
      expect(toHomeCategorySections(<String, dynamic>{}), isNull);
      expect(toHomeCategorySections({'sections': 'nope'}), isNull);
    });

    test('empty list when the operator switched everything off (render nothing)', () {
      expect(toHomeCategorySections({'sections': <dynamic>[]}), isEmpty);
    });

    test('keeps order, layout and placement; defaults to cards / body', () {
      final out = toHomeCategorySections({
        'sections': [
          {
            'id': 's1',
            'layout': 'circles',
            'placement': 'hero',
            'items': [tile(link: '/ar/category/c1')],
          },
          {
            'id': 's2',
            'items': [tile(category: {'id': 'cat_1', 'name': 'x'})],
          },
        ],
      })!;
      expect(out.map((s) => s.id), ['s1', 's2']);
      expect(out[0].layout, HomeSectionLayout.circles);
      expect(out[0].placement, HomeSectionPlacement.hero);
      expect(out[1].layout, HomeSectionLayout.cards);
      expect(out[1].placement, HomeSectionPlacement.body);
    });

    test('drops tiles without an image, without a link or category, or without a title', () {
      final out = toHomeCategorySections({
        'sections': [
          {
            'id': 's',
            'items': [
              tile(image: null, link: '/pricing'),
              tile(image: 'javascript:x', link: '/pricing'),
              tile(), // no link and no category
              tile(link: '/pricing', titleAr: '  ', titleEn: ''),
              tile(link: '/pricing', titleAr: 'ok', titleEn: ''),
            ],
          },
        ],
      })!;
      expect(out, hasLength(1));
      expect(out.single.tiles, hasLength(1));
      expect(out.single.tiles.single.titleAr, 'ok');
    });

    test('a link wins over the category; the category name stands in for a missing Arabic title', () {
      final out = toHomeCategorySections({
        'sections': [
          {
            'id': 's',
            'items': [
              tile(link: '/ar/blog', category: {'id': 'cat_9', 'name': 'اسم الفئة'}, titleAr: ''),
              tile(category: {'id': 'cat_9', 'name': 'اسم الفئة'}, titleAr: '', titleEn: ''),
            ],
          },
        ],
      })!;
      final tiles = out.single.tiles;
      expect(tiles, hasLength(2));
      expect(tiles.first.link, '/ar/blog');
      expect(tiles.first.categoryId, 'cat_9');
      expect(tiles.first.titleAr, 'اسم الفئة');
      // Second tile has no link of its own; its category routes it.
      expect(tiles.last.link, isNull);
      expect(tiles.last.categoryId, 'cat_9');
      expect(tiles.last.titleAr, 'اسم الفئة');
    });

    test('a section whose tiles are all invalid is dropped', () {
      final out = toHomeCategorySections({
        'sections': [
          {'id': 'empty', 'items': <dynamic>[]},
          {'id': 'bad', 'items': [tile(image: null, link: '/x')]},
        ],
      });
      expect(out, isEmpty);
    });

    test('view-all needs a safe url; labels default to the built-in wording', () {
      final out = toHomeCategorySections({
        'sections': [
          {
            'id': 'a',
            'view_all': {'url': '/ar/shop', 'label_ar': '', 'label_en': ''},
            'items': [tile(link: '/x')],
          },
          {
            'id': 'b',
            'view_all': {'url': 'javascript:alert(1)', 'label_ar': 'x', 'label_en': 'y'},
            'items': [tile(link: '/x')],
          },
          {
            'id': 'c',
            'view_all': {'url': '/shop', 'label_ar': 'المزيد', 'label_en': 'More'},
            'items': [tile(link: '/x')],
          },
        ],
      })!;
      expect(out[0].viewAll!.href, '/ar/shop');
      expect(out[0].viewAll!.labelAr, 'عرض الكل');
      expect(out[0].viewAll!.labelEn, 'View all');
      expect(out[1].viewAll, isNull);
      expect(out[2].viewAll!.labelAr, 'المزيد');
      expect(out[2].viewAll!.labelEn, 'More');
    });

    test('tile image, alt and descriptions are carried through', () {
      final out = toHomeCategorySections({
        'sections': [
          {
            'id': 's',
            'items': [
              {
                'id': 'tile-1',
                'image_url': 'https://cdn.example/a.jpg',
                'image_alt': ' Gold rings ',
                'link_url': '#collections',
                'title_ar': 'خواتم',
                'title_en': 'Rings',
                'description_ar': 'وصف',
                'description_en': 'Desc',
              },
            ],
          },
        ],
      })!;
      final t = out.single.tiles.single;
      expect(t.id, 'tile-1');
      expect(t.image, 'https://cdn.example/a.jpg');
      expect(t.alt, 'Gold rings');
      expect(t.link, '#collections');
      expect(t.descriptionEn, 'Desc');
      expect(t.title, 'خواتم');
    });
  });

  group('toProductSections', () {
    test('null when the payload has no sections list (keep the legacy exclusive rail)', () {
      expect(toProductSections(null), isNull);
      expect(toProductSections({'sections': null}), isNull);
    });

    test('empty list when every section is switched off (render nothing)', () {
      expect(toProductSections({'sections': <dynamic>[]}), isEmpty);
    });

    test('items need an id and a handle; sections need items', () {
      final out = toProductSections({
        'sections': [
          {
            'id': 'sec',
            'items': [
              {'id': 'i1', 'handle': 'ring-1', 'order': 2},
              {'id': 'i2', 'handle': ''},
              {'handle': 'no-id'},
              'not a map',
            ],
          },
          {
            'id': 'empty',
            'items': [
              {'id': 'i3'},
            ],
          },
        ],
      })!;
      expect(out.map((s) => s.id), ['sec']);
      expect(out.single.items.single.handle, 'ring-1');
      expect(out.single.items.single.order, 2);
    });

    test('keeps the operator order of items', () {
      final out = toProductSections({
        'sections': [
          {
            'id': 's',
            'items': [
              {'id': 'b', 'handle': 'b', 'order': 5},
              {'id': 'a', 'handle': 'a', 'order': 1},
            ],
          },
        ],
      })!;
      expect(out.single.items.map((i) => i.handle), ['b', 'a']);
    });

    test('overlays trim, drop empties, and badgeDark is true only when true', () {
      final out = toProductSections({
        'sections': [
          {
            'id': 's',
            'title': {'ar': ' الحصرية ', 'en': '  '},
            'subtitle': {'ar': '', 'en': ''},
            'items': [
              {
                'id': 'i',
                'handle': 'h',
                'badgeDark': true,
                'badge': {'ar': ' جديد ', 'en': ''},
                'metaLabel': {'ar': '', 'en': 'Ring'},
              },
              {'id': 'j', 'handle': 'k', 'badgeDark': 'yes'},
            ],
          },
        ],
      })!;
      final s = out.single;
      expect(s.title.ar, 'الحصرية');
      expect(s.title.en, '');
      expect(s.subtitle, isNull);
      expect(s.items[0].badgeDark, isTrue);
      expect(s.items[0].badge!.ar, 'جديد');
      expect(s.items[0].badge!.en, '');
      expect(s.items[0].metaLabel!.en, 'Ring');
      expect(s.items[0].metaLabel!.ar, '');
      expect(s.items[1].badgeDark, isFalse);
      expect(s.items[1].badge, isNull);
      expect(s.items[1].order, 0);
    });

    test('view-all only with a safe url', () {
      List<HomeProductSection>? parse(Object? viewAll) =>
          toProductSections({
            'sections': [
              {
                'id': 's',
                'viewAll': viewAll,
                'items': [
                  {'id': 'i', 'handle': 'h'},
                ],
              },
            ],
          });
      expect(parse({'url': '/ar/shop', 'label': {'ar': 'الكل', 'en': 'All'}})!.single.viewAllHref, '/ar/shop');
      expect(parse({'url': '/ar/shop', 'label': {'ar': 'الكل', 'en': 'All'}})!.single.viewAllLabel!.en, 'All');
      expect(parse({'url': 'javascript:1'})!.single.viewAllHref, isNull);
      expect(parse(null)!.single.viewAllHref, isNull);
    });
  });

  group('resolveSiteLink', () {
    const origin = 'https://rknthmin.com.sa/';
    String go(String href, [String lang = 'ar']) => describe(resolveSiteLink(href, lang: lang, origin: origin));

    test('category paths, with or without a language prefix, go to the in-app category route', () {
      expect(go('/ar/category/pcat_1'), 'app:/category/pcat_1');
      expect(go('/en/category/pcat_1'), 'app:/category/pcat_1');
      expect(go('/category/pcat_1'), 'app:/category/pcat_1');
      expect(go('/category/pcat_1/'), 'app:/category/pcat_1');
    });

    test('product paths go to the in-app product route', () {
      expect(go('/ar/product/prod_1'), 'app:/product/prod_1');
      expect(go('/product/aurora-ring?x=1'), 'app:/product/aurora-ring');
    });

    test('articles, pricing, search, certificate and invest pages map to app routes', () {
      expect(go('/ar/articles'), 'app:/blog');
      expect(go('/articles/policy'), 'app:/blog/policy');
      expect(go('/en/pricing'), 'app:/pricing');
      expect(go('/search'), 'app:/search');
      expect(go('/certificate'), 'app:/certificate');
      expect(go('/certificate/RK-42'), 'app:/certificate?serial=RK-42');
      expect(go('/ar/invest/zakat'), 'app:/invest/zakat');
    });

    test('anchors, unmapped site paths and the bare home page open on the website', () {
      expect(go('#collections'), 'web:https://rknthmin.com.sa/ar/#collections');
      expect(go('/ar/gifts'), 'web:https://rknthmin.com.sa/ar/gifts');
      expect(go('/en/cart'), 'web:https://rknthmin.com.sa/en/cart');
      expect(go('/cart', 'en'), 'web:https://rknthmin.com.sa/en/cart');
    });

    test('http(s) links open as given, externally', () {
      expect(go('https://example.com/a?b=1'), 'web:https://example.com/a?b=1');
    });

    test('category route encodes the id', () {
      expect(categoryRoute('pcat 1'), '/category/pcat%201');
    });

    test('site-relative images are served by the website; absolute ones are kept', () {
      expect(homeImageUrl('/categories/ctg-rings.jpg'), '${AppConfig.origin}/categories/ctg-rings.jpg');
      expect(homeImageUrl('https://cdn.example/a.jpg'), 'https://cdn.example/a.jpg');
    });
  });
}
