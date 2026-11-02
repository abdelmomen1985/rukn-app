import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../models/portfolio.dart';
import '../../models/trips.dart';
import '../../state/gold_ticker.dart';
import '../../state/portfolio_state.dart';
import '../../state/trips_state.dart';
import '../../widgets/common.dart';

Color verdictColor(String v) => switch (v) {
      'excellent' => AppColors.success,
      'fair' => AppColors.info,
      _ => AppColors.error,
    };

String verdictLabel(I18n i18n, String v) => switch (v) {
      'excellent' => i18n.t('fairPriceLabelExcellent'),
      'fair' => i18n.t('fairPriceLabelFair'),
      _ => i18n.t('fairPriceLabelHigh'),
    };

/// Pure (24K) gold per gram in SAR: the live metal rate, else the spot feed.
double purePerGram(BuildContext context) {
  final raw = context.watch<GoldTicker>().data?.karatBlock['24']?.raw;
  if (raw != null && raw > 0) return raw;
  final spot = context.watch<PortfolioState>().spot;
  return spot == null ? 0 : purePerGramSar(spot, 'XAU');
}

class TripsListScreen extends StatelessWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final state = context.watch<TripsState>();
    final trips = state.trips;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('tripsTitle'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.primary,
        onPressed: () => context.push('/invest/trips/new'),
        icon: const Icon(Icons.add),
        label: Text(i18n.t('newTrip')),
      ),
      body: trips.isEmpty
          ? MessageState(icon: Icons.shopping_bag_outlined, emoji: '🛍️', title: i18n.t('tripsEmptyTitle'), subtitle: i18n.t('tripsEmptySubtitle'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: trips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = trips[i];
                final best = t.cheapestStop;
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (_) => confirmDialog(context,
                      title: i18n.t('deleteTrip'), message: '${i18n.t('deleteTripConfirm')}\n\n"${t.name}"', confirmLabel: i18n.t('deleteTrip'), destructive: true),
                  onDismissed: (_) => state.deleteTrip(t.id),
                  child: CardBox(
                    onTap: () => context.push('/invest/trips/${t.id}'),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Expanded(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                        StatusChip(
                          label: t.status == 'active' ? i18n.t('tripStatusActive') : i18n.t('tripStatusCompleted'),
                          color: t.status == 'active' ? AppColors.darkGreen : AppColors.muted,
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('${cityLabel(t.city, i18n.lang)} · ${t.purityLabel} · ${t.stops.length} ${i18n.t('tripStops')}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      const SizedBox(height: 10),
                      if (best == null)
                        Text(i18n.t('noStopsYet'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            const Icon(Icons.auto_awesome, size: 15, color: AppColors.darkGreen),
                            const SizedBox(width: 6),
                            Expanded(child: Text(i18n.t('tripBestPrice'), style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600, fontSize: 12.5))),
                            Price(best.totalPriceSar, decimals: 0, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                        ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

class NewTripScreen extends StatefulWidget {
  const NewTripScreen({super.key});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final _name = TextEditingController();
  final _search = TextEditingController();
  final _weight = TextEditingController();
  String _city = 'riyadh';
  String _goal = 'compare';
  String _category = 'ring';
  String _purity = '21K';

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _start() {
    final i18n = context.i18nRead;
    if (_name.text.trim().isEmpty) return showSnack(context, i18n.t('tripNamePlaceholder'), error: true);
    final options = tripPuritiesFor(_category);
    final purity = options.firstWhere((p) => p.label == _purity, orElse: () => options.first);
    haptic(Haptic.medium);
    final trip = context.read<TripsState>().addTrip(
          name: _name.text.trim(),
          city: _city,
          goal: _goal,
          category: _category,
          purityLabel: purity.label,
          purityFactor: purity.factor,
          weightGrams: parseNumber(_weight.text),
        );
    context.pushReplacement('/invest/trips/${trip.id}');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final q = _search.text.trim().toLowerCase();
    final cities = popularCities.where((c) => q.isEmpty || c.nameAr.contains(q) || c.nameEn.toLowerCase().contains(q)).toList();
    final purities = tripPuritiesFor(_category);

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('newTrip'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(i18n.t('tripName')),
          TextField(controller: _name, decoration: InputDecoration(hintText: i18n.t('tripNamePlaceholder'))),
          const SizedBox(height: 20),
          SectionLabel(i18n.t('tripCity')),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: i18n.t('citySearchPlaceholder'), prefixIcon: const Icon(Icons.search)),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cities)
              Pill(label: i18n.isAr ? c.nameAr : c.nameEn, active: _city == c.id, onTap: () => setState(() => _city = c.id)),
          ]),
          const SizedBox(height: 20),
          SectionLabel(i18n.t('tripGoal')),
          Row(children: [
            for (final (id, label, icon) in [('compare', i18n.t('goalCompare'), Icons.search), ('buy-today', i18n.t('goalBuyToday'), Icons.auto_awesome)])
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _goal = id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _goal == id ? AppColors.darkGreen : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _goal == id ? AppColors.darkGreen : AppColors.border),
                      ),
                      child: Column(children: [
                        Icon(icon, color: _goal == id ? AppColors.primary : AppColors.foreground),
                        const SizedBox(height: 6),
                        Text(label, style: TextStyle(color: _goal == id ? AppColors.primary : AppColors.foreground, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 20),
          SectionLabel(i18n.t('tripCategory')),
          PillSelector<String>(
            options: tripCategories,
            selected: _category,
            label: (c) => i18n.t(c),
            leading: (c) => categoryEmoji[c] ?? '',
            onSelect: (c) => setState(() {
              _category = c;
              if (c == 'bar') _purity = '24K';
            }),
          ),
          const SizedBox(height: 20),
          SectionLabel(i18n.t('tripPurity')),
          PillSelector<String>(options: [for (final p in purities) p.label], selected: _purity, label: (p) => p, onSelect: (p) => setState(() => _purity = p)),
          const SizedBox(height: 20),
          SectionLabel(i18n.t('tripExpectedWeight')),
          TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: '0', suffixText: i18n.t('gramsShort'))),
          const SizedBox(height: 28),
          GoldButton(label: i18n.t('startTrip'), onPressed: _start),
        ],
      ),
    );
  }
}

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final state = context.watch<TripsState>();
    final trip = state.byId(tripId);
    if (trip == null) {
      return Scaffold(appBar: AppBar(), body: MessageState(icon: Icons.search_off, title: i18n.t('tripsEmptyTitle')));
    }
    final best = trip.cheapestStop;
    final avg = trip.averageTotal;
    final savings = best != null && avg > 0 ? avg - best.totalPriceSar : 0.0;
    final stops = [...trip.stops]..sort((a, b) => a.totalPriceSar.compareTo(b.totalPriceSar));

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'status') {
                state.setStatus(trip.id, trip.status == 'active' ? 'completed' : 'active');
              } else if (v == 'delete') {
                final ok = await confirmDialog(context,
                    title: i18n.t('deleteTrip'), message: i18n.t('deleteTripConfirm'), confirmLabel: i18n.t('deleteTrip'), destructive: true);
                if (ok && context.mounted) {
                  state.deleteTrip(trip.id);
                  context.pop();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'status', child: Text(trip.status == 'active' ? i18n.t('markTripCompleted') : i18n.t('reopenTrip'))),
              PopupMenuItem(value: 'delete', child: Text(i18n.t('deleteTrip'), style: const TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
      floatingActionButton: trip.status == 'active'
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: AppColors.primary,
              onPressed: () => context.push('/invest/trips/${trip.id}/stop'),
              icon: const Icon(Icons.add_business_outlined),
              label: Text(i18n.t('addStop')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('${cityLabel(trip.city, i18n.lang)} · ${i18n.t(trip.category)} · ${trip.purityLabel}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          Row(children: [
            for (final (label, value, color) in [
              (i18n.t('tripBestPrice'), best?.totalPriceSar ?? 0, AppColors.darkGreen),
              (i18n.t('tripAverage'), avg, AppColors.foreground),
              (i18n.t('tripSavings'), savings, savings > 0 ? AppColors.success : AppColors.muted),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: CardBox(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      const SizedBox(height: 2),
                      FittedBox(fit: BoxFit.scaleDown, child: Price(value, decimals: 0, style: TextStyle(color: color, fontWeight: FontWeight.w800))),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          SectionLabel('${i18n.t('tripStops')} (${stops.length})'),
          if (stops.isEmpty)
            MessageState(icon: Icons.storefront_outlined, title: i18n.t('noStopsYet'))
          else
            for (final s in stops)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CardBox(
                  borderColor: s.id == best?.id ? AppColors.success : AppColors.border,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text(s.storeName, style: const TextStyle(fontWeight: FontWeight.w800))),
                      if (s.id == best?.id && stops.length > 1) ...[
                        StatusChip(label: i18n.t('bestStopBadge'), color: AppColors.success, icon: Icons.star),
                        const SizedBox(width: 6),
                      ],
                      StatusChip(label: verdictLabel(i18n, s.verdict), color: verdictColor(s.verdict)),
                    ]),
                    if ((s.location ?? '').isNotEmpty) Text(s.location!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Price(s.totalPriceSar, decimals: 0, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text('· ${formatNumber(s.weightGrams)} ${i18n.t('gramsShort')} · ${s.purityLabel}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.muted),
                        onPressed: () async {
                          final ok = await confirmDialog(context, title: i18n.t('deleteStop'), message: s.storeName, confirmLabel: i18n.t('delete'), destructive: true);
                          if (ok) state.deleteStop(trip.id, s.id);
                        },
                      ),
                    ]),
                    Text(
                      '${formatSar(s.perGramSar, i18n.lang)} / ${i18n.t('gramsShort')} · ${i18n.t('breakdownMakingPerGram')}: ${formatSar(s.makingPerGramSar, i18n.lang)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({super.key, required this.tripId});
  final String tripId;

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _store = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  String _purity = '21K';
  bool _vatIncluded = true;
  String _origin = 'local';
  TripStop? _saved;
  FairPriceResult? _savedResult;

  @override
  void initState() {
    super.initState();
    final trip = context.read<TripsState>().byId(widget.tripId);
    if (trip != null) {
      _purity = trip.category == 'bar' ? '24K' : trip.purityLabel;
      if (trip.weightGrams != null) _weight.text = formatNumber(trip.weightGrams!).replaceAll(',', '');
    }
  }

  @override
  void dispose() {
    for (final c in [_store, _location, _price, _weight, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(MarketTrip trip, double pure) {
    final i18n = context.i18nRead;
    final price = parseNumber(_price.text);
    final weight = parseNumber(_weight.text);
    if (_store.text.trim().isEmpty || price == null || price <= 0 || weight == null || weight <= 0) {
      return showSnack(context, i18n.t('stopFormInvalid'), error: true);
    }
    if (pure <= 0) return showSnack(context, i18n.t('loadingPriceData'), error: true);
    final options = tripPuritiesFor(trip.category);
    final purity = options.firstWhere((p) => p.label == _purity, orElse: () => options.first);
    final r = evaluateFairPrice(totalPriceSar: price, weightGrams: weight, purityFactor: purity.factor, vatIncluded: _vatIncluded, purePerGramSar: pure);
    final stop = TripStop(
      id: 'stop-${DateTime.now().millisecondsSinceEpoch}',
      storeName: _store.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      totalPriceSar: price,
      weightGrams: weight,
      purityLabel: purity.label,
      purityFactor: purity.factor,
      vatIncluded: _vatIncluded,
      origin: _origin,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      visitedAt: DateTime.now().toIso8601String(),
      verdict: r.verdict,
      makingPerGramSar: r.makingPerGram,
      marketReferencePerGramSar: r.fairPerGram,
    );
    context.read<TripsState>().addStop(trip.id, stop);
    haptic(Haptic.medium);
    setState(() {
      _saved = stop;
      _savedResult = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final trip = context.watch<TripsState>().byId(widget.tripId);
    final pure = purePerGram(context);
    if (trip == null) return Scaffold(appBar: AppBar(), body: MessageState(icon: Icons.search_off, title: i18n.t('tripsEmptyTitle')));

    if (_saved != null && _savedResult != null) {
      final r = _savedResult!;
      final s = _saved!;
      final color = verdictColor(r.verdict);
      final (banner, hint) = switch (r.verdict) {
        'excellent' => (i18n.t('excellentDealBanner'), i18n.t('fairPriceHintExcellent')),
        'fair' => (i18n.t('fairDealBanner'), i18n.t('fairPriceHintFair')),
        _ => (i18n.t('highDealBanner'), i18n.t('fairPriceHintHigh')),
      };
      return Scaffold(
        appBar: AppBar(title: Text(s.storeName)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: color)),
              child: Column(children: [
                Text(banner, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(hint, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
              ]),
            ),
            const SizedBox(height: 14),
            CardBox(
              child: Column(children: [
                InfoRow(label: i18n.t('breakdownStorePrice'), valueWidget: Price(s.totalPriceSar)),
                if (r.vatAmount > 0) InfoRow(label: i18n.t('breakdownVAT'), valueWidget: Price(r.vatAmount)),
                InfoRow(label: i18n.t('breakdownGoldValue'), valueWidget: Price(r.goldValue)),
                InfoRow(label: i18n.t('breakdownMaking'), valueWidget: Price(r.preTaxTotal - r.goldValue)),
                const Divider(),
                InfoRow(label: i18n.t('breakdownMakingPerGram'), highlight: true, valueColor: color, valueWidget: Price(r.makingPerGram)),
                Text(i18n.t('fairBandNote', {'low': fairMakingLow.toInt(), 'high': fairMakingHigh.toInt()}), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 18),
            GoldButton(
              label: i18n.t('tryAnother'),
              onPressed: () => setState(() {
                _saved = null;
                _savedResult = null;
                _store.clear();
                _location.clear();
                _price.clear();
                _notes.clear();
              }),
            ),
            TextButton(onPressed: () => context.pop(), child: Text(i18n.t('close'))),
          ],
        ),
      );
    }

    final purities = tripPuritiesFor(trip.category);
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('addStopTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(i18n.t('storeName')),
          TextField(controller: _store, decoration: InputDecoration(hintText: i18n.t('storeNamePlaceholder'))),
          const SizedBox(height: 14),
          SectionLabel(i18n.t('storeLocation')),
          TextField(controller: _location, decoration: InputDecoration(hintText: i18n.t('storeLocationPlaceholder'))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(i18n.t('storeQuotedPrice')),
                TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(suffixText: i18n.t('sarShort'))),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(i18n.t('storeWeight')),
                TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(suffixText: i18n.t('gramsShort'))),
              ]),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.darkGreen,
            value: _vatIncluded,
            onChanged: (v) => setState(() => _vatIncluded = v),
            title: Text(i18n.t('vatIncluded')),
          ),
          SectionLabel(i18n.t('tripPurity')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in purities)
              Pill(
                label: pure > 0 ? '${p.label} · ${formatNumber(pure * p.factor, decimals: 0)}/${i18n.t('gramsShort')}' : p.label,
                active: _purity == p.label,
                onTap: () => setState(() => _purity = p.label),
              ),
          ]),
          const SizedBox(height: 14),
          SectionLabel(i18n.t('storeMakingOrigin')),
          Wrap(spacing: 8, children: [
            Pill(label: i18n.t('originLocal'), active: _origin == 'local', onTap: () => setState(() => _origin = 'local')),
            Pill(label: i18n.t('originImported'), active: _origin == 'imported', onTap: () => setState(() => _origin = 'imported')),
          ]),
          const SizedBox(height: 14),
          SectionLabel(i18n.t('notes')),
          TextField(controller: _notes, maxLines: 2),
          const SizedBox(height: 24),
          GoldButton(label: i18n.t('addToTrip'), onPressed: () => _save(trip, pure)),
        ],
      ),
    );
  }
}
