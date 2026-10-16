import 'package:shared_preferences/shared_preferences.dart';

/// Simpan JWT di perangkat.
/// [SharedPreferences] = key-value kecil yang tahan restart app
/// (di web tersimpan di localStorage).
class TokenStorage {
  static const _accessKey = 'klik_access_token';
  static const _refreshKey = 'klik_refresh_token';

  /// Access token: umur pendek, dikirim di header Authorization.
  Future<String?> readAccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  /// Refresh token: umur panjang, hanya untuk minta access token baru.
  Future<String?> readRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> save({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  /// Dipanggil saat logout atau token sudah tidak valid.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
