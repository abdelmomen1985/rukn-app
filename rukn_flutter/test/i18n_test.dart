import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/l10n/strings_base.dart';
import 'package:rukn_thamin/l10n/strings_extra.dart';
import 'package:rukn_thamin/l10n/site_sync/all.dart';

void main() {
  final en = {...baseStringsEn, ...extraStringsEn, ...siteSyncStringsEn};
  final ar = {...baseStringsAr, ...extraStringsAr, ...siteSyncStringsAr};

  test('every literal translation key used in lib/ exists in both languages', () {
    final pattern = RegExp(r"""(?:\.t|tr)\('([a-zA-Z0-9_]+)'""");
    final used = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in pattern.allMatches(f.readAsStringSync())) {
        used.add(m[1]!);
      }
    }
    // Keys built at runtime (status, metal, unit, tier … lookups).
    used.addAll([
      for (final s in ['pending', 'processing', 'shipped', 'delivered', 'cancelled']) 'orderStatus_$s',
      for (final s in ['bank_transfer', 'cod', 'paymob']) 'pm_$s',
      for (final s in ['bronze', 'silver', 'gold', 'platinum']) 'tier_$s',
      for (final s in ['semiannual', 'annual', 'lifetime']) 'plan_$s',
      'gold', 'silver', 'platinum', 'palladium',
      'grams', 'tolas', 'ounces', 'mithqal',
      'ring', 'bracelet', 'necklace', 'earring', 'bar', 'coin',
      'consultationExpect1', 'consultationExpect2', 'consultationExpect3',
      'alertFiredAbove', 'alertFiredBelow',
      'authNoAccount', 'authPhoneRegistered', 'authEmailTaken', 'authPhoneTaken',
      'authPhoneRejected', 'authInvalidName', 'authOtpUnavailable', 'otpInvalid', 'otpSendFailed',
    ]);
    final missingEn = used.where((k) => !en.containsKey(k)).toList()..sort();
    final missingAr = used.where((k) => !ar.containsKey(k)).toList()..sort();
    expect(missingEn, isEmpty, reason: 'missing English: $missingEn');
    expect(missingAr, isEmpty, reason: 'missing Arabic: $missingAr');
  });

  test('both languages define the same keys', () {
    expect(en.keys.toSet().difference(ar.keys.toSet()), isEmpty);
    expect(ar.keys.toSet().difference(en.keys.toSet()), isEmpty);
  });
}
