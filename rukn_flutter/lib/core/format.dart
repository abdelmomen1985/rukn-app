import 'package:intl/intl.dart';

/// Number formatting shared by every price on screen. Western digits in both
/// languages, matching the website (`formatNumber` in utils/currency.ts).
String formatNumber(num value, {int? decimals, int maxDecimals = 2}) {
  final isInt = value == value.roundToDouble();
  final min = decimals ?? (isInt ? 0 : 2);
  final max = decimals ?? maxDecimals;
  final f = NumberFormat.decimalPattern('en_US')
    ..minimumFractionDigits = min > max ? max : min
    ..maximumFractionDigits = max;
  return f.format(value);
}

/// "SAR 1,234" / "1,234 ر.س" — the riyal symbol widget is used where space allows.
String formatSar(num value, String lang, {int? decimals}) {
  final n = formatNumber(value, decimals: decimals);
  return lang == 'ar' ? '$n ر.س' : 'SAR $n';
}

/// Whole-riyal display used by the portfolio screens.
String formatSarWhole(num value, String lang) => formatSar(value.round(), lang, decimals: 0);

String formatSarCompact(num amount) {
  if (amount >= 1000000) return 'SAR ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'SAR ${(amount / 1000).toStringAsFixed(1)}K';
  return 'SAR ${amount.toStringAsFixed(0)}';
}

String formatDate(String? iso, String lang, {bool withTime = false}) {
  if (iso == null || iso.isEmpty) return '—';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return iso;
  final pattern = withTime ? DateFormat.yMMMd(lang).add_jm() : DateFormat.yMMMMd(lang);
  return pattern.format(date);
}

String formatTime(DateTime date, String lang) => DateFormat.Hms(lang).format(date.toLocal());

String formatPercent(num value, {int decimals = 2}) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(decimals)}%';

/// Arabic-Indic and Persian digits → ASCII, so numeric inputs accept either.
String toWesternDigits(String input) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final e = eastern.indexOf(ch);
    final p = persian.indexOf(ch);
    buffer.write(e >= 0 ? '$e' : (p >= 0 ? '$p' : ch));
  }
  return buffer.toString();
}

double? parseNumber(String input) {
  final cleaned = toWesternDigits(input).replaceAll(',', '').replaceAll('٫', '.').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
