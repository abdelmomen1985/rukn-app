import 'dart:math' as math;

import '../models/product.dart';
import 'catalog_service.dart';
import 'content_service.dart';

/// Local search over categories and blog articles (port of rukn-site/src/hooks/useSearchIndex.ts).
/// Products are searched server-side by Medusa; this index only covers what the app can
/// match without a request per keystroke.

enum SearchKind { category, article }

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.subtitleAr = '',
    this.subtitleEn = '',
    this.score = 0,
  });

  final SearchKind kind;
  /// Category id (for `/category/:id`) or article slug (for `/blog/:slug`).
  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final int score;

  String title(String lang) => _pick(titleAr, titleEn, lang);
  String subtitle(String lang) => _pick(subtitleAr, subtitleEn, lang);

  SearchHit withScore(int value) => SearchHit(
        kind: kind,
        id: id,
        titleAr: titleAr,
        titleEn: titleEn,
        subtitleAr: subtitleAr,
        subtitleEn: subtitleEn,
        score: value,
      );
}

String _pick(String ar, String en, String lang) =>
    lang == 'ar' ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);

final _arabicDiacritics = RegExp('[ؐ-ًؚ-ٟۖ-ٰۭـ]');

/// Alef variants → bare alef, alef maqsura → ya, ta marbuta → ha (the site's fold table).
const Map<String, String> _arabicFold = {
  'آ': 'ا', // آ
  'أ': 'ا', // أ
  'إ': 'ا', // إ
  'ٱ': 'ا', // ٱ
  'ى': 'ي', // ى
  'ة': 'ه', // ة
};

/// Lowercase, strip Arabic diacritics and tatweel, fold alef/ya/ta-marbuta, trim.
String normalizeSearchText(String input) {
  final lower = input.toLowerCase().replaceAll(_arabicDiacritics, '');
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    buffer.write(_arabicFold[ch] ?? ch);
  }
  return buffer.toString().trim();
}

/// Score of one normalised query against one normalised haystack. Higher is better:
/// exact 100, prefix 60, any substring 30 plus a small bonus for an early or repeated match.
int scoreSearchText(String haystack, String query) {
  if (haystack.isEmpty || query.isEmpty) return 0;
  if (haystack == query) return 100;
  if (haystack.startsWith(query)) return 60;
  final idx = haystack.indexOf(query);
  if (idx == -1) return 0;
  var base = 30;
  base += math.max(0, 10 - math.min(10, idx ~/ 4));
  final occurrences = haystack.split(query).length - 1;
  if (occurrences > 1) base += math.min(10, occurrences * 2);
  return base;
}

class _Entry {
  _Entry(this.hit, this.enHay, this.arHay);
  final SearchHit hit;
  final String enHay;
  final String arHay;
}

/// Ranked corpus of categories and articles.
class SearchIndex {
  SearchIndex._(this._entries);

  final List<_Entry> _entries;

  /// Blog posts requested for the index, as the site does.
  static const _blogIndexLimit = 250;

  static SearchIndex? _loaded;
  static Future<SearchIndex>? _loading;

  /// Builds the index from already-fetched data. Categories without a name and duplicate
  /// ids or slugs are skipped.
  factory SearchIndex.fromSources({List<Category> categories = const [], List<Article> articles = const []}) {
    final entries = <_Entry>[];
    final seenCategories = <String>{};
    for (final c in categories) {
      if (c.id.isEmpty || c.name.isEmpty || !seenCategories.add(c.id)) continue;
      final hit = SearchHit(
        kind: SearchKind.category,
        id: c.id,
        titleAr: c.name.ar.isNotEmpty ? c.name.ar : c.name.en,
        titleEn: c.name.en.isNotEmpty ? c.name.en : c.name.ar,
        subtitleAr: c.description ?? '',
        subtitleEn: c.description ?? '',
      );
      entries.add(_entryFor(hit));
    }
    final seenSlugs = <String>{};
    for (final a in articles) {
      if (a.slug.isEmpty || !seenSlugs.add(a.slug)) continue;
      final hit = SearchHit(
        kind: SearchKind.article,
        id: a.slug,
        titleAr: a.title('ar'),
        titleEn: a.title('en'),
        subtitleAr: a.excerptAr.isNotEmpty ? a.excerptAr : a.excerptEn,
        subtitleEn: a.excerptEn.isNotEmpty ? a.excerptEn : a.excerptAr,
      );
      entries.add(_entryFor(hit));
    }
    return SearchIndex._(entries);
  }

  static _Entry _entryFor(SearchHit hit) {
    String haystack(String title, String subtitle) =>
        normalizeSearchText([title, subtitle].where((s) => s.isNotEmpty).join(' • '));
    return _Entry(
      hit,
      haystack(hit.titleEn, hit.subtitleEn),
      haystack(hit.titleAr, hit.subtitleAr),
    );
  }

  int get length => _entries.length;

  /// Ranked hits for [query]. A hit matching in both languages gets a bonus, and one matching
  /// in the active [lang] a smaller bonus. Ties sort by English title.
  List<SearchHit> search(String query, {String lang = 'ar', int limit = 12}) {
    final q = normalizeSearchText(query);
    if (q.isEmpty) return const [];
    final scored = <SearchHit>[];
    for (final e in _entries) {
      final en = scoreSearchText(e.enHay, q);
      final ar = scoreSearchText(e.arHay, q);
      final total = math.max(en, ar);
      if (total <= 0) continue;
      final bilingual = en > 0 && ar > 0 ? 5 : 0;
      final activeBonus = (lang == 'en' ? en : ar) > 0 ? 3 : 0;
      scored.add(e.hit.withScore(total + bilingual + activeBonus));
    }
    scored.sort((a, b) => a.score != b.score
        ? b.score.compareTo(a.score)
        : a.titleEn.compareTo(b.titleEn));
    return scored.take(limit).toList();
  }

  /// Loads categories and blog posts once and caches the index. A source that fails
  /// contributes nothing; if every source fails the result is empty and not cached, so a
  /// later search retries.
  static Future<SearchIndex> load() {
    final loaded = _loaded;
    if (loaded != null) return Future.value(loaded);
    return _loading ??= _fetch();
  }

  static Future<SearchIndex> _fetch() async {
    var anySucceeded = false;
    final categories = CatalogService.listCategories()
        .then((c) {
          anySucceeded = true;
          return c;
        })
        .catchError((_) => <Category>[]);
    final articles = ContentService.blogPosts(limit: _blogIndexLimit)
        .then((a) {
          anySucceeded = true;
          return a;
        })
        .catchError((_) => <Article>[]);
    final index = SearchIndex.fromSources(categories: await categories, articles: await articles);
    if (anySucceeded) {
      _loaded = index;
    }
    _loading = null;
    return index;
  }
}
