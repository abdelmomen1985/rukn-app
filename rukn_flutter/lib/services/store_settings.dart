import '../core/api.dart';
import '../models/gold_prices.dart';

class OrderingStatus {
  const OrderingStatus({required this.open, this.messageAr = '', this.messageEn = ''});
  final bool open;
  final String messageAr;
  final String messageEn;
  static const openStatus = OrderingStatus(open: true);
}

class Announcement {
  const Announcement({required this.id, required this.textAr, required this.textEn, this.href});
  final String id;
  final String textAr;
  final String textEn;
  final String? href;
}

class AnnouncementBar {
  const AnnouncementBar({required this.theme, required this.bilingual, required this.items});
  final String theme; // gold | green | cream
  final bool bilingual;
  final List<Announcement> items;
}

class AuthSettings {
  const AuthSettings({required this.otpEnabled, required this.passwordEnabled, required this.otpLength});
  final bool otpEnabled;
  final bool passwordEnabled;
  final int otpLength;

  /// What a backend without `/store/auth-settings` supports.
  static const legacy = AuthSettings(otpEnabled: false, passwordEnabled: true, otpLength: 4);
}

class CatalogBranch {
  const CatalogBranch({required this.id, required this.name, required this.nameEn, required this.city});
  final String id;
  final String name;
  final String nameEn;
  final String city;
}

/// Multi-branch catalogue: which products are exclusive to which branches.
class BranchCatalog {
  const BranchCatalog({required this.configured, required this.branches, required this.exclusive});
  final bool configured;
  final List<CatalogBranch> branches;
  final Map<String, List<String>> exclusive;

  static const empty = BranchCatalog(configured: false, branches: [], exclusive: {});

  List<String>? restrictionOf(String? productId) => productId == null ? null : exclusive[productId];

  String branchNames(List<String> ids, String lang) {
    final names = ids.map((id) {
      final b = branches.where((x) => x.id == id).firstOrNull;
      if (b == null) return id;
      return lang == 'en' && b.nameEn.isNotEmpty ? b.nameEn : b.name;
    });
    return names.join(lang == 'ar' ? ' أو ' : ' or ');
  }

  static List<String>? intersect(Iterable<List<String>?> restrictions) {
    List<String>? allowed;
    for (final r in restrictions) {
      if (r == null) continue;
      allowed = allowed == null ? r.toSet().toList() : allowed.where(r.contains).toList();
    }
    return allowed;
  }

  List<String>? cartBranches(Iterable<String?> productIds) => intersect(productIds.map(restrictionOf));

  /// Explains why a product cannot join the cart, or null when it can.
  String? addToCartConflict(Iterable<String?> cartProductIds, String? productId, String lang) {
    final incoming = restrictionOf(productId);
    if (incoming == null) return null;
    final current = cartBranches(cartProductIds);
    if (current == null) return null;
    if ((intersect([current, incoming]) ?? const []).isNotEmpty) return null;
    final productBranch = branchNames(incoming, lang);
    final cartBranch = branchNames(current, lang);
    return lang == 'ar'
        ? 'هذا المنتج متوفر في $productBranch فقط، وسلتك تحتوي على منتجات من $cartBranch. أكمل طلبك الحالي أو أزل تلك المنتجات أولاً.'
        : 'This item is only available at $productBranch, and your cart holds items from $cartBranch. Complete your current order or remove those items first.';
  }

  String? exclusiveLabel(String? productId, String lang) {
    final r = restrictionOf(productId);
    if (r == null || r.isEmpty) return null;
    final names = branchNames(r, lang);
    return lang == 'ar' ? 'متوفر في $names فقط' : 'Only available at $names';
  }
}

class VatInfo {
  const VatInfo({required this.taxRate, required this.exempt});
  final double taxRate;
  final Map<String, bool> exempt;
  static const none = VatInfo(taxRate: 0, exempt: {});

  /// VAT contained in a VAT-inclusive gross amount, rounded to halalas.
  static double extract(double gross, double ratePercent) {
    if (!(ratePercent > 0) || !gross.isFinite) return 0;
    return ((gross * ratePercent) / (100 + ratePercent) * 100).roundToDouble() / 100;
  }

  double? lineVat(String productId, double lineTotal) =>
      exempt[productId] == true ? null : extract(lineTotal, taxRate);
}

class StoreSettings {
  StoreSettings._();

  static Future<GoldPrices> goldPrices() async => GoldPrices.fromJson(asMap(await Api.get('/store/gold-prices')));

  static Future<OrderingStatus> orderingStatus() async {
    try {
      final body = asMap(await Api.get('/store/ordering-status'));
      return OrderingStatus(
        open: body['orders_enabled'] != false,
        messageAr: asString(body['closed_message_ar']),
        messageEn: asString(body['closed_message_en']),
      );
    } catch (_) {
      return OrderingStatus.openStatus;
    }
  }

  static Future<AnnouncementBar?> announcements() async {
    try {
      final body = asMap(await Api.get('/store/announcements'));
      if (body['enabled'] != true) return null;
      final items = <Announcement>[];
      for (final raw in asList(body['items'])) {
        final m = asMap(raw);
        final ar = asString(m['text_ar']).trim();
        final en = asString(m['text_en']).trim();
        if (ar.isEmpty && en.isEmpty) continue;
        final href = asString(m['link_url']).trim();
        items.add(Announcement(
          id: asString(m['id'], '${items.length}'),
          textAr: ar,
          textEn: en,
          href: href.startsWith('http') ? href : null,
        ));
      }
      if (items.isEmpty) return null;
      final theme = asString(body['theme']);
      return AnnouncementBar(
        theme: const ['gold', 'green', 'cream'].contains(theme) ? theme : 'gold',
        bilingual: body['bilingual'] != false,
        items: items,
      );
    } catch (_) {
      return null;
    }
  }

  /// Which sign-in forms to render. A 404 means the backend predates OTP sign-in.
  static Future<AuthSettings> authSettings() async {
    try {
      final raw = asMap(await Api.get('/store/auth-settings'));
      return AuthSettings(
        otpEnabled: raw['otp_enabled'] == true,
        passwordEnabled: raw['password_enabled'] == true,
        otpLength: asInt(raw['otp_length']) ?? 4,
      );
    } on MedusaError catch (e) {
      if (e.status == 404) return AuthSettings.legacy;
      rethrow;
    }
  }

  static BranchCatalog _branchCache = BranchCatalog.empty;
  static DateTime? _branchAt;
  static BranchCatalog get cachedBranchCatalog => _branchCache;

  static Future<BranchCatalog> branchCatalog() async {
    if (_branchAt != null && DateTime.now().difference(_branchAt!) < const Duration(minutes: 1)) {
      return _branchCache;
    }
    try {
      final v = asMap(await Api.get('/store/branch-catalog'));
      final exclusive = <String, List<String>>{};
      asMap(v['exclusive']).forEach((k, ids) => exclusive[k] = [for (final id in asList(ids)) '$id']);
      _branchCache = BranchCatalog(
        configured: v['configured'] == true,
        branches: [
          for (final b in asList(v['branches']))
            CatalogBranch(
              id: asString(asMap(b)['id']),
              name: asString(asMap(b)['name']),
              nameEn: asString(asMap(b)['name_en']),
              city: asString(asMap(b)['city']),
            ),
        ],
        exclusive: exclusive,
      );
      _branchAt = DateTime.now();
    } catch (_) {
      // keep whatever was cached
    }
    return _branchCache;
  }

  static Future<VatInfo> productVat(List<String> productIds) async {
    final ids = productIds.toSet().where((e) => e.isNotEmpty).toList();
    if (ids.isEmpty) return VatInfo.none;
    try {
      final params = ids.map((id) => 'id[]=${Uri.encodeQueryComponent(id)}').join('&');
      final data = asMap(await Api.get('/store/products/vat?$params'));
      final exempt = <String, bool>{};
      asMap(data['products']).forEach((id, row) => exempt[id] = asMap(row)['vat_exempt'] == true);
      final rate = asDouble(data['tax_rate']) ?? 0;
      return VatInfo(taxRate: rate > 0 ? rate : 0, exempt: exempt);
    } catch (_) {
      return VatInfo.none;
    }
  }
}
