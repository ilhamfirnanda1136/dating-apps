import 'package:flutter/material.dart';

import '../../state/session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/api_feedback.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/soft_background.dart';
import '../onboarding_screen.dart';

/// Pengaturan akun. Saat ini sebagian item masih "segera hadir" (toast).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget group(List<Widget> children) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow(0.06),
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64, color: AppColors.line),
                  children[i],
                ],
              ],
            ),
          ),
        );

    Widget tile(IconData icon, String label, {VoidCallback? onTap, Color color = AppColors.ink}) => ListTile(
          onTap: onTap ?? () => _toast(context, '$label segera hadir'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color == AppColors.ink ? AppColors.primary : color, size: 20),
          ),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
        );

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    size: 44,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Text('Pengaturan', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 24),
              group([
                tile(Icons.tune_rounded, 'Preferensi pencarian'),
                tile(Icons.block_rounded, 'Daftar blokir'),
                tile(Icons.lock_outline_rounded, 'Privasi & keamanan'),
                tile(Icons.notifications_active_outlined, 'Notifikasi'),
              ]),
              const SizedBox(height: 16),
              group([
                tile(Icons.help_outline_rounded, 'Bantuan'),
                tile(Icons.info_outline_rounded, 'Tentang Klik', onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Klik',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Aplikasi kencan online — UI preview.',
                  );
                }),
              ]),
              const SizedBox(height: 16),
              group([
                tile(
                  Icons.logout_rounded,
                  'Keluar',
                  color: AppColors.primaryDeep,
                  onTap: () async {
                    try {
                      await SessionScope.read(context).logout();
                    } catch (error) {
                      if (context.mounted) showApiError(context, error);
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      (_) => false,
                    );
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
