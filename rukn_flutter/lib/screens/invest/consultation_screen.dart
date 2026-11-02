import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/i18n.dart';
import '../../services/invest_service.dart';
import '../../state/auth_state.dart';
import '../../widgets/common.dart';
import '../payment_webview_screen.dart';

const _preferredTimes = ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00', '19:00', '20:00'];

/// Book a session with a gold specialist (`/store/consultations`). When the
/// admin charges for sessions the request comes back with a hosted checkout.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  ConsultationConfig? _config;
  final _days = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));
  int? _day;
  final Set<String> _times = {};
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String _status = 'idle'; // idle | sending | confirming | sent | unpaid | failed
  ConsultationRequest? _request;

  @override
  void initState() {
    super.initState();
    final c = context.read<AuthState>().customer;
    if (c != null) {
      _name.text = c.fullName;
      _email.text = c.email ?? '';
      _phone.text = c.phone ?? '';
    }
    InvestService.consultationConfig().then((c) {
      if (mounted) setState(() => _config = c);
    }).catchError((_) {
      if (mounted) setState(() => _config = const ConsultationConfig(enabled: false, feeAmountCents: 0, currency: 'SAR'));
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _summary => [
        'Name: ${_name.text}',
        'Email: ${_email.text.isEmpty ? '-' : _email.text}',
        'Phone: ${_phone.text.isEmpty ? '-' : _phone.text}',
        'Preferred date: ${_day == null ? '-' : DateFormat.yMMMEd('en').format(_days[_day!])}',
        'Preferred times: ${_times.isEmpty ? '-' : (_times.toList()..sort()).join(', ')}',
        'Notes: ${_notes.text.isEmpty ? '-' : _notes.text}',
      ].join('\n');

  Future<void> _fallback(String channel) async {
    final subject = Uri.encodeComponent('Gold consultation request');
    final body = Uri.encodeComponent(_summary);
    final url = channel == 'email'
        ? 'mailto:${AppConfig.supportEmail}?subject=$subject&body=$body'
        : 'https://wa.me/${AppConfig.whatsapp}?text=${Uri.encodeComponent('طلب استشارة / Consultation request\n\n$_summary')}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    final i18n = context.i18nRead;
    final hasContact = _email.text.contains('@') || toWesternDigits(_phone.text).replaceAll(RegExp(r'\D'), '').length >= 8;
    if (_name.text.trim().length < 2 || !hasContact) {
      showSnack(context, i18n.t('consultationRequiredFields'), error: true);
      return;
    }
    haptic(Haptic.medium);
    setState(() => _status = 'sending');
    try {
      final req = await InvestService.submitConsultation(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        preferredDate: _day == null ? null : _days[_day!].toIso8601String().substring(0, 10),
        preferredTimes: _times.toList()..sort(),
        notes: _notes.text.trim(),
      );
      _request = req;
      if (req.payment == null || req.payment!.checkoutUrl.isEmpty) {
        if (mounted) setState(() => _status = 'sent');
        return;
      }
      await _pay(req.payment!);
    } catch (_) {
      if (mounted) setState(() => _status = 'failed');
    }
  }

  Future<void> _pay(HostedPayment payment) async {
    if (!payment.simulated && mounted) {
      await PaymentWebViewScreen.open(context, payment.checkoutUrl);
    }
    if (!mounted) return;
    setState(() => _status = 'confirming');
    for (var i = 0; i < 15 && mounted; i++) {
      try {
        final state = await InvestService.confirmConsultationPayment(_request!.id);
        if (state == 'paid' || state == 'not_required') {
          if (mounted) setState(() => _status = 'sent');
          return;
        }
        if (state == 'failed') break;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    // The request is saved; only the payment is outstanding.
    if (mounted) setState(() => _status = 'unpaid');
  }

  Future<void> _retryPayment() async {
    setState(() => _status = 'sending');
    try {
      final p = await InvestService.retryConsultationPayment(_request!.id);
      await _pay(p);
    } catch (_) {
      if (mounted) setState(() => _status = 'unpaid');
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final fee = (_config?.enabled ?? false) ? (_config!.feeAmountCents / 100) : null;

    if (_status == 'sent' || _status == 'unpaid' || _status == 'confirming') {
      return Scaffold(
        appBar: AppBar(title: Text(i18n.t('consultationTitle'))),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              _status == 'sent' ? Icons.check_circle_outline : Icons.hourglass_bottom,
              size: 72,
              color: _status == 'sent' ? AppColors.primary : AppColors.warning,
            ),
            const SizedBox(height: 14),
            Text(
              _status == 'sent' ? i18n.t('consultationRequestedTitle') : (_status == 'confirming' ? i18n.t('paymentConfirmingTitle') : i18n.t('consultationUnpaidTitle')),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _status == 'sent' ? i18n.t('consultationRequestedSubtitle') : i18n.t('consultationUnpaidBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.6),
            ),
            const SizedBox(height: 18),
            CardBox(
              child: Column(children: [
                if (_request != null) InfoRow(label: i18n.t('consultationReference'), value: _request!.id.split('_').last.toUpperCase()),
                InfoRow(label: i18n.t('consultationDate'), value: _day == null ? '—' : DateFormat.MMMMEEEEd(i18n.lang).format(_days[_day!])),
                InfoRow(label: i18n.t('consultationTime'), value: _times.isEmpty ? '—' : (_times.toList()..sort()).join(', ')),
                if (fee != null) InfoRow(label: i18n.t('consultationFee'), highlight: true, valueWidget: Price(fee)),
              ]),
            ),
            const SizedBox(height: 20),
            if (_status == 'unpaid') ...[
              GoldButton(label: i18n.t('payNow'), onPressed: _retryPayment),
              const SizedBox(height: 8),
            ],
            if (_status == 'confirming') const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
            if (_status != 'confirming')
              OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: Text(i18n.t('consultationBackToPortfolio'))),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('consultationTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.15), border: Border.all(color: AppColors.primary, width: 2)),
                  child: const Icon(Icons.support_agent, color: AppColors.primary, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i18n.t('consultationSpecialistGeneric'), style: const TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('45 min · ${i18n.t('consultationPerSession')}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
                ),
                if (fee != null) Price(fee, style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in [i18n.t('specialtyMarket'), i18n.t('specialtyPortfolio'), i18n.t('specialtyBuySell')])
                  StatusChip(label: s, color: AppColors.primary),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionLabel(i18n.t('consultationSelectDate')),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = _day == i;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        haptic();
                        setState(() => _day = i);
                      },
                      child: Container(
                        width: 58,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.darkGreen : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AppColors.darkGreen : AppColors.border),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(DateFormat.E(i18n.lang).format(_days[i]), style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : AppColors.muted)),
                          Text('${_days[i].day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? AppColors.primary : AppColors.foreground)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionLabel(i18n.t('consultationPreferredTimes')),
              Text(i18n.t('consultationPreferredTimesHint'), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in _preferredTimes)
                  Pill(
                    label: t,
                    active: _times.contains(t),
                    onTap: () {
                      haptic();
                      setState(() => _times.contains(t) ? _times.remove(t) : _times.add(t));
                    },
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionLabel(i18n.t('consultationWhatToExpect')),
              for (final k in ['consultationExpect1', 'consultationExpect2', 'consultationExpect3'])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle_outline, size: 17, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i18n.t(k), style: const TextStyle(height: 1.5))),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SectionLabel(i18n.t('consultationYourDetails')),
              TextField(controller: _name, decoration: InputDecoration(hintText: i18n.t('fullName'), fillColor: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: i18n.t('email'), fillColor: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: i18n.t('phoneNumber'), fillColor: Colors.white)),
              const SizedBox(height: 10),
              TextField(controller: _notes, maxLines: 4, decoration: InputDecoration(hintText: i18n.t('consultationNotesPlaceholder'), fillColor: Colors.white)),
            ]),
          ),
          if (_status == 'failed') ...[
            const SizedBox(height: 14),
            CardBox(
              borderColor: AppColors.error,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(i18n.t('consultationFailedTitle'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(i18n.t('consultationSendFailed'), style: const TextStyle(color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => _fallback('email'), child: Text(i18n.t('emailSupport')))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: () => _fallback('whatsapp'), child: const Text('WhatsApp'))),
                ]),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          if (fee != null)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(i18n.t('consultationPaidNote', {'fee': formatSar(fee, i18n.lang)}), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5))),
            ]),
          const SizedBox(height: 14),
          GoldButton(
            label: fee != null ? i18n.t('consultationSubmitAndPay') : i18n.t('consultationSubmit'),
            loading: _status == 'sending' || _config == null,
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          Text(i18n.t('consultationPriceDisclaimer'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.5)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
