/// Build-time configuration.
///
/// Everything here can be overridden with `--dart-define`, e.g.
///
///   flutter run --dart-define=MEDUSA_URL=http://10.0.2.2:9000
///   flutter build appbundle --dart-define=WEB_ORIGIN=https://ruknthamin.com \
///     --dart-define=SUPPORT_EMAIL=support@ruknthamin.com ...
///
/// The defaults point at the deployed Medusa backend (rukn-admin) — the same
/// one rukn-site talks to — so a plain `flutter run` shows the live catalogue.
library;

class AppConfig {
  AppConfig._();

  static const String medusaUrl = String.fromEnvironment(
    'MEDUSA_URL',
    defaultValue: 'https://admin.rknthmin.com.sa',
  );

  static const String publishableKey = String.fromEnvironment(
    'MEDUSA_PUBLISHABLE_KEY',
    defaultValue: 'pk_375af1650d3fc81e3b35342130536b67fb37aba13f384f16bd3e1319e67cbaa1',
  );

  /// Public website. Privacy policy and terms pages live here (`/{lang}/privacy`,
  /// `/{lang}/terms`) and both stores open them during review.
  static const String webOrigin = String.fromEnvironment(
    'WEB_ORIGIN',
    defaultValue: 'https://rknthmin.com.sa',
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'info@alruknalthamin.com',
  );

  /// WhatsApp Business number, international format, digits only.
  static const String whatsapp = String.fromEnvironment(
    'WHATSAPP',
    defaultValue: '966573788758',
  );

  static const String legalEntity = String.fromEnvironment(
    'LEGAL_ENTITY',
    defaultValue: 'Rukn Thamin Trading',
  );

  static String get baseUrl => medusaUrl.replaceAll(RegExp(r'/+$'), '');
  static String get origin => webOrigin.replaceAll(RegExp(r'/+$'), '');
  /// Privacy policy page on the website (`/{lang}/privacy`). The app renders
  /// the same text in-app (`LegalScreen`) and links here as the web version.
  static String privacyPolicyUrl(String lang) => '$origin/$lang/privacy';

  /// Terms & Conditions page on the website (`/{lang}/terms`).
  static String termsUrl(String lang) => '$origin/$lang/terms';
  static String productUrl(String lang, String id) => '$origin/$lang/product/$id';
  static String certificateUrl(String lang, String serial) => '$origin/$lang/certificate/$serial';
}

/// Fixed SAMA peg; used to move between the USD/oz and SAR/oz feeds losslessly.
const double usdToSar = 3.75;
const double gramsPerOz = 31.1035;
