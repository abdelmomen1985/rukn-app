import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../state/gold_ticker.dart';
import 'common.dart';

Color directionColor(TickDirection d, {Color neutral = Colors.white}) => switch (d) {
      TickDirection.up => const Color(0xFF34D399),
      TickDirection.down => const Color(0xFFF87171),
      TickDirection.neutral => neutral,
    };

IconData? directionIcon(TickDirection d) => switch (d) {
      TickDirection.up => Icons.arrow_drop_up,
      TickDirection.down => Icons.arrow_drop_down,
      TickDirection.neutral => null,
    };

/// Horizontal live karat strip under the home header. Tapping opens the pricing screen.
class LiveTickerStrip extends StatelessWidget {
  const LiveTickerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final ticker = context.watch<GoldTicker>();
    final i18n = context.i18n;
    final data = ticker.data;
    if (data == null) return const SizedBox.shrink();
    final karats = ['24', '22', '21', '18'].where((k) => data.tickerKarat(k) != null).toList();

    return Material(
      color: AppColors.deepGreen,
      child: InkWell(
        onTap: () => context.push('/pricing'),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 12),
              _MarketDot(open: data.marketOpen),
              const SizedBox(width: 8),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: karats.length + (data.ounceGold != null ? 1 : 0),
                  separatorBuilder: (_, _) => const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12, width: 20),
                  itemBuilder: (context, i) {
                    if (i == karats.length) {
                      final d = ticker.direction('ounce:gold');
                      return _TickerItem(label: i18n.t('ounceGold'), value: data.ounceGold!, direction: d);
                    }
                    final k = karats[i];
                    return _TickerItem(
                      label: i18n.t('karatShort', {'k': k}),
                      value: data.tickerKarat(k)!,
                      direction: ticker.direction('karat:$k'),
                    );
                  },
                ),
              ),
              Icon(forwardIcon(context), color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickerItem extends StatelessWidget {
  const _TickerItem({required this.label, required this.value, required this.direction});
  final String label;
  final double value;
  final TickDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = directionColor(direction);
    final icon = directionIcon(direction);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          child: Price(value, decimals: 2),
        ),
        if (icon != null) Icon(icon, color: color, size: 18),
      ],
    );
  }
}

class _MarketDot extends StatelessWidget {
  const _MarketDot({required this.open});
  final bool? open;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    if (open == null) return const Icon(Icons.show_chart, color: AppColors.primary, size: 18);
    final color = open! ? const Color(0xFF34D399) : const Color(0xFFF59E0B);
    return Tooltip(
      message: open! ? i18n.t('marketOpen') : i18n.t('marketClosed'),
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

/// "Updated 12:01:33" line used on the pricing and invest screens.
class UpdatedAt extends StatelessWidget {
  const UpdatedAt({super.key, required this.time, this.stale = false, this.color = AppColors.muted});
  final DateTime? time;
  final bool stale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    if (time == null) return const SizedBox.shrink();
    return Text(
      '${stale ? '${i18n.t('offline')} · ' : ''}${i18n.t('lastUpdated')}: ${formatTime(time!, i18n.lang)}',
      style: TextStyle(color: color, fontSize: 11.5),
    );
  }
}
