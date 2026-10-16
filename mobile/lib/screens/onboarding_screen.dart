import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../widgets/gradient_button.dart';
import '../widgets/soft_background.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

/// Selamat datang: dua tombol → Daftar atau Masuk.
/// [Navigator.push] menumpuk halaman baru di atas stack.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const BrandLogo(),
                const Expanded(child: _HeroArt()),
                Text(
                  'Temukan seseorang yang benar-benar klik',
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Swipe, match, lalu ngobrol dengan orang nyata dari komunitas Klik.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.inkSoft, height: 1.5),
                ),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Buat akun',
                  icon: Icons.favorite_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                OutlineSoftButton(
                  label: 'Saya sudah punya akun',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dengan melanjutkan, kamu menyetujui Syarat & Kebijakan Privasi kami.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    Widget card(IconData icon, double angle, Color color) => Transform.rotate(
          angle: angle,
          child: Container(
            width: 150,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 5),
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.85), color]),
              boxShadow: AppColors.softShadow(0.25),
            ),
            child: Icon(icon, color: Colors.white, size: 54),
          ),
        );

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(left: 8, child: card(Icons.photo_camera_rounded, -0.14, const Color(0xFFFF8FB8))),
        Positioned(right: 8, child: card(Icons.chat_bubble_rounded, 0.14, const Color(0xFFFF6B9D))),
        card(Icons.favorite_rounded, 0, AppColors.primary),
      ],
    );
  }
}
