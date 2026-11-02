import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../models/portfolio.dart';
import '../../services/invest_service.dart';
import '../../state/alerts_state.dart';
import '../../state/auth_state.dart';
import '../../state/portfolio_state.dart';
import '../../state/trips_state.dart';
import '../../widgets/common.dart';
import '../../widgets/ticker_widgets.dart';
import '../payment_webview_screen.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  String _sort = 'value';
  String _filter = 'all';
  PortfolioAccess _access = PortfolioAccess.open;
  SubscriptionConfig? _plans;
  String? _accessFor;

  Future<void> _checkAccess(String? customerId) async {
    if (customerId == _accessFor) return;
    _accessFor = customerId;
    if (customerId == null) {
      setState(() => _access = PortfolioAccess.open);
      return;
    }
    try {
      final config = await InvestService.subscriptionConfig();
      if (!config.paid) {
        if (mounted) setState(() => _access = PortfolioAccess.open);
        return;
      }
      final access = await InvestService.portfolioAccess();
      if (mounted) {
        setState(() {
          _plans = config;
          _access = access;
        });
      }
    } catch (_) {
      // A paywall that cannot be checked stays open rather than locking people out.
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final portfolio = context.watch<PortfolioState>();
    final customerId = context.watch<AuthState>().customer?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAccess(customerId));

    if (!_access.allowed && _plans != null) {
      return Scaffold(
        appBar: AppBar(title: Text(i18n.t('investTitle'))),
        body: _Paywall(
          config: _plans!,
          access: _access,
          onUnlocked: () {
            _accessFor = null;
            _checkAccess(customerId);
          },
        ),
      );
    }

    final summary = portfolio.summary;
    final zakat = portfolio.zakat;
    final assets = portfolio.assets.where((a) => _filter == 'all' || a.metalType == _filter).toList()
      ..sort((a, b) => switch (_sort) {
            'date' => b.purchaseDate.compareTo(a.purchaseDate),
            'gain' => (portfolio.valueOf(b) - b.totalCost).compareTo(portfolio.valueOf(a) - a.totalCost),
            _ => portfolio.valueOf(b).compareTo(portfolio.valueOf(a)),
          });
    final usedMetals = portfolio.assets.map((a) => a.metalType).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('investTitle')),
        actions: [
          if (portfolio.syncing) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          IconButton(tooltip: i18n.t('converter'), icon: const Icon(Icons.swap_horiz, color: AppColors.primary), onPressed: () => context.push('/invest/converter')),
          IconButton(tooltip: i18n.t('zakat'), icon: const Icon(Icons.balance, color: Color(0xFFD97706)), onPressed: () => context.push('/invest/zakat')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.primary,
        onPressed: () => context.push('/invest/asset/new'),
        icon: const Icon(Icons.add),
        label: Text(i18n.t('addAsset')),
      ),
      body: RefreshIndicator(
        onRefresh: portfolio.refreshPrices,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const _SpotTicker(),
            if (zakat?.isAboveNisab ?? false)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: CardBox(
                  color: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFCD34D),
                  onTap: () => context.push('/invest/zakat'),
                  child: Row(children: [
                    const Text('⚖️', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(i18n.t('nisabAlert'), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                        Text(i18n.t('tapToCalculateZakat'), style: const TextStyle(color: Color(0xFF92400E), fontSize: 12)),
                      ]),
                    ),
                    Icon(forwardIcon(context), color: const Color(0xFF92400E)),
                  ]),
                ),
              ),
            _SummaryCard(summary: summary),
            _Tools(),
            if (summary.metalValues.values.any((v) => v > 0)) _Allocation(values: summary.metalValues, total: summary.totalValue),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: Text('${i18n.t('assets')} (${assets.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  for (final (key, label) in [('value', i18n.t('currentValue')), ('gain', i18n.t('gainLoss')), ('date', i18n.t('purchaseDate'))])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Pill(label: label, active: _sort == key, dense: true, onTap: () => setState(() => _sort = key)),
                    ),
                  if (usedMetals.length > 1) ...[
                    const VerticalDivider(width: 16),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Pill(label: i18n.t('all'), active: _filter == 'all', dense: true, onTap: () => setState(() => _filter = 'all')),
                    ),
                    for (final m in usedMetals)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Pill(
                          label: metalById(m)?.label(i18n.lang) ?? m,
                          active: _filter == m,
                          dense: true,
                          onTap: () => setState(() => _filter = m),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (assets.isEmpty)
              MessageState(icon: Icons.diamond_outlined, emoji: '💎', title: i18n.t('noAssets'), subtitle: i18n.t('noAssetsSubtitle'))
            else
              for (final a in assets) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: AssetTile(asset: a)),
            if (!context.watch<AuthState>().isSignedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(i18n.t('portfolioLocalNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12))),
                  TextButton(onPressed: () => context.push('/auth'), child: Text(i18n.t('signIn'))),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpotTicker extends StatelessWidget {
  const _SpotTicker();

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final p = context.watch<PortfolioState>();
    final spot = p.spot;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16)),
      child: spot == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(i18n.t('spotPrices'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  UpdatedAt(time: spot.fetchedAt.millisecondsSinceEpoch == 0 ? null : spot.fetchedAt, stale: p.isOffline, color: Colors.white54),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  for (final m in defaultMetals)
                    if ((spot.prices[m.apiSymbol] ?? 0) > 0)
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${m.emoji} ${m.label(i18n.lang)}', style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Price(purePerGramSar(spot, m.apiSymbol), decimals: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                          Text(i18n.t('perGramPure'), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ]),
                      ),
                ]),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final up = summary.gainLoss >= 0;
    final color = up ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i18n.t('totalValue'), style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Price(summary.totalValue, decimals: 0, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i18n.t('gainLoss'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                Row(children: [
                  Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: color),
                  Price(summary.gainLoss.abs(), decimals: 0, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('(${formatPercent(summary.gainLossPercent)})', style: TextStyle(color: color, fontSize: 12.5)),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(i18n.t('totalCost'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              Price(summary.totalCost, decimals: 0, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _Tools extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final tripsActive = context.watch<TripsState>().activeCount;
    final alerts = context.watch<AlertsState>().activeCount;
    final tools = [
      (Icons.shopping_bag_outlined, i18n.t('tripsCardLabel'), tripsActive > 0 ? '$tripsActive ${i18n.t('tripStatusActive')}' : i18n.t('tripsCardHelper'), const Color(0xFFA4313F), '/invest/trips'),
      (Icons.notifications_active_outlined, i18n.t('priceAlerts'), alerts > 0 ? i18n.t('activeAlertsCount', {'n': alerts}) : i18n.t('priceAlertsSubtitle'), const Color(0xFF2563EB), '/invest/alerts'),
      (Icons.support_agent, i18n.t('consultationTitle'), i18n.t('consultationShort'), const Color(0xFF059669), '/invest/consultation'),
      (Icons.candlestick_chart_outlined, i18n.t('livePrices'), i18n.t('livePricesSubtitle'), AppColors.primary, '/pricing'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 66,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final (icon, title, subtitle, color, route) in tools)
            CardBox(
              padding: const EdgeInsets.all(10),
              onTap: () => context.push(route),
              child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 19)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ]),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Allocation extends StatelessWidget {
  const _Allocation({required this.values, required this.total});
  final Map<String, double> values;
  final double total;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final entries = values.entries.where((e) => e.value > 0).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i18n.t('allocation'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
              width: 130,
              height: 130,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: [
                  for (final e in entries)
                    PieChartSectionData(
                      value: e.value,
                      color: metalById(e.key)?.color ?? AppColors.muted,
                      radius: 28,
                      showTitle: false,
                    ),
                ],
              )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: metalById(e.key)?.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(metalById(e.key)?.label(i18n.lang) ?? e.key)),
                      Text('${(total > 0 ? e.value / total * 100 : 0).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

class AssetTile extends StatelessWidget {
  const AssetTile({super.key, required this.asset});
  final PortfolioAsset asset;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final p = context.watch<PortfolioState>();
    final metal = metalById(asset.metalType);
    final value = p.valueOf(asset);
    final gain = value - asset.totalCost;
    final pct = asset.totalCost > 0 ? gain / asset.totalCost * 100 : 0.0;
    final color = gain >= 0 ? AppColors.success : AppColors.error;
    return CardBox(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/invest/asset/${asset.id}'),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: metal?.bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: metal?.borderColor ?? AppColors.border)),
          child: Text(categoryEmoji[asset.category] ?? '💍', style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(asset.displayName(i18n.lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${asset.purityLabel} ${metal?.label(i18n.lang) ?? ''} · ${formatNumber(asset.weightGrams)} ${i18n.t('gramsShort')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Price(value, decimals: 0, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(formatPercent(pct), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _Paywall extends StatefulWidget {
  const _Paywall({required this.config, required this.access, required this.onUnlocked});
  final SubscriptionConfig config;
  final PortfolioAccess access;
  final VoidCallback onUnlocked;

  @override
  State<_Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<_Paywall> {
  String? _busy;

  Future<void> _subscribe(OfferedPlan plan) async {
    final i18n = context.i18nRead;
    setState(() => _busy = plan.plan);
    try {
      final res = await InvestService.subscribe(plan.plan);
      if (!mounted) return;
      if (!res.payment.simulated && res.payment.checkoutUrl.isNotEmpty) {
        await PaymentWebViewScreen.open(context, res.payment.checkoutUrl);
      }
      final id = res.subscription?.id;
      if (id != null) {
        for (var i = 0; i < 20; i++) {
          final state = await InvestService.confirmSubscription(id);
          if (state == 'paid') break;
          if (state == 'failed' || state == 'cancelled') {
            if (mounted) showSnack(context, i18n.t('paymentFailedTitle'), error: true);
            return;
          }
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
      widget.onUnlocked();
    } catch (_) {
      if (mounted) showSnack(context, i18n.t('genericError'), error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.lock_outline, size: 56, color: AppColors.darkGreen),
        const SizedBox(height: 12),
        Text(i18n.t('paywallTitle'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          widget.access.lastExpired != null ? i18n.t('paywallExpired') : i18n.t('paywallBody'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 20),
        for (final plan in widget.config.plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CardBox(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i18n.t('plan_${plan.plan}'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (plan.monthlyEquivalent != null)
                      Text(i18n.t('perMonthEquivalent', {'amount': formatSar(plan.monthlyEquivalent!, i18n.lang)}),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
                Price(plan.priceCents / 100, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: GoldButton(label: i18n.t('subscribe'), loading: _busy == plan.plan, onPressed: _busy == null ? () => _subscribe(plan) : null),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
