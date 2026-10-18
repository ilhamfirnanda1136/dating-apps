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
  runApp(FindLoveApp(session: SessionStore()));
}

/// Widget akar. [StatefulWidget] dipakai karena ChatStore harus di-[dispose]
/// saat app ditutup, supaya listener tidak bocor.
class FindLoveApp extends StatefulWidget {
  const FindLoveApp({super.key, required this.session});

  /// Status login/profil. Disimpan di sini supaya tidak hilang saat rebuild.
  final SessionStore session;

  @override
  State<FindLoveApp> createState() => _FindLoveAppState();
}

class _FindLoveAppState extends State<FindLoveApp> {
  /// State percakapan hidup selama app berjalan (bukan per-halaman).
  final _chatStore = ChatStore();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_syncWebSocket);
    _syncWebSocket();
  }

  void _syncWebSocket() async {
    if (widget.session.isLoggedIn) {
      final token = await widget.session.storage.readAccess();
      if (token != null && token.isNotEmpty) {
        _chatStore.initWebSocket(token);
      }
    } else {
      _chatStore.disconnectWebSocket();
    }
  }

  /// [dispose] dipanggil Flutter saat widget ini dihapus dari tree.
  /// Selalu tutup ChangeNotifier supaya tidak ada memory leak.
  @override
  void dispose() {
    widget.session.removeListener(_syncWebSocket);
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
          title: 'FindLove — Temukan cintamu',
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
