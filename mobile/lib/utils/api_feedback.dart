import 'package:flutter/material.dart';

import '../api/api_exception.dart';

/// Tampilkan error API sebagai SnackBar di bawah layar.
///
/// [ScaffoldMessenger.of(context)] mencari Scaffold terdekat di widget tree.
/// Selalu cek `mounted` dulu kalau dipanggil setelah `await`, karena
/// halaman mungkin sudah ditutup.
void showApiError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Terjadi kesalahan. Coba lagi.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
