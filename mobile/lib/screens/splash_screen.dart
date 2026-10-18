import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/session_store.dart';
import '../theme/app_colors.dart';
import '../widgets/soft_background.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

/// Layar pertama: animasi logo sambil cek token.
/// Mixin [SingleTickerProviderStateMixin] memberi [vsync] untuk AnimationController
/// (hemat baterai: ticker berhenti saat widget tidak terlihat).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  /// [initState] hanya sekali, sebelum [build] pertama.
  /// Jangan pakai `context` untuk InheritedWidget di sini — belum siap.
  /// [addPostFrameCallback] menunggu frame pertama selesai, baru [_boot].
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  /// [Future.wait] menjalankan delay (biar splash sempat terlihat) dan
  /// [restore] token secara bersamaan. [mounted] wajib dicek setelah await:
  /// user mungkin sudah pindah halaman.
  Future<void> _boot() async {
    final session = SessionScope.read(context);
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1200)),
      session.restore(),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => session.isLoggedIn ? const HomeShell() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: AppColors.softShadow(0.4),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'findlove',
                    style: GoogleFonts.pacifico(fontSize: 42, color: AppColors.primaryDeep, height: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temukan cinta sejatimu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
