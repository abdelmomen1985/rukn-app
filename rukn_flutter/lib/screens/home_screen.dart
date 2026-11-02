import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/home_content_service.dart';
import '../services/store_settings.dart';
import '../state/cart_state.dart';
import '../state/gold_ticker.dart';
import '../state/wishlist_state.dart';
import '../widgets/common.dart';
import '../widgets/home_rails.dart';
import '../widgets/product_widgets.dart';
import '../widgets/ticker_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 24;

  List<Category> _categories = [];
  List<Product> _exclusive = [];
  // Admin-managed home content. A null list means "keep the built-in content".
  List<HomeCategorySection>? _homeSections;
  List<HomeProductSection>? _productSections;
  Map<String, Product> _productsByHandle = {};
  final List<Product> _products = [];
  AnnouncementBar? _announcement;
  String? _categoryId;
  int _count = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    StoreSettings.announcements().then((a) {
      if (mounted) setState(() => _announcement = a);
    });
    CatalogService.listCategories().then((c) {
      if (mounted) setState(() => _categories = c.where((x) => x.isTopLevel).toList());
    }).catchError((_) {});
    _loadHomeContent(refresh: refresh);
    await _loadProducts(reset: true);
  }

  /// Admin-managed category sections and product sections. A failed product-section fetch, or
  /// one whose products cannot be resolved, falls back to the legacy exclusive rail.
  Future<void> _loadHomeContent({bool refresh = false}) async {
    final categories = await HomeContentService.homeCategories(refresh: refresh);
    var sections = await HomeContentService.productSections(refresh: refresh);
    var byHandle = <String, Product>{};
    if (sections != null && sections.isNotEmpty) {
      try {
        byHandle = await HomeContentService.resolveProducts(sections);
      } catch (_) {
        sections = null;
      }
    }
    if (!mounted) return;
    stampBaseline(context, byHandle.values);
    setState(() {
      _homeSections = categories;
      _productSections = sections;
      _productsByHandle = byHandle;
    });
    if (sections == null) _loadExclusive();
  }

  Future<void> _loadExclusive() async {
    try {
      final items = await CatalogService.exclusiveProducts();
      if (items.isEmpty) return;
      final byHandle = await CatalogService.getProductsByHandles(items.map((e) => e.handle).toList());
      if (!mounted) return;
      final list = [for (final i in items) ?byHandle[i.handle]];
      stampBaseline(context, list);
      setState(() => _exclusive = list);
    } catch (_) {}
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await CatalogService.listProducts(
        categoryId: _categoryId,
        limit: _pageSize,
        offset: reset ? 0 : _products.length,
      );
      if (!mounted) return;
      stampBaseline(context, page.products);
      setState(() {
        if (reset) _products.clear();
        _products.addAll(page.products);
        _count = page.count;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _selectCategory(String? id) {
    if (id == _categoryId) return;
    haptic();
    setState(() => _categoryId = id);
    _loadProducts(reset: true);
  }

  List<HomeCategorySection> _sectionsIn(HomeSectionPlacement placement) =>
      [for (final s in _homeSections ?? const <HomeCategorySection>[]) if (s.placement == placement) s];

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.darkGreen,
        onRefresh: () async {
          context.read<GoldTicker>().refresh();
          await _loadAll(refresh: true);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 600 && !_loading && !_loadingMore && _error == null && _products.length < _count) {
              _loadProducts();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: HomeHeader()),
              if (_announcement != null) SliverToBoxAdapter(child: _AnnouncementStrip(bar: _announcement!)),
              const SliverToBoxAdapter(child: LiveTickerStrip()),
              const SliverToBoxAdapter(child: _HeroCarousel()),
              for (final section in _sectionsIn(HomeSectionPlacement.hero))
                SliverToBoxAdapter(child: HomeCategoryRail(section: section)),
              SliverToBoxAdapter(child: _QuickLinks()),
              for (final section in _sectionsIn(HomeSectionPlacement.body))
                SliverToBoxAdapter(child: HomeCategoryRail(section: section)),
              if (_productSections != null)
                for (final section in _productSections!)
                  SliverToBoxAdapter(
                    child: HomeProductRail(section: section, productsByHandle: _productsByHandle),
                  )
              else if (_exclusive.isNotEmpty) ...[
                SliverToBoxAdapter(child: _SectionTitle(title: i18n.t('exclusiveProducts'))),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 290,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _exclusive.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ProductCard(product: _exclusive[i], width: 170),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: i18n.t('newArrivals'),
                  action: i18n.t('search'),
                  onAction: () => context.push('/search'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill(label: i18n.t('all'), active: _categoryId == null, onTap: () => _selectCategory(null), dense: true),
                      ),
                      for (final c in _categories)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Pill(label: c.name.of(i18n.lang), active: _categoryId == c.id, onTap: () => _selectCategory(c.id), dense: true),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_loading)
                const SliverToBoxAdapter(child: LoadingView())
              else if (_error != null)
                SliverToBoxAdapter(child: ErrorView(onRetry: () => _loadProducts(reset: true)))
              else if (_products.isEmpty)
                SliverToBoxAdapter(
                  child: MessageState(icon: Icons.diamond_outlined, title: i18n.t('noProductsFound')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: ProductSliverGrid(products: _products),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _loadingMore ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark-green brand header: search, logo, wishlist and cart with badges.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final cart = context.watch<CartState>().itemCount;
    final wish = context.watch<WishlistState>().count;
    final top = MediaQuery.paddingOf(context).top;

    Widget iconWithBadge(IconData icon, int count, VoidCallback onTap) => IconButton(
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: AppColors.primary,
            textColor: AppColors.darkGreen,
            label: Text('$count'),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
        );

    return Container(
      color: AppColors.darkGreen,
      padding: EdgeInsets.fromLTRB(12, top + 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search, color: AppColors.primary),
                label: Text(i18n.t('search'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Image.asset('assets/images/logo.webp', width: 58, height: 58, fit: BoxFit.contain),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                iconWithBadge(Icons.favorite_border, wish, () => StatefulNavigationShell.maybeOf(context)?.goBranch(1)),
                iconWithBadge(Icons.shopping_bag_outlined, cart, () => StatefulNavigationShell.maybeOf(context)?.goBranch(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementStrip extends StatefulWidget {
  const _AnnouncementStrip({required this.bar});
  final AnnouncementBar bar;

  @override
  State<_AnnouncementStrip> createState() => _AnnouncementStripState();
}

class _AnnouncementStripState extends State<_AnnouncementStrip> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.bar.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) setState(() => _index = (_index + 1) % widget.bar.items.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final item = widget.bar.items[_index % widget.bar.items.length];
    final (bg, fg) = switch (widget.bar.theme) {
      'green' => (AppColors.darkGreen, AppColors.primary),
      'cream' => (AppColors.cream, AppColors.darkGreen),
      _ => (AppColors.primary, AppColors.darkGreen),
    };
    final text = i18n.pick(item.textAr, item.textEn);
    return Material(
      color: bg,
      child: InkWell(
        onTap: item.href == null ? null : () => launchUrl(Uri.parse(item.href!), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              text,
              key: ValueKey(item.id),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;
  static const _images = ['assets/images/slider_1.jpg', 'assets/images/slider_2.jpg', 'assets/images/slider_3.jpg'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _images.length, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _images.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (_, i) => Image.asset(_images[i], fit: BoxFit.cover),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 36,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i18n.t('heroTitle'),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(i18n.t('heroSubtitle'), style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : Colors.white60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shortcuts to the website features that now live in the app.
class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final links = [
      (Icons.candlestick_chart_outlined, i18n.t('livePrices'), '/pricing'),
      (Icons.verified_outlined, i18n.t('verifyCertificate'), '/certificate'),
      (Icons.notifications_active_outlined, i18n.t('priceAlerts'), '/invest/alerts'),
      (Icons.menu_book_outlined, i18n.t('blog'), '/blog'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          for (final (icon, label, route) in links)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push(route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.cream,
                        child: Icon(icon, color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 6),
                      Text(label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
