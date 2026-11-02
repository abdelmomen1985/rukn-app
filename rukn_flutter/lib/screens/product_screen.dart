import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/site_analytics.dart';
import '../services/store_settings.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/gold_ticker.dart';
import '../state/wishlist_state.dart';
import '../widgets/common.dart';
import '../widgets/offer_badge.dart';
import '../widgets/product_widgets.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.idOrHandle});
  final String idOrHandle;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _product;
  bool _loading = true;
  Object? _error;
  final Map<String, String> _choices = {};
  int _quantity = 1;
  List<Review> _reviews = [];
  VatInfo _vat = VatInfo.none;
  BranchCatalog _branches = BranchCatalog.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await CatalogService.getProduct(widget.idOrHandle);
      if (!mounted) return;
      if (p != null) {
        stampBaseline(context, [p]);
        _initChoices(p);
        CatalogService.listReviews(p.id).then((r) {
          if (mounted) setState(() => _reviews = r);
        }).catchError((_) {});
        StoreSettings.productVat([p.id]).then((v) {
          if (mounted) setState(() => _vat = v);
        });
        StoreSettings.branchCatalog().then((b) {
          if (mounted) setState(() => _branches = b);
        });
      }
      setState(() => _product = p);
      if (p != null) {
        SiteAnalytics.shared.productViewed(
          productId: p.id,
          variantId: p.variantId ?? p.purchaseOptions.firstOrNull?.variantId ?? p.id,
          value: p.basePrice,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initChoices(Product p) {
    _choices.clear();
    final def = p.purchaseOptions.where((o) => o.variantId == p.variantId).firstOrNull;
    for (final option in p.options) {
      // A size must be chosen deliberately, unless there is only one.
      if (option.kind == ProductOptionKind.size && option.values.length > 1) continue;
      final value = def?.choices[option.title] ?? option.values.first;
      _choices[option.title] = value;
    }
  }

  PurchaseOption? get _selected {
    final p = _product;
    if (p == null) return null;
    if (p.options.isEmpty) return p.purchaseOptions.where((o) => o.variantId == p.variantId).firstOrNull;
    if (p.options.any((o) => !_choices.containsKey(o.title))) return null;
    return p.purchaseOptions
        .where((o) => p.options.every((opt) => o.choices[opt.title] == _choices[opt.title]))
        .firstOrNull;
  }

  bool _valueAvailable(ProductOption option, String value) {
    final p = _product!;
    return p.purchaseOptions.any((o) =>
        o.choices[option.title] == value &&
        p.options.where((x) => x.title != option.title).every((x) => !_choices.containsKey(x.title) || o.choices[x.title] == _choices[x.title]));
  }

  void _addToCart({bool buyNow = false}) {
    final p = _product!;
    final i18n = context.i18nRead;
    final option = _selected;
    if (p.options.isNotEmpty && option == null) {
      showSnack(context, i18n.t('chooseOptionFirst'), error: true);
      return;
    }
    haptic(Haptic.medium);
    final base = option?.price ?? p.basePrice;
    final price = PriceScaler(p.baseline).scale(base, context.read<GoldTicker>().productCatalogPrice);
    final refusal = context.read<CartState>().add(p, option: option, price: price, quantity: _quantity, lang: i18n.lang);
    if (refusal != null) {
      showSnack(context, refusal, error: true);
      return;
    }
    if (buyNow) {
      context.push('/checkout');
    } else {
      showSnack(context, i18n.t('addedToCart'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final p = _product;
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) return Scaffold(appBar: AppBar(), body: ErrorView(onRetry: _load));
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: MessageState(
          icon: Icons.search_off,
          title: i18n.t('productNotFound'),
          action: () => context.go('/'),
          actionLabel: i18n.t('continueShopping'),
        ),
      );
    }

    final wish = context.watch<WishlistState>();
    final option = _selected;
    final price = livePrice(context, p, option?.price ?? p.basePrice);
    final exclusive = _branches.exclusiveLabel(p.id, i18n.lang);
    final vatExempt = _vat.exempt[p.id] == true;
    final weightText = option?.weight?.of(i18n.lang) ?? p.weight.of(i18n.lang);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: MediaQuery.sizeOf(context).width.clamp(280, 520),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(wish.contains(p.id) ? Icons.favorite : Icons.favorite_border,
                    color: wish.contains(p.id) ? AppColors.primary : null),
                onPressed: () {
                  haptic(Haptic.medium);
                  wish.toggle(p.id);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProductGallery(key: ValueKey(p.id), images: p.images),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList.list(
              children: [
                if (p.badge != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusChip(label: p.badge!.of(i18n.lang), color: AppColors.darkGreen),
                  ),
                const SizedBox(height: 6),
                Text(p.name.of(i18n.lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
                if (!p.metaLabel.isEmpty || weightText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      [p.metaLabel.of(i18n.lang), weightText].where((e) => e.isNotEmpty).join(' · '),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Price(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                    if (p.oldPrice != null && p.oldPrice! > price) ...[
                      const SizedBox(width: 10),
                      Price(p.oldPrice!, strike: true, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        vatExempt ? i18n.t('livePriceVatExempt') : i18n.t('livePriceVatIncluded'),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                SpecialOfferBox(productId: p.id, categoryIds: p.categoryIds),
                if (exclusive != null) ...[
                  const SizedBox(height: 12),
                  _Notice(icon: Icons.store_mall_directory_outlined, text: exclusive),
                ],
                for (final opt in p.options) ...[
                  const SizedBox(height: 20),
                  SectionLabel(opt.kind == ProductOptionKind.size ? i18n.t('size') : (opt.kind == ProductOptionKind.weight ? i18n.t('weight') : opt.title)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in opt.values)
                        _OptionTile(
                          label: v,
                          active: _choices[opt.title] == v,
                          available: _valueAvailable(opt, v),
                          onTap: () {
                            haptic();
                            setState(() => _choices[opt.title] = v);
                          },
                        ),
                    ],
                  ),
                ],
                if (p.options.isNotEmpty && option == null && p.options.every((o) => _choices.containsKey(o.title)))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(i18n.t('combinationUnavailable'), style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(i18n.t('quantity'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _Stepper(
                      value: _quantity,
                      onChanged: (v) => setState(() => _quantity = v.clamp(1, 20)),
                    ),
                  ],
                ),
                if (p.certificateSerial != null) ...[
                  const SizedBox(height: 16),
                  CardBox(
                    onTap: () => context.push('/certificate?serial=${Uri.encodeQueryComponent(p.certificateSerial!)}'),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.darkGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i18n.t('barCertificate'), style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(i18n.t('barCertificateHint'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(forwardIcon(context), color: AppColors.muted),
                      ],
                    ),
                  ),
                ],
                if ((p.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionLabel(i18n.t('productDetails')),
                  Text(p.description!.trim(), style: const TextStyle(color: Color(0xFF444444), height: 1.7)),
                ],
                const SizedBox(height: 24),
                _ReviewsSection(product: p, reviews: _reviews),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: p.isPurchasable ? () => _addToCart(buyNow: true) : null,
                  child: Text(i18n.t('buyNow'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GoldButton(
                  label: p.isPurchasable ? i18n.t('addToCart') : i18n.t('productUnavailable'),
                  icon: Icons.add_shopping_cart,
                  onPressed: p.isPurchasable ? _addToCart : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.goldBorder)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.goldText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.goldText, fontSize: 13))),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove, size: 18), onPressed: () => onChanged(value - 1)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add, size: 18), onPressed: () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product, required this.reviews});
  final Product product;
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final avg = reviews.isEmpty ? 0.0 : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          '${i18n.t('reviews')} (${reviews.length})',
          trailing: TextButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => _ReviewForm(productId: product.id),
            ),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: Text(i18n.t('writeReview')),
          ),
        ),
        if (reviews.isEmpty)
          Text(i18n.t('noReviewsYet'), style: const TextStyle(color: AppColors.muted))
        else ...[
          Row(children: [
            _Stars(rating: avg.round()),
            const SizedBox(width: 8),
            Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          for (final r in reviews)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700))),
                    _Stars(rating: r.rating, size: 14),
                  ]),
                  if (r.title.isNotEmpty) Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(r.body, style: const TextStyle(color: Color(0xFF555555), height: 1.5)),
                  if (r.createdAt != null)
                    Text(formatDate(r.createdAt, i18n.lang), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 18, this.onTap});
  final int rating;
  final double size;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.primary),
          ),
      ],
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.productId});
  final String productId;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _rating = 5;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<AuthState>().customer;
    if (c != null) _name.text = c.fullName;
  }

  Future<void> _submit() async {
    final i18n = context.i18nRead;
    if (_name.text.trim().length < 2 || _body.text.trim().length < 3) {
      showSnack(context, i18n.t('reviewRequired'), error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await CatalogService.submitReview(
        productId: widget.productId,
        customerName: _name.text.trim(),
        customerEmail: context.read<AuthState>().customer?.email,
        rating: _rating,
        title: _title.text.trim(),
        body: _body.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, i18n.t('reviewSubmitted'));
    } catch (_) {
      if (mounted) showSnack(context, i18n.t('reviewFailed'), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n.t('writeReview'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Center(child: _Stars(rating: _rating, size: 34, onTap: (v) => setState(() => _rating = v))),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: InputDecoration(hintText: i18n.t('fullName'))),
          const SizedBox(height: 10),
          TextField(controller: _title, decoration: InputDecoration(hintText: i18n.t('reviewTitle'))),
          const SizedBox(height: 10),
          TextField(controller: _body, maxLines: 4, decoration: InputDecoration(hintText: i18n.t('reviewBody'))),
          const SizedBox(height: 8),
          Text(i18n.t('reviewModerationNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          GoldButton(label: i18n.t('submit'), loading: _sending, onPressed: _submit),
        ],
      ),
    );
  }
}

/// The product photo gallery: a swipeable main image, a thumbnail strip over its foot and arrows.
/// Auto-advances every 4.5 s until the customer swipes, taps a thumbnail or an arrow — then it
/// stops for good. Reduced motion (the OS setting) means no auto-advance and no animated slides.
/// A single photo renders alone, with no thumbnails and no arrows.
class _ProductGallery extends StatefulWidget {
  const _ProductGallery({super.key, required this.images});
  final List<String> images;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  static const _interval = Duration(milliseconds: 4500);
  static const _slide = Duration(milliseconds: 600);
  static const _thumb = 56.0;
  static const _thumbGap = 8.0;
  static const _stripPad = 8.0;

  final PageController _pages = PageController();
  final ScrollController _strip = ScrollController();
  Timer? _timer;
  bool _userTookOver = false;
  int _index = 0;

  int get _count => widget.images.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  /// Runs the auto-advance only while it may still move the gallery.
  void _syncTimer() {
    final still = MediaQuery.disableAnimationsOf(context) || _userTookOver || _count < 2;
    if (still) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(_interval, (_) => _advance());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    _strip.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted || !_pages.hasClients || _count < 2) return;
    _pages.animateToPage((_index + 1) % _count, duration: _slide, curve: Curves.easeInOut);
  }

  /// The customer is in charge from now on: no more automatic moves.
  void _takeOver() {
    _userTookOver = true;
    _timer?.cancel();
    _timer = null;
  }

  void _goTo(int i) {
    _takeOver();
    if (!_pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(i, duration: _slide, curve: Curves.easeInOut);
    }
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerThumb(i));
  }

  /// Keeps the active thumbnail in view, scrolling only the strip itself.
  void _centerThumb(int i) {
    if (!mounted || !_strip.hasClients) return;
    final pos = _strip.position;
    final target = (_stripPad + i * (_thumb + _thumbGap) + _thumb / 2 - pos.viewportDimension / 2)
        .clamp(0.0, pos.maxScrollExtent)
        .toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _strip.jumpTo(target);
    } else {
      _strip.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return NetImage(fallbackProductImage);
    if (_count == 1) return NetImage(widget.images.first);

    final i18n = context.i18n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final prevIcon = rtl ? Icons.chevron_right : Icons.chevron_left;
    final nextIcon = rtl ? Icons.chevron_left : Icons.chevron_right;

    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollStartNotification>(
          onNotification: (n) {
            // Only a finger on the screen counts as the customer; our own slides do not.
            if (n.dragDetails != null) _takeOver();
            return false;
          },
          child: PageView.builder(
            controller: _pages,
            itemCount: _count,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) => NetImage(widget.images[i]),
          ),
        ),
        PositionedDirectional(
          start: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: _ArrowButton(
              icon: prevIcon,
              label: i18n.t('galleryPrevious'),
              onTap: () => _goTo((_index - 1 + _count) % _count),
            ),
          ),
        ),
        PositionedDirectional(
          end: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: _ArrowButton(
              icon: nextIcon,
              label: i18n.t('galleryNext'),
              onTap: () => _goTo((_index + 1) % _count),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          height: _thumb + 8,
          child: SingleChildScrollView(
            controller: _strip,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _stripPad),
            child: Semantics(
              container: true,
              label: i18n.t('galleryPhotos'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _count; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: _thumbGap),
                      child: _Thumb(
                        url: widget.images[i],
                        label: i18n.t('galleryPhoto', {'n': '${i + 1}'}),
                        active: i == _index,
                        onTap: () => _goTo(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: AppColors.deepGreen),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.label, required this.active, required this.onTap});
  final String url;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.deepGreen,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppColors.primary : Colors.white70, width: 2),
          ),
          child: Opacity(
            opacity: active ? 1 : 0.65,
            child: NetImage(url, radius: 5),
          ),
        ),
      ),
    );
  }
}

/// A weight / size choice as a bordered tile: pale-gold border at rest, gold border on a gold wash
/// when chosen (dark green ink), dashed border with struck-through grey text when unavailable.
class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.active, required this.available, required this.onTap});
  final String label;
  final bool active;
  final bool available;
  final VoidCallback onTap;

  static const _gold = Color(0xFFFFC508);
  static const _paleGold = Color(0xFFF0E6C4);
  static const _goldWash = Color(0xFFFFFAEB);
  static const _unavailable = Color(0xFFE7E9EC);
  static const _radius = 6.0;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active && available ? _goldWash : Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: available
            ? Border.all(color: active ? _gold : _paleGold, width: 2)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: available ? AppColors.deepGreen : const Color(0xFF9CA3AF),
          decoration: available ? TextDecoration.none : TextDecoration.lineThrough,
          decorationColor: const Color(0xFF9CA3AF),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: active,
      enabled: available,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: onTap,
          child: available
              ? tile
              : CustomPaint(
                  foregroundPainter: _DashedBorderPainter(color: _unavailable, radius: _radius),
                  child: tile,
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + dash) < metric.length ? d + dash : metric.length;
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}
