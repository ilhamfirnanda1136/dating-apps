/// Padding nol di depan: 9 jadi "09".
String _two(int n) => n.toString().padLeft(2, '0');

/// Jam percakapan, contoh 08:05.
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// Tampilkan waktu relatif untuk daftar chat:
/// hari ini → jam, kemarin → teks, lebih lama → tanggal.
///
/// [now] opsional supaya mudah diuji di unit test (waktu bisa difix).
String formatChatTime(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  // Buang jam/menit supaya bandingannya per-hari, bukan per-detik.
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return formatClock(t);
  if (diff == 1) return 'Kemarin';
  return '${_two(t.day)}/${_two(t.month)}';
}
