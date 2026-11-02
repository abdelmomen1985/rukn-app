import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../models/price_alert.dart';
import '../../state/alerts_state.dart';
import '../../state/gold_ticker.dart';
import '../../widgets/common.dart';

/// Per-gram price alerts, checked on every live tick while the app is open.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final state = context.watch<AlertsState>();
    final data = context.watch<GoldTicker>().data;

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('priceAlerts'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.primary,
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _AlertForm()),
        icon: const Icon(Icons.add_alert_outlined),
        label: Text(i18n.t('newAlert')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(child: Text(i18n.t('alertsInAppNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5))),
          ]),
          const SizedBox(height: 12),
          if (state.alerts.isEmpty)
            MessageState(icon: Icons.notifications_none, title: i18n.t('noAlerts'), subtitle: i18n.t('noAlertsSubtitle'))
          else
            for (final a in state.alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlertCard(alert: a, price: alertPerGramSar(data, a.metal, a.purityFactor, a.purityLabel)),
              ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.price});
  final PriceAlert alert;
  final double? price;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final state = context.read<AlertsState>();
    final above = alert.direction == 'above';
    final distance = price == null ? null : distanceToTargetPercent(alert, price!);
    return CardBox(
      color: alert.active ? AppColors.surface : Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(above ? Icons.trending_up : Icons.trending_down, color: above ? AppColors.success : AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${i18n.t(alert.metal)} ${alert.purityLabel} · ${above ? i18n.t('alertAbove') : i18n.t('alertBelow')}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Switch(
            value: alert.active,
            activeThumbColor: AppColors.darkGreen,
            onChanged: (v) => state.setActive(alert.id, v, currentPrice: price),
          ),
        ]),
        Row(children: [
          Text(i18n.t('target'), style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 6),
          Price(alert.targetPerGramSar, decimals: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          Text(' / ${i18n.t('gramsShort')}', style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, color: AppColors.muted),
            onPressed: () => state.remove(alert.id),
          ),
        ]),
        if (price != null)
          Text(
            '${i18n.t('nowPrice', {'price': formatSar(price!, i18n.lang)})} · ${distance! >= 0 ? '+' : ''}${distance.toStringAsFixed(2)}%',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        if (alert.lastTriggeredAt != null)
          Text(i18n.t('lastTriggered', {'date': formatDate(alert.lastTriggeredAt, i18n.lang, withTime: true)}),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        if (alert.repeat) Text(i18n.t('alertRepeats'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ]),
    );
  }
}

class _AlertForm extends StatefulWidget {
  const _AlertForm();

  @override
  State<_AlertForm> createState() => _AlertFormState();
}

class _AlertFormState extends State<_AlertForm> {
  String _metal = 'gold';
  String _purity = '21K';
  String _direction = 'above';
  bool _repeat = false;
  final _target = TextEditingController();

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final data = context.watch<GoldTicker>().data;
    final purities = alertPurities(_metal);
    final purity = purities.firstWhere((p) => p.label == _purity, orElse: () => purities.first);
    final current = alertPerGramSar(data, _metal, purity.factor, purity.label);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n.t('newAlert'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'gold', label: Text(i18n.t('gold'))),
              ButtonSegment(value: 'silver', label: Text(i18n.t('silver'))),
            ],
            selected: {_metal},
            onSelectionChanged: (v) => setState(() {
              _metal = v.first;
              _purity = _metal == 'gold' ? '21K' : '999';
            }),
          ),
          const SizedBox(height: 12),
          PillSelector<String>(options: [for (final p in purities) p.label], selected: purity.label, label: (p) => p, onSelect: (p) => setState(() => _purity = p)),
          const SizedBox(height: 12),
          if (current != null)
            Row(children: [
              Text(i18n.t('currentPricePerGram'), style: const TextStyle(color: AppColors.muted)),
              const Spacer(),
              Price(current, decimals: 2, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'above', label: Text(i18n.t('alertAbove')), icon: const Icon(Icons.trending_up)),
              ButtonSegment(value: 'below', label: Text(i18n.t('alertBelow')), icon: const Icon(Icons.trending_down)),
            ],
            selected: {_direction},
            onSelectionChanged: (v) => setState(() => _direction = v.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: i18n.t('targetPerGram'), suffixText: i18n.t('sarShort')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.darkGreen,
            value: _repeat,
            onChanged: (v) => setState(() => _repeat = v),
            title: Text(i18n.t('alertRepeat')),
            subtitle: Text(i18n.t('alertRepeatHint'), style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 8),
          GoldButton(
            label: i18n.t('createAlert'),
            onPressed: () {
              final target = parseNumber(_target.text);
              if (target == null || target <= 0) return showSnack(context, i18n.t('targetInvalid'), error: true);
              context.read<AlertsState>().add(createAlert(
                    metal: _metal,
                    purityLabel: purity.label,
                    purityFactor: purity.factor,
                    direction: _direction,
                    target: target,
                    repeat: _repeat,
                    currentPrice: current,
                  ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
