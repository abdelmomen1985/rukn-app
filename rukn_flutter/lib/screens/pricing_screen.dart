import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../state/gold_ticker.dart';
import '../widgets/common.dart';
import '../widgets/ticker_widgets.dart';

/// Instant pricing: live per-gram karat rates, silver, and the ounce.
///
/// The site's candlestick chart is generated client-side (synthetic history);
/// it is left out here on purpose — a store reviewer reads a chart as real
/// market data, and none is published by the backend.
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final ticker = context.watch<GoldTicker>();
    final data = ticker.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('livePrices')),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), tooltip: i18n.t('priceAlerts'), onPressed: () => context.push('/invest/alerts')),
        ],
      ),
      body: data == null
          ? (ticker.failed ? ErrorView(onRetry: ticker.refresh) : const LoadingView())
          : RefreshIndicator(
              onRefresh: ticker.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.darkGreen, AppColors.deepGreen]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (data.marketOpen != null)
                            StatusChip(
                              label: data.marketOpen! ? i18n.t('marketOpen') : i18n.t('marketClosed'),
                              color: data.marketOpen! ? const Color(0xFF34D399) : AppColors.warning,
                              icon: Icons.circle,
                            ),
                          const Spacer(),
                          UpdatedAt(time: data.asOf ?? ticker.updatedAt, color: Colors.white60),
                        ]),
                        const SizedBox(height: 14),
                        if (data.ounceGold != null)
                          _OunceRow(label: i18n.t('goldOunce'), value: data.ounceGold!, direction: ticker.direction('ounce:gold')),
                        if (data.ounceSilver != null)
                          _OunceRow(label: i18n.t('silverOunce'), value: data.ounceSilver!, direction: ticker.direction('ounce:silver')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(i18n.t('goldPerGram')),
                  CardBox(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(children: [
                      for (final k in ['24', '22', '21', '18', '14'])
                        if (data.tickerKarat(k) != null)
                          _KaratRow(
                            label: i18n.t('karatLong', {'k': k}),
                            value: data.tickerKarat(k)!,
                            direction: ticker.direction('karat:$k'),
                          ),
                    ]),
                  ),
                  if (data.silverBlock.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionLabel(i18n.t('silverPerGram')),
                    CardBox(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(children: [
                        for (final p in ['999', '925', '900', '800'])
                          if (data.tickerSilver(p) != null)
                            _KaratRow(label: i18n.t('silverPurityLabel', {'p': p}), value: data.tickerSilver(p)!, direction: ticker.direction('silver:$p')),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.tickerIncludesTax ? i18n.t('tickerIncludesTaxNote') : i18n.t('tickerRawNote'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/invest/converter'),
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(i18n.t('goldValueCalculator')),
                  ),
                ],
              ),
            ),
    );
  }
}

class _OunceRow extends StatelessWidget {
  const _OunceRow({required this.label, required this.value, required this.direction});
  final String label;
  final double value;
  final TickDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = directionColor(direction);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
          child: Price(value, decimals: 2),
        ),
        Icon(directionIcon(direction) ?? Icons.remove, color: color, size: 22),
      ]),
    );
  }
}

class _KaratRow extends StatelessWidget {
  const _KaratRow({required this.label, required this.value, required this.direction});
  final String label;
  final double value;
  final TickDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = directionColor(direction, neutral: AppColors.foreground);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800),
          child: Price(value, decimals: 2),
        ),
        SizedBox(width: 22, child: Icon(directionIcon(direction), color: color, size: 22)),
      ]),
    );
  }
}
