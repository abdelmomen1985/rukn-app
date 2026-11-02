import '../core/api.dart';
import '../core/format.dart';
import '../models/customer.dart';

/// Saudi National Address (port of rukn-site/src/lib/nationalAddress.ts).
class NationalAddressDraft {
  NationalAddressDraft({
    this.shortAddress = '',
    this.buildingNumber = '',
    this.street = '',
    this.district = '',
    this.city = '',
    this.postalCode = '',
    this.additionalNumber = '',
    this.buildingDescription = '',
    this.latitude,
    this.longitude,
    this.verified = false,
    this.latin,
  });

  String shortAddress;
  String buildingNumber;
  String street;
  String district;
  String city;
  String postalCode;
  String additionalNumber;
  String buildingDescription;
  double? latitude;
  double? longitude;
  bool verified;
  Map<String, dynamic>? latin;

  NationalAddressDraft copy() => NationalAddressDraft.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'short_address': shortAddress,
        'building_number': buildingNumber,
        'street': street,
        'district': district,
        'city': city,
        'postal_code': postalCode,
        'additional_number': additionalNumber,
        'building_description': buildingDescription,
        'latitude': latitude,
        'longitude': longitude,
        'verified': verified,
        'latin': latin,
      };

  factory NationalAddressDraft.fromJson(Map<String, dynamic> m) => NationalAddressDraft(
        shortAddress: asString(m['short_address']),
        buildingNumber: asString(m['building_number']),
        street: asString(m['street']),
        district: asString(m['district']),
        city: asString(m['city']),
        postalCode: asString(m['postal_code']),
        additionalNumber: asString(m['additional_number']),
        buildingDescription: asString(m['building_description']),
        latitude: asDouble(m['latitude']),
        longitude: asDouble(m['longitude']),
        verified: m['verified'] == true,
        latin: m['latin'] is Map ? asMap(m['latin']) : null,
      );

  factory NationalAddressDraft.fromCustomerAddress(CustomerAddress a) {
    final n = a.nationalAddress;
    if (n == null) {
      return NationalAddressDraft(street: a.address1 ?? '', city: a.city ?? '', postalCode: a.postalCode ?? '');
    }
    final verified = n['verified'] == true && isShortAddress(asString(n['short_address']));
    return NationalAddressDraft(
      shortAddress: asString(n['short_address']),
      buildingNumber: asString(n['building_number']),
      street: asString(n['street']),
      district: asString(n['district'], a.province ?? ''),
      city: a.city ?? '',
      postalCode: a.postalCode ?? '',
      additionalNumber: asString(n['additional_number']),
      buildingDescription: asString(n['building_description']),
      latitude: asDouble(n['latitude']),
      longitude: asDouble(n['longitude']),
      verified: verified,
      latin: verified && n['latin'] is Map ? asMap(n['latin']) : null,
    );
  }

  String get streetLine =>
      [toWesternDigits(buildingNumber.trim()), street.trim()].where((e) => e.isNotEmpty).join(' ');

  String format(String lang) {
    final sep = lang == 'ar' ? '، ' : ', ';
    final districtPostal =
        [district.trim(), toWesternDigits(postalCode.trim())].where((e) => e.isNotEmpty).join(' ');
    final main = [streetLine, districtPostal].where((e) => e.isNotEmpty).join(sep);
    final code = normalizeShortAddress(shortAddress);
    return [main, code].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
  }

  /// null when complete; otherwise which part is wrong.
  String? get problem {
    if (!isShortAddress(shortAddress)) return 'short_address';
    if ([buildingNumber, street, district, city].any((v) => v.trim().isEmpty)) return 'fields';
    if (!RegExp(r'^\d{1,6}$').hasMatch(toWesternDigits(buildingNumber.trim()))) return 'building_number';
    if (additionalNumber.trim().isNotEmpty &&
        !RegExp(r'^\d{1,6}$').hasMatch(toWesternDigits(additionalNumber.trim()))) {
      return 'building_number';
    }
    if (!RegExp(r'^\d{5}$').hasMatch(toWesternDigits(postalCode.trim()))) return 'postal_code';
    return null;
  }

  bool get isComplete => problem == null;

  /// The Medusa address fields + `metadata.national_address`.
  Map<String, dynamic> toMedusaAddressFields() {
    String? orNull(String v) => v.trim().isEmpty ? null : v.trim();
    final code = normalizeShortAddress(shortAddress);
    return {
      'address_1': streetLine,
      'address_2': [district.trim(), code ?? ''].where((e) => e.isNotEmpty).join(' - ').isEmpty
          ? null
          : [district.trim(), code ?? ''].where((e) => e.isNotEmpty).join(' - '),
      'city': city.trim(),
      'province': orNull(district),
      'postal_code': orNull(toWesternDigits(postalCode)),
      'metadata': {
        'national_address': {
          'short_address': code,
          'building_number': orNull(toWesternDigits(buildingNumber)),
          'street': orNull(street),
          'district': orNull(district),
          'additional_number': orNull(toWesternDigits(additionalNumber)),
          'building_description': orNull(buildingDescription),
          'latitude': latitude,
          'longitude': longitude,
          'verified': verified,
          'latin': verified ? latin : null,
        },
      },
    };
  }
}

String? normalizeShortAddress(String? input) {
  final cleaned = toWesternDigits(input ?? '').replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  return RegExp(r'^[A-Z]{4}\d{4}$').hasMatch(cleaned) ? cleaned : null;
}

bool isShortAddress(String? input) => normalizeShortAddress(input) != null;

class NationalAddressLookup {
  const NationalAddressLookup.found(this.draft) : kind = 'found', message = null;
  const NationalAddressLookup.notFound(this.message) : kind = 'not_found', draft = null;
  const NationalAddressLookup.error(this.message) : kind = 'error', draft = null;

  final String kind;
  final NationalAddressDraft? draft;
  final String? message;
}

Future<NationalAddressLookup> lookupNationalAddress(
  String code,
  String lang, {
  NationalAddressDraft? previous,
}) async {
  final normalized = normalizeShortAddress(code);
  if (normalized == null) return const NationalAddressLookup.error(null);
  try {
    final data = asMap(await Api.get('/store/national-address?code=${Uri.encodeQueryComponent(normalized)}&lang=$lang'));
    final a = asMap(data['address']);
    final lat = asDouble(a['latitude']);
    final keepPin = lat == null && previous?.latitude != null && previous?.longitude != null;
    return NationalAddressLookup.found(NationalAddressDraft(
      shortAddress: asString(a['short_address'], normalized),
      buildingNumber: asString(a['building_number']),
      street: asString(a['street']),
      district: asString(a['district']),
      city: asString(a['city']),
      postalCode: asString(a['postal_code']),
      additionalNumber: asString(a['additional_number']),
      buildingDescription: previous?.buildingDescription ?? '',
      latitude: keepPin ? previous!.latitude : lat,
      longitude: keepPin ? previous!.longitude : asDouble(a['longitude']),
      verified: true,
      latin: data['latin'] is Map ? asMap(data['latin']) : null,
    ));
  } on MedusaError catch (e) {
    if (e.status == 404) return NationalAddressLookup.notFound(e.message ?? '');
    return NationalAddressLookup.error(e.message);
  } catch (_) {
    return const NationalAddressLookup.error(null);
  }
}
