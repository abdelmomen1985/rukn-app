import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../models/portfolio.dart';
import '../../state/portfolio_state.dart';
import '../../widgets/common.dart';

class AssetFormScreen extends StatefulWidget {
  const AssetFormScreen({super.key, this.assetId});
  final String? assetId;

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  PortfolioAsset? _editing;
  String _metal = 'gold';
  String _category = 'ring';
  String _unit = 'grams';
  String _purity = '21K';
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _price = TextEditingController();
  final _making = TextEditingController(text: '0');
  final _vat = TextEditingController(text: '0');
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.assetId == null ? null : context.read<PortfolioState>().byId(widget.assetId!);
    if (a != null) {
      _editing = a;
      _metal = metalById(a.metalType) == null ? 'gold' : a.metalType;
      _category = a.category;
      _unit = a.weightUnit;
      _purity = a.purityLabel;
      _name.text = a.name;
      _weight.text = formatNumber(a.weightValue, maxDecimals: 4).replaceAll(',', '');
      _price.text = a.purchasePrice.toString();
      _making.text = a.makingCharges.toString();
      _vat.text = a.vatAmount.toString();
      _notes.text = a.notes ?? '';
      _date = DateTime.tryParse(a.purchaseDate) ?? DateTime.now();
    }
    _normalizePurity();
  }

  @override
  void dispose() {
    for (final c in [_name, _weight, _price, _making, _vat, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isGoldBar => _metal == 'gold' && _category == 'bar';

  List<MetalPurity> get _purities {
    final all = metalById(_metal)!.purities;
    return _isGoldBar ? all.where((p) => p.label == '24K').toList() : all;
  }

  void _normalizePurity() {
    if (_isGoldBar) {
      _purity = '24K';
    } else if (!_purities.any((p) => p.label == _purity)) {
      _purity = _metal == 'gold' ? '21K' : _purities.first.label;
    }
  }

  Future<void> _save() async {
    final i18n = context.i18nRead;
    final weight = parseNumber(_weight.text);
    final price = parseNumber(_price.text);
    String? error;
    if (_name.text.trim().isEmpty) {
      error = i18n.t('assetNameRequired');
    } else if (weight == null || weight <= 0) {
      error = i18n.t('weightInvalid');
    } else if (price == null || price < 0) {
      error = i18n.t('purchasePriceInvalid');
    }
    if (error != null) return showSnack(context, error, error: true);

    final purity = _purities.firstWhere((p) => p.label == _purity, orElse: () => _purities.first);
    haptic(Haptic.medium);
    setState(() => _saving = true);
    final now = DateTime.now().toIso8601String();
    final asset = PortfolioAsset(
      id: _editing?.id ?? '',
      metalType: _metal,
      name: _name.text.trim(),
      nameAr: _editing?.nameAr,
      category: _category,
      weightValue: weight!,
      weightUnit: _unit,
      purityLabel: purity.label,
      purityFactor: purity.factor,
      purchasePrice: price!,
      purchaseDate: _date.toIso8601String().substring(0, 10),
      makingCharges: parseNumber(_making.text) ?? 0,
      vatAmount: parseNumber(_vat.text) ?? 0,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: _editing?.createdAt ?? now,
      updatedAt: now,
      karat: _metal == 'gold' ? int.tryParse(purity.label.replaceAll('K', '')) : null,
      silverPurity: _metal == 'silver' ? int.tryParse(purity.label) : null,
    );
    final state = context.read<PortfolioState>();
    final future = _editing == null ? state.addAsset(asset) : state.updateAsset(asset);
    // The local copy is saved synchronously; the server sync finishes in the background.
    future.ignore();
    if (mounted) context.pop();
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(t.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(title: Text(_editing == null ? i18n.t('addAsset') : i18n.t('editAsset'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          _label(i18n.t('metalType')),
          Row(children: [
            for (final m in defaultMetals)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _metal = m.id;
                      _normalizePurity();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _metal == m.id ? m.bgColor : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _metal == m.id ? m.color : AppColors.border, width: 2),
                      ),
                      child: Column(children: [
                        Text(m.emoji, style: const TextStyle(fontSize: 20)),
                        Text(m.label(i18n.lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _metal == m.id ? m.textColor : AppColors.foreground)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
          _label(i18n.t('assetName')),
          TextField(controller: _name, decoration: InputDecoration(hintText: i18n.t('assetNamePlaceholder'))),
          _label(i18n.t('category')),
          PillSelector<String>(
            options: assetCategories,
            selected: _category,
            label: (c) => i18n.t(c),
            leading: (c) => categoryEmoji[c] ?? '',
            onSelect: (c) => setState(() {
              _category = c;
              _normalizePurity();
            }),
          ),
          _label(i18n.t('weight')),
          TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: i18n.t('weightPlaceholder'))),
          const SizedBox(height: 8),
          PillSelector<String>(options: weightUnits, selected: _unit, label: (u) => i18n.t(u), onSelect: (u) => setState(() => _unit = u)),
          _label(_metal == 'gold' ? i18n.t('karat') : i18n.t('purity')),
          PillSelector<String>(options: [for (final p in _purities) p.label], selected: _purity, label: (p) => p, onSelect: (p) => setState(() => _purity = p)),
          if (_isGoldBar)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(i18n.t('goldBarPurityNote'), style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          _label(i18n.t('purchasePrice')),
          TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: '0', suffixText: i18n.t('sarShort'))),
          _label(i18n.t('purchaseDate')),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1970), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
              child: Text(formatDate(_date.toIso8601String(), i18n.lang)),
            ),
          ),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(i18n.t('makingCharges')),
                TextField(controller: _making, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(i18n.t('vatAmount')),
                TextField(controller: _vat, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ]),
            ),
          ]),
          _label(i18n.t('notes')),
          TextField(controller: _notes, maxLines: 3, decoration: InputDecoration(hintText: i18n.t('notesPlaceholder'))),
          const SizedBox(height: 24),
          GoldButton(label: i18n.t('saveAsset'), loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key, required this.assetId});
  final String assetId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final state = context.watch<PortfolioState>();
    final asset = state.byId(assetId);
    if (asset == null) {
      return Scaffold(appBar: AppBar(), body: MessageState(icon: Icons.search_off, title: i18n.t('assetNotFound')));
    }
    final metal = metalById(asset.metalType);
    final pnl = state.spot == null ? null : calculatePnL(asset, state.spot!);
    final purityText = '${asset.purityLabel} ${metal?.label(i18n.lang) ?? ''}';

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.displayName(i18n.lang)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/invest/asset/new?assetId=${asset.id}')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: metal?.bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: metal?.borderColor ?? AppColors.border)),
            child: Column(children: [
              Text(categoryEmoji[asset.category] ?? '💍', style: const TextStyle(fontSize: 46)),
              const SizedBox(height: 6),
              Text(asset.displayName(i18n.lang), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: metal?.textColor)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                StatusChip(label: purityText, color: metal?.textColor ?? AppColors.goldText),
                StatusChip(label: '${formatNumber(asset.weightGrams)} ${i18n.t('gramsShort')}', color: AppColors.muted),
                StatusChip(label: i18n.t(asset.category), color: AppColors.muted),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel(i18n.t('details')),
              InfoRow(label: i18n.t('weight'), value: '${formatNumber(asset.weightValue, maxDecimals: 4)} ${i18n.t(asset.weightUnit)} (${formatNumber(asset.weightGrams)} ${i18n.t('gramsShort')})'),
              InfoRow(label: i18n.t('purity'), value: purityText),
              InfoRow(label: i18n.t('purchaseDate'), value: formatDate(asset.purchaseDate, i18n.lang)),
              if (asset.notes != null) ...[
                const SizedBox(height: 6),
                Text(i18n.t('notes'), style: const TextStyle(color: AppColors.muted)),
                Text(asset.notes!),
              ],
            ]),
          ),
          const SizedBox(height: 14),
          if (pnl == null)
            CardBox(child: Text(i18n.t('loadingPriceData'), style: const TextStyle(color: AppColors.muted)))
          else
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(i18n.t('performance')),
                InfoRow(label: i18n.t('purchaseCost'), valueWidget: Price(asset.purchasePrice)),
                if (asset.makingCharges > 0) InfoRow(label: i18n.t('makingCharges'), valueWidget: Price(asset.makingCharges)),
                if (asset.vatAmount > 0) InfoRow(label: i18n.t('vatAmount'), valueWidget: Price(asset.vatAmount)),
                InfoRow(label: i18n.t('totalCost'), highlight: true, valueWidget: Price(pnl.totalCost)),
                const Divider(),
                InfoRow(label: i18n.t('currentValue'), highlight: true, valueWidget: Price(pnl.currentValue, decimals: 0)),
                InfoRow(
                  label: i18n.t('gainLoss'),
                  valueColor: pnl.gainLoss >= 0 ? AppColors.success : AppColors.error,
                  valueWidget: Price(pnl.gainLoss, decimals: 0),
                ),
                InfoRow(label: i18n.t('returnPercent'), value: formatPercent(pnl.percentReturn), valueColor: pnl.percentReturn >= 0 ? AppColors.success : AppColors.error),
                InfoRow(label: i18n.t('annualizedReturn'), value: formatPercent(pnl.annualizedReturn), valueColor: pnl.annualizedReturn >= 0 ? AppColors.success : AppColors.error),
                InfoRow(label: i18n.t('holdingDays'), value: '${pnl.holdingDays}'),
              ]),
            ),
          const SizedBox(height: 18),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: i18n.t('deleteAsset'), message: '${i18n.t('deleteConfirm')} "${asset.displayName(i18n.lang)}"?', confirmLabel: i18n.t('deleteAsset'), destructive: true);
              if (!ok || !context.mounted) return;
              context.read<PortfolioState>().deleteAsset(asset.id).ignore();
              context.pop();
            },
            child: Text(i18n.t('deleteAsset')),
          ),
        ],
      ),
    );
  }
}
