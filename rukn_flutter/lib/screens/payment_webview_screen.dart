import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../widgets/common.dart';

/// Hosted checkout (Paymob) inside the app.
///
/// The provider redirects the browser to the website's return URL once the
/// customer is done; that navigation is intercepted and the screen pops with
/// `true`. Whatever the redirect says is ignored on purpose — the caller asks
/// the backend for the real payment state, exactly like the site does.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.url, this.title, this.returnPatterns = const ['/return', 'return=']});

  final String url;
  final String? title;
  final List<String> returnPatterns;

  /// Opens [url] and resolves once the customer leaves the payment page.
  /// On web (no webview) the page opens in a new tab and this resolves at once.
  static Future<bool> open(BuildContext context, String url, {String? title}) async {
    if (kIsWeb) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return true;
    }
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => PaymentWebViewScreen(url: url, title: title)),
    );
    return result ?? false;
  }

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _done = false;

  bool _isReturn(String url) {
    final initialHost = Uri.tryParse(widget.url)?.host;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host == initialHost) return false;
    return widget.returnPatterns.any(url.contains) &&
        !uri.host.contains('paymob') &&
        !uri.host.contains('accept.') &&
        !uri.host.contains('3ds');
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onNavigationRequest: (request) {
          if (_isReturn(request.url)) {
            _finish();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          if (_isReturn(url)) _finish();
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? i18n.t('securePayment')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final leave = await confirmDialog(
              context,
              title: i18n.t('leavePaymentTitle'),
              message: i18n.t('leavePaymentBody'),
              confirmLabel: i18n.t('leavePaymentConfirm'),
            );
            if (leave) _finish();
          },
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100, color: AppColors.primary, minHeight: 2),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
