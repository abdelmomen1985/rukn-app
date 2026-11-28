import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_base.dart';
import 'strings_extra.dart';
import 'site_sync/all.dart';

/// Language state. Until the customer picks a language (persisted), the app
/// follows the device: the first of Arabic or English in its preferred
/// languages, and Arabic, the store's primary language, when it lists neither.
class I18n extends ChangeNotifier {
  static const _storageKey = 'app_language';

  String _lang = 'ar';
  String get lang => _lang;
  bool get isAr => _lang == 'ar';
  bool get isRtl => _lang == 'ar';
  Locale get locale => Locale(_lang);
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  static final Map<String, String> _en = {...baseStringsEn, ...extraStringsEn, ...siteSyncStringsEn};
  static final Map<String, String> _ar = {...baseStringsAr, ...extraStringsAr, ...siteSyncStringsAr};

  Future<void> load({List<Locale>? deviceLocales}) async {
    _lang = deviceLanguage(deviceLocales ?? PlatformDispatcher.instance.locales);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == 'en' || stored == 'ar') _lang = stored!;
    } catch (_) {}
    notifyListeners();
  }

  /// The app language for a device's preferred-language list (most preferred first).
  static String deviceLanguage(List<Locale> locales) {
    for (final l in locales) {
      final code = l.languageCode.toLowerCase();
      if (code == 'ar' || code == 'en') return code;
    }
    return 'ar';
  }

  Future<void> setLang(String lang) async {
    if (lang == _lang) return;
    _lang = lang;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString(_storageKey, lang);
    } catch (_) {}
  }

  /// Looks a key up, substituting `{name}` placeholders from [args].
  String t(String key, [Map<String, Object?> args = const {}]) {
    var value = (isAr ? _ar[key] : _en[key]) ?? _en[key] ?? key;
    if (args.isNotEmpty) {
      args.forEach((name, v) => value = value.replaceAll('{$name}', '${v ?? ''}'));
    }
    return value;
  }

  /// Picks the right side of a bilingual pair, falling back to the other.
  String pick(String? ar, String? en) {
    final a = (ar ?? '').trim();
    final e = (en ?? '').trim();
    if (isAr) return a.isNotEmpty ? a : e;
    return e.isNotEmpty ? e : a;
  }

  static bool hasKey(String key) => _en.containsKey(key) && _ar.containsKey(key);
}

extension I18nContext on BuildContext {
  I18n get i18n => watch<I18n>();
  I18n get i18nRead => read<I18n>();
  String tr(String key, [Map<String, Object?> args = const {}]) => watch<I18n>().t(key, args);
}
