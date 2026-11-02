import '../core/format.dart';

/// Countries the OTP gateway delivers to (port of rukn-site/src/lib/phone.ts).
class OtpCountry {
  const OtpCountry(this.iso, this.dialCode, this.flag, this.nameAr, this.nameEn, this.mobile);
  final String iso;
  final String dialCode;
  final String flag;
  final String nameAr;
  final String nameEn;
  final RegExp mobile;
}

final List<OtpCountry> otpCountries = [
  OtpCountry('SA', '966', '🇸🇦', 'السعودية', 'Saudi Arabia', RegExp(r'^5\d{8}$')),
  OtpCountry('AE', '971', '🇦🇪', 'الإمارات', 'UAE', RegExp(r'^5\d{8}$')),
  OtpCountry('KW', '965', '🇰🇼', 'الكويت', 'Kuwait', RegExp(r'^[569]\d{7}$')),
  OtpCountry('QA', '974', '🇶🇦', 'قطر', 'Qatar', RegExp(r'^[3567]\d{7}$')),
  OtpCountry('BH', '973', '🇧🇭', 'البحرين', 'Bahrain', RegExp(r'^(3\d{7}|66\d{6})$')),
  OtpCountry('OM', '968', '🇴🇲', 'عُمان', 'Oman', RegExp(r'^[79]\d{7}$')),
  OtpCountry('EG', '20', '🇪🇬', 'مصر', 'Egypt', RegExp(r'^1[0125]\d{8}$')),
  OtpCountry('JO', '962', '🇯🇴', 'الأردن', 'Jordan', RegExp(r'^7[789]\d{7}$')),
];

/// Normalizes user input to E.164 (`+9665XXXXXXXX`) or null when invalid.
String? normalizeOtpPhone(String? input, [String? dialCode]) {
  if (input == null) return null;
  final raw = toWesternDigits(input).trim();
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  final explicit = raw.startsWith('+') || digits.startsWith('00');
  digits = digits.replaceFirst(RegExp(r'^00'), '');
  if (digits.isEmpty) return null;

  String? valid(OtpCountry country, String national) {
    final nsn = national.replaceFirst(RegExp(r'^0+'), '');
    return country.mobile.hasMatch(nsn) ? '+${country.dialCode}$nsn' : null;
  }

  for (final country in otpCountries) {
    if (digits.startsWith(country.dialCode)) {
      final phone = valid(country, digits.substring(country.dialCode.length));
      if (phone != null) return phone;
    }
  }
  if (explicit) return null;
  final wanted = (dialCode ?? '').replaceAll(RegExp(r'\D'), '');
  final picked = otpCountries.where((c) => c.dialCode == wanted).firstOrNull ?? otpCountries.first;
  return valid(picked, digits);
}

OtpCountry countryOfPhone(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  return otpCountries.where((c) => digits.startsWith(c.dialCode)).firstOrNull ?? otpCountries.first;
}

/// `+966501234567` → `0501234567`, for display.
String nationalPhoneOf(String? phone) {
  final e164 = normalizeOtpPhone(phone);
  if (e164 == null) return phone ?? '';
  final country = countryOfPhone(e164);
  return '0${e164.substring(country.dialCode.length + 1)}';
}
