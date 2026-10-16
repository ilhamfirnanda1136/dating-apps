import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'state/chat_store.dart';
import 'state/session_store.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_frame.dart';

/// Titik masuk aplikasi Flutter.
///
/// [WidgetsFlutterBinding.ensureInitialized] wajib dipanggil dulu kalau kita
/// butuh plugin (SharedPreferences, HTTP) sebelum [runApp].
/// [runApp] menempelkan widget akar ke layar.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KlikApp(session: SessionStore()));
}

/// Widget akar. [StatefulWidget] dipakai karena ChatStore harus di-[dispose]
/// saat app ditutup, supaya listener tidak bocor.
class KlikApp extends StatefulWidget {
  const KlikApp({super.key, required this.session});

  /// Status login/profil. Disimpan di sini supaya tidak hilang saat rebuild.
  final SessionStore session;

  @override
  State<KlikApp> createState() => _KlikAppState();
}

class _KlikAppState extends State<KlikApp> {
  /// State percakapan hidup selama app berjalan (bukan per-halaman).
  final _chatStore = ChatStore();

  /// [dispose] dipanggil Flutter saat widget ini dihapus dari tree.
  /// Selalu tutup ChangeNotifier supaya tidak ada memory leak.
  @override
  void dispose() {
    _chatStore.dispose();
    widget.session.dispose();
    super.dispose();
  }

  /// [build] dipanggil setiap kali perlu menggambar ulang.
  /// Urutan: SessionScope → ChatScope → MaterialApp.
  /// Scope adalah InheritedWidget: anak di bawahnya bisa ambil store
  /// lewat `SessionScope.of(context)` tanpa passing constructor.
  @override
  Widget build(BuildContext context) {
    return SessionScope(
      store: widget.session,
      child: ChatScope(
        store: _chatStore,
        child: MaterialApp(
          title: 'Klik — Temukan yang klik',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          // [builder] membungkus SEMUA rute. PhoneFrame membuat tampilan
          // HP di tengah saat dijalankan di Chrome desktop.
          builder: (context, child) => PhoneFrame(child: child!),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
