import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../models/portfolio.dart';
import '../../state/portfolio_state.dart';
import '../../widgets/common.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _w = TextEditingController();
  String _from = 'tolas';
  String _to = 'grams';
  final _g = TextEditingController();
  String _gUnit = 'grams';
  int _karat = 21;
  final _s = TextEditingController();
  String _sUnit = 'grams';
  int _silver = 925;

  @override
  void dispose() {
    _w.dispose();
    _g.dispose();
    _s.dispose();
    super.dispose();
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SectionLabel(title), ...children])),
      );

  Widget _caption(String t) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text(t, style: const TextStyle(color: AppColors.muted, fontSize: 12)));

  Widget _result(String top, Widget value, {Color bg = AppColors.darkGreen, Color fg = Colors.white70, Color valueColor = AppColors.primary}) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(top, style: TextStyle(color: fg, fontSize: 12)),
          const SizedBox(height: 4),
          DefaultTextStyle.merge(style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.w800), child: value),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final spot = context.watch<PortfolioState>().spot;
    final w = parseNumber(_w.text);
    final g = parseNumber(_g.text);
    final s = parseNumber(_s.text);
    final numberKeyboard = const TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('converter'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(i18n.t('weightConverter'), [
            TextField(controller: _w, keyboardType: numberKeyboard, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: i18n.t('amountPlaceholder'))),
            _caption(i18n.t('convertFrom')),
            PillSelector<String>(options: weightUnits, selected: _from, label: (u) => i18n.t(u), onSelect: (u) => setState(() => _from = u)),
            _caption(i18n.t('convertTo')),
            PillSelector<String>(options: weightUnits, selected: _to, label: (u) => i18n.t(u), onSelect: (u) => setState(() => _to = u)),
            if (w != null)
              _result('${_w.text} ${i18n.t(_from)} =', Text('${formatNumber(convertWeight(w, _from, _to), maxDecimals: 4)} ${i18n.t(_to)}')),
          ]),
          _section(i18n.t('goldValueCalculator'), [
            if (spot == null) Text(i18n.t('loadingPrices'), style: const TextStyle(color: AppColors.muted)),
            TextField(controller: _g, keyboardType: numberKeyboard, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: i18n.t('weightInputPlaceholder'))),
            _caption(i18n.t('unit')),
            PillSelector<String>(options: weightUnits, selected: _gUnit, label: (u) => i18n.t(u), onSelect: (u) => setState(() => _gUnit = u)),
            _caption(i18n.t('karat')),
            PillSelector<int>(options: goldKarats, selected: _karat, label: (k) => '${k}K', onSelect: (k) => setState(() => _karat = k)),
            if (g != null && spot != null)
              _result(
                '${_g.text} ${i18n.t(_gUnit)} ${_karat}K ${i18n.t('ofGold')} =',
                Price(weightInGrams(g, _gUnit) * purePerGramSar(spot, 'XAU') * _karat / 24, decimals: 0),
                bg: AppColors.goldBg,
                fg: const Color(0xFF92710B),
                valueColor: AppColors.goldText,
              ),
          ]),
          _section(i18n.t('silverValueCalculator'), [
            if (spot == null) Text(i18n.t('loadingPrices'), style: const TextStyle(color: AppColors.muted)),
            TextField(controller: _s, keyboardType: numberKeyboard, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: i18n.t('weightInputPlaceholder'))),
            _caption(i18n.t('unit')),
            PillSelector<String>(options: weightUnits, selected: _sUnit, label: (u) => i18n.t(u), onSelect: (u) => setState(() => _sUnit = u)),
            _caption(i18n.t('purity')),
            PillSelector<int>(options: silverPurities, selected: _silver, label: (p) => '$p', onSelect: (p) => setState(() => _silver = p)),
            if (s != null && spot != null)
              _result(
                '${_s.text} ${i18n.t(_sUnit)} ${i18n.t('ofSilver')} $_silver =',
                Price(weightInGrams(s, _sUnit) * purePerGramSar(spot, 'XAG') * _silver / 1000, decimals: 2),
                bg: const Color(0xFFF5F5F5),
                fg: const Color(0xFF666666),
                valueColor: const Color(0xFF333333),
              ),
          ]),
        ],
      ),
    );
  }
}
