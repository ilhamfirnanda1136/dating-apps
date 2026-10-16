import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Klien HTTP tunggal untuk semua panggilan `/api/v1`.
///
/// Pola: method publik (get/post/...) → [_json] atau [_send] → [_raw].
/// Kalau server menjawab 401, kita coba refresh token sekali, lalu ulangi request.
class ApiClient {
  ApiClient({TokenStorage? storage, http.Client? httpClient})
      : _storage = storage ?? TokenStorage(),
        _http = httpClient ?? http.Client();

  final TokenStorage _storage;
  final http.Client _http;

  /// Kunci supaya banyak request 401 tidak menembak /auth/refresh bersamaan.
  Future<void>? _refreshing;

  Future<Map<String, dynamic>> get(String path) => _json('GET', path);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _json('POST', path, body: body, auth: auth);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _json('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) =>
      _json('PATCH', path, body: body);

  /// Untuk endpoint yang tidak mengembalikan JSON (logout, 204).
  Future<void> postEmpty(String path, {Map<String, dynamic>? body}) async {
    await _send('POST', path, body: body);
  }

  Future<void> patchEmpty(String path) async {
    await _send('PATCH', path);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  /// Parse body JSON menjadi Map. Backend kita selalu `{ data: ... }` atau `{ error: ... }`.
  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final response = await _send(method, path, body: body, auth: auth);
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid');
  }

  /// Kirim request + otomatis refresh token jika 401.
  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final response = await _raw(method, path, body: body, auth: auth);
    // Bukan 401, atau endpoint tanpa auth, atau sudah pernah di-retry → selesai.
    if (response.statusCode != 401 || !auth || !retry) {
      _throwIfNeeded(response);
      return response;
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      _throwIfNeeded(response);
      return response;
    }

    // Ulangi request asli dengan access token baru.
    final retryResponse = await _raw(method, path, body: body, auth: auth);
    _throwIfNeeded(retryResponse);
    return retryResponse;
  }

  /// Request HTTP mentah: pasang header JSON + Bearer token.
  Future<http.Response> _raw(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await _storage.readAccess();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final encoded = body == null ? null : jsonEncode(body);
    try {
      // Switch expression Dart 3: pilih method HTTP.
      return switch (method) {
        'GET' => await _http.get(uri, headers: headers),
        'PUT' => await _http.put(uri, headers: headers, body: encoded),
        'PATCH' => await _http.patch(uri, headers: headers, body: encoded),
        'DELETE' => await _http.delete(uri, headers: headers),
        _ => await _http.post(uri, headers: headers, body: encoded),
      };
    } catch (_) {
      // Gagal DNS / backend mati / CORS, bukan error JSON dari server.
      throw const ApiException('Tidak bisa terhubung ke server. Pastikan backend sedang berjalan.');
    }
  }

  /// Jika beberapa request 401 bersamaan, mereka menunggu refresh yang sama.
  Future<bool> _tryRefresh() async {
    if (_refreshing != null) {
      await _refreshing;
      return (await _storage.readAccess()) != null;
    }

    final future = _refreshOnce();
    _refreshing = future;
    try {
      return await future;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _refreshOnce() async {
    final refreshToken = await _storage.readRefresh();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.clear();
      return false;
    }

    try {
      final response = await _raw(
        'POST',
        '/auth/refresh',
        body: {'refresh_token': refreshToken},
        auth: false,
      );
      if (response.statusCode >= 400) {
        await _storage.clear();
        return false;
      }
      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! Map<String, dynamic>) return false;
      final access = data['access_token'] as String?;
      final refresh = data['refresh_token'] as String?;
      if (access == null || refresh == null) return false;
      await _storage.save(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      await _storage.clear();
      return false;
    }
  }

  /// Status >= 400 dijadikan [ApiException] supaya UI bisa tampilkan pesannya.
  void _throwIfNeeded(http.Response response) {
    if (response.statusCode < 400) return;
    throw ApiException(_messageOf(response), statusCode: response.statusCode, code: _codeOf(response));
  }

  String _messageOf(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        final details = error['details'];
        // Zod biasanya kirim daftar { field, message }.
        if (details is List && details.isNotEmpty) {
          final first = details.first;
          if (first is Map && first['message'] is String) return first['message'] as String;
        }
        if (error['message'] is String) return error['message'] as String;
      }
    } catch (_) {}
    if (response.statusCode == 401) return 'Sesi berakhir. Silakan masuk lagi.';
    return 'Terjadi kesalahan pada server';
  }

  String? _codeOf(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        return (decoded['error'] as Map)['code'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
