import 'package:flutter/foundation.dart';

/// Alamat backend. Kelas utilitas: konstruktor privat supaya tidak di-new.
class ApiConfig {
  ApiConfig._();

  /// Diisi saat compile lewat:
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1`
  /// [String.fromEnvironment] dibaca saat build, bukan saat runtime.
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Pilih URL sesuai platform.
  /// Android emulator tidak bisa `localhost` (itu HP palsu itu sendiri),
  /// jadi pakai `10.0.2.2` yang mengarah ke komputer host.
  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api/v1';
      default:
        return 'http://127.0.0.1:3000/api/v1';
    }
  }
}
