import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/search_index.dart';
import '../services/site_analytics.dart';
import '../widgets/common.dart';
import '../widgets/offer_badge.dart';
import '../widgets/product_widgets.dart';

/// Paginated product grid: a category, a search, or the whole shop.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.categoryId, this.title, this.search = false, this.initialQuery});

  final String? categoryId;
  final String? title;
  final bool search;
  final String? initialQuery;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _shopPageSize = 24;
  static const _maxCategoryHits = 6;
  static const _maxArticleHits = 4;

  int get _pageSize => widget.categoryId != null ? categoryPageSize : _shopPageSize;

  List<Product> _products = [];
  late final TextEditingController _query = TextEditingController(text: widget.initialQuery ?? '');
  /// Medusa's total for the current listing; null when Medusa sent no count.
  int? _total;
  /// Medusa offset of the next page. Tracked apart from the product count, which dedupe may shorten.
  int _nextOffset = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  Object? _error;
  Timer? _debounce;
  int _requestId = 0;
  String? _categoryTitle;
  /// Local categories and articles for search; null until loaded (or if loading failed).
  SearchIndex? _index;

  @override
  void initState() {
    super.initState();
    if (!widget.search || _query.text.trim().isNotEmpty) _load(reset: true);
    if (widget.search) {
      SearchIndex.load().then((index) {
        if (mounted) setState(() => _index = index);
      });
    }
    if (widget.categoryId != null && widget.title == null) {
      CatalogService.listCategories().then((cats) {
        final c = cats.where((c) => c.id == widget.categoryId).firstOrNull;
        if (c != null && mounted) setState(() => _categoryTitle = c.name.of(context.i18nRead.lang));
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final id = ++_requestId;
    final offset = reset ? 0 : _nextOffset;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
      _loadMoreFailed = false;
    });
    try {
      final page = await CatalogService.listProducts(
        categoryId: widget.categoryId,
        query: widget.search ? _query.text : null,
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted || id != _requestId) return;
      stampBaseline(context, page.products);
      setState(() {
        final incoming = page.products;
        _products = reset
            ? uniqueById(incoming, (p) => p.id)
            : appendPage(_products, incoming, (p) => p.id);
        _total = page.countKnown ? page.count : null;
        _nextOffset = offset + _pageSize;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        if (reset) {
          _error = e;
        } else {
          _loadMoreFailed = true;
        }
      });
    } finally {
      if (mounted && id == _requestId) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _submitSearch() {
    SiteAnalytics.shared.search(_query.text);
    _load(reset: true);
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query.text.trim().isEmpty) {
        setState(() {
          _products = [];
          _total = null;
          _nextOffset = 0;
          _error = null;
          _loadMoreFailed = false;
        });
        return;
      }
      _load(reset: true);
    });
  }

  List<SearchHit> _hitsFor(String lang, SearchKind kind, int max) {
    final index = _index;
    if (!widget.search || index == null || _query.text.trim().isEmpty) return const [];
    return index.search(_query.text, lang: lang, limit: 50).where((h) => h.kind == kind).take(max).toList();
  }

  void _openHit(SearchHit hit, String lang) {
    if (hit.kind == SearchKind.category) {
      context.push('/category/${Uri.encodeComponent(hit.id)}?title=${Uri.encodeQueryComponent(hit.title(lang))}');
    } else {
      context.push('/blog/${Uri.encodeComponent(hit.id)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final lang = i18n.lang;
    final title = widget.title ?? _categoryTitle ?? (widget.search ? i18n.t('search') : i18n.t('shopAll'));
    final categoryHits = _hitsFor(lang, SearchKind.category, _maxCategoryHits);
    final articleHits = _hitsFor(lang, SearchKind.article, _maxArticleHits);
    final hasLocalHits = categoryHits.isNotEmpty || articleHits.isNotEmpty;
    final hasMore = _error == null && _products.isNotEmpty && hasMoreProducts(_products.length, _total);

    Widget body;
    if (_loading) {
      body = const SliverToBoxAdapter(child: LoadingView());
    } else if (_error != null) {
      body = SliverToBoxAdapter(child: ErrorView(onRetry: () => _load(reset: true)));
    } else if (widget.search && _query.text.trim().isEmpty) {
      body = SliverToBoxAdapter(
        child: MessageState(icon: Icons.search, title: i18n.t('searchHint')),
      );
    } else if (_products.isEmpty) {
      body = hasLocalHits
          ? const SliverToBoxAdapter(child: SizedBox.shrink())
          : SliverToBoxAdapter(
              child: MessageState(icon: Icons.diamond_outlined, title: i18n.t('noProductsFound')),
            );
    } else {
      body = SliverMainAxisGroup(
        slivers: [
          if (hasLocalHits)
            SliverToBoxAdapter(child: _SectionHeader(title: i18n.t('searchSectionProducts'), icon: Icons.diamond_outlined)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: ProductSliverGrid(products: _products),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: widget.search
            ? TextField(
                controller: _query,
                autofocus: widget.initialQuery == null,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: (_) => _submitSearch(),
                decoration: InputDecoration(
                  hintText: i18n.t('searchPlaceholder'),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _query.clear();
                            _onQueryChanged('');
                          },
                        ),
                ),
              )
            : Text(title),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 600 &&
              !_loading &&
              !_loadingMore &&
              !_loadMoreFailed &&
              hasMore) {
            _load();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            if (widget.categoryId != null)
              SliverToBoxAdapter(child: CategoryOfferBanner(categoryId: widget.categoryId!)),
            if (widget.search && categoryHits.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader(title: i18n.t('searchSectionCategories'), icon: Icons.folder_outlined)),
              SliverList.builder(
                itemCount: categoryHits.length,
                itemBuilder: (_, i) => _HitTile(
                  hit: categoryHits[i],
                  lang: lang,
                  icon: Icons.folder_outlined,
                  onTap: () => _openHit(categoryHits[i], lang),
                ),
              ),
            ],
            if (widget.search && articleHits.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader(title: i18n.t('searchSectionArticles'), icon: Icons.article_outlined)),
              SliverList.builder(
                itemCount: articleHits.length,
                itemBuilder: (_, i) => _HitTile(
                  hit: articleHits[i],
                  lang: lang,
                  icon: Icons.article_outlined,
                  onTap: () => _openHit(articleHits[i], lang),
                ),
              ),
            ],
            if (!_loading && _products.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Text(i18n.t('resultsCount', {'n': _total ?? _products.length}),
                      style: const TextStyle(color: AppColors.muted)),
                ),
              ),
            body,
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _footer(i18n, hasMore),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _footer(I18n i18n, bool hasMore) {
    if (_loadingMore) {
      return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));
    }
    if (_loadMoreFailed) {
      return Column(
        children: [
          Text(i18n.t('categoryLoadMoreFailed'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _load(), child: Text(i18n.t('categoryLoadMore'))),
        ],
      );
    }
    if (hasMore) {
      return Center(
        child: OutlinedButton(onPressed: () => _load(), child: Text(i18n.t('categoryLoadMore'))),
      );
    }
    return null;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.darkGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
        ],
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.lang, required this.icon, required this.onTap});
  final SearchHit hit;
  final String lang;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = hit.subtitle(lang);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.muted),
      title: Text(hit.title(lang), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
