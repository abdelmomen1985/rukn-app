import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_base.dart';
import 'strings_extra.dart';
import 'site_sync/all.dart';

/// Language state. Arabic is the store's primary language, so it is the
/// default until the customer picks otherwise; the choice is persisted.
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

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == 'en' || stored == 'ar') _lang = stored!;
    } catch (_) {}
    notifyListeners();
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
