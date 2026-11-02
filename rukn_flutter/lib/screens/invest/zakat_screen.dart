import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../models/portfolio.dart';
import '../../state/portfolio_state.dart';
import '../../widgets/common.dart';

class ZakatScreen extends StatelessWidget {
  const ZakatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final p = context.watch<PortfolioState>();
    final spot = p.spot;
    final zakat = p.zakat;

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('zakat'))),
      body: spot == null || zakat == null
          ? LoadingView(label: i18n.t('loadingPriceData'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: zakat.isAboveNisab ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: zakat.isAboveNisab ? const Color(0xFFFCD34D) : const Color(0xFF86EFAC)),
                  ),
                  child: Column(children: [
                    Text(zakat.isAboveNisab ? '⚖️' : '✅', style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      zakat.isAboveNisab ? i18n.t('nisabAlert') : i18n.t('belowNisab'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: zakat.isAboveNisab ? const Color(0xFF92400E) : const Color(0xFF166534)),
                    ),
                    if (zakat.isAboveNisab) ...[
                      const SizedBox(height: 6),
                      Text(i18n.t('zakatObligatory'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF92400E))),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SectionLabel(i18n.t('nisabCalculation')),
                    InfoRow(label: i18n.t('goldPerGram24K'), valueWidget: Price(purePerGramSar(spot, 'XAU'), decimals: 2)),
                    InfoRow(label: i18n.t('nisabEquals85g')),
                    const Divider(),
                    InfoRow(label: i18n.t('nisabThreshold'), highlight: true, valueWidget: Price(zakat.nisabThresholdSar, decimals: 0)),
                    InfoRow(label: i18n.t('zakatableValue'), highlight: true, valueWidget: Price(zakat.totalZakatableValue, decimals: 0)),
                    if (zakat.isAboveNisab) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Text(i18n.t('zakatDue'), style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Price(zakat.zakatDue, decimals: 0, style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('× 2.5%', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SectionLabel(i18n.t('assetBreakdown')),
                    if (p.assets.isEmpty)
                      Text(i18n.t('noAssetsInPortfolio'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted))
                    else
                      for (final a in p.assets) InfoRow(label: a.displayName(i18n.lang), valueWidget: Price(p.valueOf(a), decimals: 0)),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(i18n.t('disclaimer'), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5))),
                ]),
              ],
            ),
    );
  }
}
