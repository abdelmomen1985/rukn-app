import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/models/product.dart';
import 'package:rukn_thamin/services/catalog_service.dart';
import 'package:rukn_thamin/services/content_service.dart';
import 'package:rukn_thamin/services/search_index.dart';

Article _article(String slug, {String ar = '', String en = '', String excerptAr = '', String excerptEn = ''}) => Article(
      slug: slug,
      titleAr: ar,
      titleEn: en,
      contentAr: '',
      contentEn: '',
      excerptAr: excerptAr,
      excerptEn: excerptEn,
    );

Category _category(String id, {String ar = '', String en = '', String? description}) => Category(
      id: id,
      name: LocalizedText(ar, en),
      handle: id,
      description: description,
    );

void main() {
  group('normalizeSearchText', () {
    test('lowercases and trims', () {
      expect(normalizeSearchText('  Gold RING  '), 'gold ring');
    });

    test('strips harakat and tatweel', () {
      expect(normalizeSearchText('ذَهَب'), 'ذهب');
      expect(normalizeSearchText('ذـهـب'), 'ذهب');
      expect(normalizeSearchText('خَاتَم'), 'خاتم');
    });

    test('folds alef variants, alef maqsura and ta marbuta', () {
      expect(normalizeSearchText('أساور إسوارة آية ٱلله'), 'اساور اسواره ايه الله');
      expect(normalizeSearchText('مستشفى'), 'مستشفي');
      expect(normalizeSearchText('فضة'), 'فضه');
    });
  });

  group('scoreSearchText', () {
    test('exact beats prefix beats substring', () {
      expect(scoreSearchText('ring', 'ring'), 100);
      expect(scoreSearchText('ring set', 'ring'), 60);
      final sub = scoreSearchText('gold ring', 'ring');
      expect(sub, greaterThan(0));
      expect(sub, lessThan(60));
    });

    test('an earlier substring match scores higher', () {
      expect(scoreSearchText('xxring', 'ring'), greaterThan(scoreSearchText('xxxxxxxxxxxxxxxxxxring', 'ring')));
    });

    test('no match and empty inputs score zero', () {
      expect(scoreSearchText('gold', 'silver'), 0);
      expect(scoreSearchText('', 'a'), 0);
      expect(scoreSearchText('a', ''), 0);
    });
  });

  group('SearchIndex', () {
    final index = SearchIndex.fromSources(
      categories: [
        _category('pcat_rings', ar: 'خواتم', en: 'Rings', description: 'Gold and silver rings'),
        _category('pcat_bars', ar: 'سبائك', en: 'Bars'),
        _category('pcat_nameless', ar: '', en: ''),
        _category('pcat_rings', ar: 'خواتم', en: 'Rings again'),
      ],
      articles: [
        _article('gold-guide', ar: 'دليل الذهب', en: 'Gold guide', excerptEn: 'How to buy gold'),
        _article('silver', ar: 'الفضة', en: 'Silver'),
        _article('gold-guide', ar: 'مكرر', en: 'Duplicate slug'),
      ],
    );

    test('skips nameless and duplicate entries', () {
      expect(index.length, 4);
    });

    test('matches Arabic and English titles, ranked by score', () {
      final hits = index.search('ring', lang: 'en');
      expect(hits.first.id, 'pcat_rings');
      expect(hits.first.kind, SearchKind.category);
    });

    test('Arabic query matches through normalisation', () {
      final hits = index.search('خَوَاتِم');
      expect(hits.map((h) => h.id), contains('pcat_rings'));
    });

    test('tells apart a category from an article and exposes the right ids', () {
      final hits = index.search('gold', lang: 'en');
      expect(hits.map((h) => h.id), containsAll(['gold-guide']));
      expect(hits.firstWhere((h) => h.id == 'gold-guide').kind, SearchKind.article);
      expect(index.search('silver', lang: 'en').map((h) => h.id), contains('silver'));
    });

    test('subtitle matches are found but rank below title matches', () {
      final hits = index.search('gold', lang: 'en');
      final ids = hits.map((h) => h.id).toList();
      expect(ids.indexOf('gold-guide'), lessThan(ids.indexOf('pcat_rings')));
    });

    test('empty or blank query returns nothing; limit is respected', () {
      expect(index.search('   '), isEmpty);
      expect(index.search('a', limit: 1).length, lessThanOrEqualTo(1));
    });

    test('title/subtitle fallback per language', () {
      final hit = index.search('silver', lang: 'ar').firstWhere((h) => h.id == 'silver');
      expect(hit.title('ar'), 'الفضة');
      expect(hit.title('en'), 'Silver');
      final barsEn = index.search('bars', lang: 'en').single;
      expect(barsEn.title('ar'), 'سبائك');
    });

    test('empty sources give an empty index', () {
      final empty = SearchIndex.fromSources();
      expect(empty.length, 0);
      expect(empty.search('ring'), isEmpty);
    });
  });

  group('category paging helpers', () {
    String idOf(Product p) => p.id;
    Product p(String id) => mapProduct({'id': id, 'title': id, 'handle': id});

    test('category page size is 100', () {
      expect(categoryPageSize, 100);
    });

    test('uniqueById keeps the first occurrence in order', () {
      final out = uniqueById([p('a'), p('b'), p('a'), p('c'), p('b')], idOf);
      expect(out.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('appendPage dedupes across pages and keeps shown order', () {
      final out = appendPage([p('a'), p('b')], [p('b'), p('c')], idOf);
      expect(out.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('hasMoreProducts follows the Medusa count; no count means nothing more', () {
      expect(hasMoreProducts(100, 250), isTrue);
      expect(hasMoreProducts(250, 250), isFalse);
      expect(hasMoreProducts(100, null), isFalse);
      expect(hasMoreProducts(0, 0), isFalse);
    });
  });
}
