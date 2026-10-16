/// Error dari API yang bisa ditampilkan ke pengguna.
/// [implements Exception] biar bisa ditangkap dengan `on ApiException`.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  /// Pesan ramah manusia, misalnya "Email atau password salah".
  final String message;

  /// Kode HTTP: 401, 404, 422, dst. Null kalau gagal jaringan.
  final int? statusCode;

  /// Kode bisnis dari backend, misalnya TOKEN_EXPIRED.
  final String? code;

  /// Dipakai saat `print(error)` atau interpolasi string.
  @override
  String toString() => message;
}
