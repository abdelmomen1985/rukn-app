import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/content_service.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';

/// Bullion bar certificate lookup (`/store/bar-serials/:serial`).
class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, this.initialSerial});
  final String? initialSerial;

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  late final _serial = TextEditingController(text: widget.initialSerial ?? '');
  CertificateInfo? _cert;
  bool _loading = false;
  bool _searched = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialSerial ?? '').isNotEmpty) _verify();
  }

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (normalizeSerial(_serial.text).isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final c = await ContentService.lookupCertificate(_serial.text);
      if (mounted) setState(() => _cert = c);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _searched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = _cert;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('verifyCertificate'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(i18n.t('verifyCertificateIntro'), style: const TextStyle(color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 14),
          TextField(
            controller: _serial,
            textCapitalization: TextCapitalization.characters,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(hintText: i18n.t('serialNumber'), prefixIcon: const Icon(Icons.qr_code_2)),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 12),
          GoldButton(label: i18n.t('verify'), loading: _loading, onPressed: _verify),
          const SizedBox(height: 20),
          if (_failed)
            ErrorView(onRetry: _verify)
          else if (_searched && !_loading && c == null)
            MessageState(icon: Icons.gpp_bad_outlined, title: i18n.t('certificateNotFound'), subtitle: i18n.t('certificateNotFoundBody'))
          else if (c != null)
            _CertificateCard(cert: c),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert});
  final CertificateInfo cert;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final ok = !cert.revoked;
    final metalColor = cert.metal == 'silver' ? const Color(0xFF9CA3AF) : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: metalColor, width: 2),
        gradient: const LinearGradient(colors: [AppColors.darkGreen, AppColors.deepGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(ok ? Icons.verified : Icons.gpp_bad, color: ok ? const Color(0xFF34D399) : AppColors.error, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ok ? i18n.t('certificateAuthentic') : i18n.t('certificateRevoked'),
                  style: TextStyle(color: ok ? const Color(0xFF34D399) : AppColors.error, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(formatSerial(cert.serial),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(color: metalColor, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(aspectRatio: 16 / 10, child: NetImage(cert.product.image)),
          ),
          const SizedBox(height: 12),
          Text(cert.product.name.of(i18n.lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Column(children: [
              _Row(i18n.t('metal'), i18n.t(cert.metal)),
              if (cert.weightGrams != null) _Row(i18n.t('weight'), '${formatNumber(cert.weightGrams!)} ${i18n.t('gramsShort')}'),
              if (cert.purity.isNotEmpty) _Row(i18n.t('purity'), cert.purity),
              if (cert.refiner != null) _Row(i18n.t('refiner'), cert.refiner!.of(i18n.lang)),
              if (cert.assayer != null) _Row(i18n.t('assayer'), cert.assayer!.of(i18n.lang)),
              if (cert.dimensions != null) _Row(i18n.t('dimensions'), cert.dimensions!),
              if (cert.mintedAt != null) _Row(i18n.t('mintedAt'), formatDate(cert.mintedAt, i18n.lang)),
              if (cert.issuedAt != null) _Row(i18n.t('issuedAt'), formatDate(cert.issuedAt, i18n.lang)),
              if (cert.registeredAt != null) _Row(i18n.t('registeredAt'), formatDate(cert.registeredAt, i18n.lang)),
            ]),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
            onPressed: () => context.push('/product/${cert.product.id}'),
            child: Text(i18n.t('viewProduct')),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13))),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}
