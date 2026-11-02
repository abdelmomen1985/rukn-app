import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// A non-2xx answer from Medusa, with the decoded body when there was one.
class MedusaError implements Exception {
  MedusaError(this.status, this.body);

  final int status;
  final Object? body;

  String? get code => _field('code');
  String? get message => _field('message');
  int? get retryAfter {
    final value = body is Map ? (body as Map)['retry_after'] : null;
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  String? _field(String key) {
    final b = body;
    if (b is Map && b[key] is String && (b[key] as String).isNotEmpty) return b[key] as String;
    return null;
  }

  @override
  String toString() => 'MedusaError($status, ${message ?? body})';
}

/// Customer JWT storage: Keychain / Keystore on device, shared_preferences on web.
class TokenStore {
  TokenStore._();

  static const _key = 'medusa_customer_token';
  static const _secure = FlutterSecureStorage();
  static String? _cached;
  static bool _loaded = false;

  static Future<String?> read() async {
    if (_loaded) return _cached;
    try {
      if (kIsWeb) {
        _cached = (await SharedPreferences.getInstance()).getString(_key);
      } else {
        _cached = await _secure.read(key: _key);
      }
    } catch (_) {
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  static Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).setString(_key, token);
    } else {
      await _secure.write(key: _key, value: token);
    }
  }

  static Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      if (kIsWeb) {
        await (await SharedPreferences.getInstance()).remove(_key);
      } else {
        await _secure.delete(key: _key);
      }
    } catch (_) {
      // best effort
    }
  }
}

/// Thin Medusa store-API client shared by every service.
class Api {
  Api._();

  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _headers(Map<String, String>? extra, {bool json = true}) async {
    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'x-publishable-api-key': AppConfig.publishableKey,
      ...?extra,
    };
    if (!headers.containsKey('Authorization')) {
      final token = await TokenStore.read();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _uri(String path) =>
      Uri.parse('${AppConfig.baseUrl}${path.startsWith('/') ? path : '/$path'}');

  /// Raw request; throws [MedusaError] on a non-2xx status.
  static Future<http.Response> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final req = http.Request(method, _uri(path));
    req.headers.addAll(await _headers(headers));
    if (body != null) req.body = jsonEncode(body);
    final streamed = await _client.send(req).timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Object? decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
      }
      throw MedusaError(response.statusCode, decoded);
    }
    return response;
  }

  static Future<dynamic> _json(http.Response response) async {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<dynamic> get(String path, {Map<String, String>? headers}) async =>
      _json(await request('GET', path, headers: headers));

  static Future<dynamic> post(String path, [Object? body, Map<String, String>? headers]) async =>
      _json(await request('POST', path, body: body ?? <String, dynamic>{}, headers: headers));

  static Future<dynamic> delete(String path) async => _json(await request('DELETE', path));

  /// GET for routes that answer HTML (the printable invoice).
  static Future<String> getText(String path) async {
    final response = await request('GET', path, headers: {'Accept': 'text/html'});
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}

// ---------------------------------------------------------------------------
// JSON helpers — the store API is loosely typed, so every read is defensive.
// ---------------------------------------------------------------------------

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? value.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};

List<dynamic> asList(Object? value) => value is List ? value : const [];

String asString(Object? value, [String fallback = '']) =>
    value == null ? fallback : (value is String ? value : '$value');

String? asStringOrNull(Object? value) {
  if (value == null) return null;
  final s = value is String ? value : '$value';
  return s.isEmpty ? null : s;
}

double? asDouble(Object? value) {
  if (value is num) return value.isFinite ? value.toDouble() : null;
  if (value is String) return double.tryParse(value);
  return null;
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
