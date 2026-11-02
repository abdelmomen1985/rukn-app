import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../l10n/i18n.dart';
import '../services/account_service.dart';
import '../state/alerts_state.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/trips_state.dart';
import '../state/wishlist_state.dart';
import '../widgets/common.dart';

/// Everything this app keeps on the device; account deletion clears all of it.
/// `app_language` stays — it is a preference, not personal data.
Future<void> wipeDeviceData(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final keep = {'app_language'};
  for (final k in prefs.getKeys().where((k) => !keep.contains(k))) {
    await prefs.remove(k);
  }
  await TokenStore.clear();
  if (!context.mounted) return;
  context.read<CartState>().clear();
  context.read<WishlistState>().clear();
  context.read<TripsState>().clear();
  context.read<AlertsState>().clear();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    }).catchError((_) {});
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) showSnack(context, AppConfig.supportEmail);
  }

  void _support() {
    final i18n = context.i18nRead;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_outlined, color: AppColors.success),
              title: const Text('WhatsApp'),
              subtitle: Text('+${AppConfig.whatsapp}', textDirection: TextDirection.ltr),
              onTap: () {
                Navigator.pop(ctx);
                _open('https://wa.me/${AppConfig.whatsapp}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline, color: AppColors.darkGreen),
              title: Text(i18n.t('emailSupport')),
              subtitle: Text(AppConfig.supportEmail),
              onTap: () {
                Navigator.pop(ctx);
                _open('mailto:${AppConfig.supportEmail}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final i18n = context.i18nRead;
    final auth = context.read<AuthState>();
    final signedIn = auth.isSignedIn;
    final confirmed = await confirmDialog(
      context,
      title: signedIn ? i18n.t('deleteAccountTitle') : i18n.t('notSignedInDeleteTitle'),
      message: signedIn ? i18n.t('deleteAccountBody') : i18n.t('notSignedInDeleteBody'),
      confirmLabel: signedIn ? i18n.t('deleteAccountConfirm') : i18n.t('wipeDeviceData'),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final status = signedIn ? await AccountService.deleteAccount() : 'no_session';
    if (!mounted) return;
    // Only erase the device once the server side is actually gone.
    if (status == 'deleted' || status == 'no_session') {
      await wipeDeviceData(context);
      auth.setCustomer(null);
      if (mounted) showSnack(context, status == 'deleted' ? i18n.t('deleteAccountDone') : i18n.t('deviceDataWiped'));
      return;
    }
    if (status == 'unauthorized') auth.setCustomer(null);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i18n.t('deleteAccount')),
        content: Text(i18n.t('deleteAccountFailed')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(i18n.t('deleteAccountCancel'))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _open('mailto:${AppConfig.supportEmail}?subject=${Uri.encodeComponent('Account deletion')}');
            },
            child: Text(i18n.t('emailSupport')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final auth = context.watch<AuthState>();
    final c = auth.customer;

    final menu = <(IconData, String, String, VoidCallback)>[
      (Icons.receipt_long_outlined, i18n.t('orderHistory'), i18n.t('orderHistorySubtitle'), () => context.push('/orders')),
      if (c != null) ...[
        (Icons.badge_outlined, i18n.t('accountDetails'), i18n.t('accountDetailsSubtitle'), () => context.push('/account')),
        (Icons.place_outlined, i18n.t('addressBook'), i18n.t('addressBookSubtitle'), () => context.push('/addresses')),
        (Icons.workspace_premium_outlined, i18n.t('loyaltyProgram'), i18n.t('loyaltySubtitle'), () => context.push('/loyalty')),
      ],
      (Icons.notifications_active_outlined, i18n.t('priceAlerts'), i18n.t('priceAlertsSubtitle'), () => context.push('/invest/alerts')),
      (Icons.candlestick_chart_outlined, i18n.t('livePrices'), i18n.t('livePricesSubtitle'), () => context.push('/pricing')),
      (Icons.verified_outlined, i18n.t('verifyCertificate'), i18n.t('verifyCertificateSubtitle'), () => context.push('/certificate')),
      (Icons.menu_book_outlined, i18n.t('blog'), i18n.t('blogSubtitle'), () => context.push('/blog')),
      (Icons.help_outline, i18n.t('helpSupport'), i18n.t('helpSupportSubtitle'), _support),
      (Icons.privacy_tip_outlined, i18n.t('privacyPolicy'), i18n.t('privacyPolicySubtitle'), () => context.push('/privacy')),
      (Icons.gavel_outlined, i18n.t('termsOfUse'), i18n.t('termsOfUseSubtitle'), () => context.push('/terms')),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardBox(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(radius: 36, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 38, color: AppColors.darkGreen)),
                const SizedBox(height: 10),
                Text(c == null ? i18n.t('guestUser') : c.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  c == null ? i18n.t('signInSubtitle') : [c.email, c.phone].where((e) => (e ?? '').isNotEmpty).join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                auth.loading
                    ? const LinearProgressIndicator(color: AppColors.darkGreen)
                    : GoldButton(
                        label: c == null ? i18n.t('signIn') : i18n.t('signOut'),
                        onPressed: () async {
                          haptic(Haptic.medium);
                          if (c == null) {
                            context.push('/auth');
                          } else {
                            await auth.signOut();
                          }
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(i18n.t('language'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {i18n.lang},
                  onSelectionChanged: (v) {
                    haptic(Haptic.medium);
                    context.read<I18n>().setLang(v.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, subtitle, onTap) in menu)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardBox(
                padding: const EdgeInsets.all(14),
                onTap: () {
                  haptic();
                  onTap();
                },
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: AppColors.cream, child: Icon(icon, color: AppColors.darkGreen, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Icon(forwardIcon(context), color: AppColors.muted),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          CardBox(
            borderColor: AppColors.error,
            padding: const EdgeInsets.all(14),
            onTap: _deleteAccount,
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i18n.t('deleteAccount'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                      Text(i18n.t('deleteAccountSubtitle'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text(i18n.t('version', {'version': _version}), style: const TextStyle(color: AppColors.muted, fontSize: 12.5))),
          Center(
            child: Text(i18n.t('copyright', {'year': DateTime.now().year}),
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
