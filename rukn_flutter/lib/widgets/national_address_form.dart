import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/national_address.dart';
import 'common.dart';

/// Saudi National Address entry: look the short code (e.g. RRRD2929) up, or
/// type the parts by hand. Reports a draft (complete or not) on every change.
class NationalAddressForm extends StatefulWidget {
  const NationalAddressForm({super.key, this.initial, required this.onChanged});
  final NationalAddressDraft? initial;
  final ValueChanged<NationalAddressDraft?> onChanged;

  @override
  State<NationalAddressForm> createState() => _NationalAddressFormState();
}

class _NationalAddressFormState extends State<NationalAddressForm> {
  late NationalAddressDraft _draft = widget.initial?.copy() ?? NationalAddressDraft();
  late final _code = TextEditingController(text: _draft.shortAddress);
  late final _building = TextEditingController(text: _draft.buildingNumber);
  late final _street = TextEditingController(text: _draft.street);
  late final _district = TextEditingController(text: _draft.district);
  late final _city = TextEditingController(text: _draft.city);
  late final _postal = TextEditingController(text: _draft.postalCode);
  late final _additional = TextEditingController(text: _draft.additionalNumber);
  late final _description = TextEditingController(text: _draft.buildingDescription);
  bool _manual = false;
  bool _looking = false;
  String? _message;

  @override
  void didUpdateWidget(covariant NationalAddressForm old) {
    super.didUpdateWidget(old);
    if (widget.initial != null && widget.initial != old.initial) {
      _draft = widget.initial!.copy();
      _syncControllers();
    }
  }

  @override
  void dispose() {
    for (final c in [_code, _building, _street, _district, _city, _postal, _additional, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    _code.text = _draft.shortAddress;
    _building.text = _draft.buildingNumber;
    _street.text = _draft.street;
    _district.text = _draft.district;
    _city.text = _draft.city;
    _postal.text = _draft.postalCode;
    _additional.text = _draft.additionalNumber;
    _description.text = _draft.buildingDescription;
  }

  void _emit() {
    _draft
      ..shortAddress = _code.text
      ..buildingNumber = _building.text
      ..street = _street.text
      ..district = _district.text
      ..city = _city.text
      ..postalCode = _postal.text
      ..additionalNumber = _additional.text
      ..buildingDescription = _description.text;
    widget.onChanged(_draft);
  }

  Future<void> _lookup() async {
    final i18n = context.i18nRead;
    if (!isShortAddress(_code.text)) {
      setState(() => _message = i18n.t('shortAddressInvalid'));
      return;
    }
    setState(() {
      _looking = true;
      _message = null;
    });
    final result = await lookupNationalAddress(_code.text, i18n.lang, previous: _draft);
    if (!mounted) return;
    setState(() {
      _looking = false;
      if (result.kind == 'found') {
        _draft = result.draft!..buildingDescription = _description.text;
        _syncControllers();
        _manual = false;
        widget.onChanged(_draft);
      } else if (result.kind == 'not_found') {
        _message = (result.message ?? '').isNotEmpty ? result.message : i18n.t('shortAddressNotFound');
        _manual = true;
      } else {
        _message = result.message ?? i18n.t('shortAddressLookupFailed');
        _manual = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final verified = _draft.verified && !_manual;
    return CardBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.pin_drop_outlined, color: AppColors.darkGreen, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text(i18n.t('nationalAddress'), style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(i18n.t('optional'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 9,
                  decoration: InputDecoration(hintText: i18n.t('shortAddressHint'), counterText: ''),
                  onChanged: (_) {
                    _draft.verified = false;
                    _emit();
                  },
                  onSubmitted: (_) => _lookup(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(90, 48)),
                  onPressed: _looking ? null : _lookup,
                  child: _looking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : Text(i18n.t('lookup')),
                ),
              ),
            ],
          ),
          if (_message != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(_message!, style: const TextStyle(color: AppColors.error, fontSize: 12.5))),
          if (verified && _draft.isComplete) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.verified, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(_draft.format(i18n.lang), style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            Text(_draft.city, style: const TextStyle(color: AppColors.muted)),
          ],
          if (_manual) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _building, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: i18n.t('buildingNumber')), onChanged: (_) => _emit())),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: _street, decoration: InputDecoration(hintText: i18n.t('street')), onChanged: (_) => _emit())),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _district, decoration: InputDecoration(hintText: i18n.t('district')), onChanged: (_) => _emit())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _city, decoration: InputDecoration(hintText: i18n.t('city')), onChanged: (_) => _emit())),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _postal, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: i18n.t('postalCode')), onChanged: (_) => _emit())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _additional, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: i18n.t('additionalNumber')), onChanged: (_) => _emit())),
            ]),
          ],
          const SizedBox(height: 8),
          TextField(controller: _description, decoration: InputDecoration(hintText: i18n.t('buildingDescription')), onChanged: (_) => _emit()),
          if (!_manual)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: () => setState(() => _manual = true), child: Text(i18n.t('enterManually'))),
            ),
        ],
      ),
    );
  }
}
