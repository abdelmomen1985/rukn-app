import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/l10n/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('I18n.deviceLanguage', () {
    test('English device opens in English', () {
      expect(I18n.deviceLanguage(const [Locale('en', 'GB')]), 'en');
      expect(I18n.deviceLanguage(const [Locale('en', 'US')]), 'en');
    });
    test('Arabic device opens in Arabic', () {
      expect(I18n.deviceLanguage(const [Locale('ar', 'SA')]), 'ar');
    });
    test('the first supported language in the list wins', () {
      expect(I18n.deviceLanguage(const [Locale('fr'), Locale('en'), Locale('ar')]), 'en');
      expect(I18n.deviceLanguage(const [Locale('ur'), Locale('ar'), Locale('en')]), 'ar');
    });
    test('neither Arabic nor English falls back to Arabic', () {
      expect(I18n.deviceLanguage(const [Locale('fr')]), 'ar');
      expect(I18n.deviceLanguage(const []), 'ar');
    });
  });

  group('I18n.load', () {
    test('follows the device when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final i18n = I18n();
      await i18n.load(deviceLocales: const [Locale('en', 'GB')]);
      expect(i18n.lang, 'en');
    });
    test('a saved choice beats the device language', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'ar'});
      final i18n = I18n();
      await i18n.load(deviceLocales: const [Locale('en', 'GB')]);
      expect(i18n.lang, 'ar');
    });
  });
}
