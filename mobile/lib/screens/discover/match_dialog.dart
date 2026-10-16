import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/net_image.dart';
import '../../widgets/pressable.dart';

/// Dialog "It's a Match!". [showGeneralDialog] = overlay custom (bukan AlertDialog).
/// Hasil: `true` = buka chat, `false`/`null` = tutup saja.
Future<bool?> showMatchDialog(BuildContext context, {required UserProfile me, required UserProfile other}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, _, _) => _MatchView(me: me, other: other),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _MatchView extends StatelessWidget {
  const _MatchView({required this.me, required this.other});

  final UserProfile me;
  final UserProfile other;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF2FF7EB0), Color(0xF2FF4F8B), Color(0xF2C04BFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  "It's a Match!",
                  style: GoogleFonts.pacifico(fontSize: 46, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kamu dan ${other.name} saling menyukai.\nJangan biarkan momen ini lewat 💕',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.5),
                ),
                const SizedBox(height: 44),
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(left: 24, child: _Photo(url: me.avatar, angle: -0.16)),
                      Positioned(right: 24, child: _Photo(url: other.avatar, angle: 0.16)),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20),
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 34),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Pressable(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    height: 58,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(29),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('Kirim pesan',
                            style: text.titleMedium?.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Pressable(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    height: 58,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(29),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text('Lanjut swipe',
                        style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.angle});

  final String url;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 140,
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(21), child: NetImage(url)),
      ),
    );
  }
}
