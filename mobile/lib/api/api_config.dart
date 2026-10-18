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

  /// URL WebSocket yang otomatis mengikuti skema dan host dari [baseUrl].
  static String get wsUrl {
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '$wsScheme://${uri.host}$portPart/ws';
  }

  /// Memastikan URL media menjadi URL lengkap dan sesuai target platform (misal emulator Android).
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && url.contains('localhost:3000')) {
        return url.replaceAll('localhost:3000', '10.0.2.2:3000');
      }
      return url;
    }
    final uri = Uri.parse(baseUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '${uri.scheme}://${uri.host}$portPart$cleanPath';
  }
}
