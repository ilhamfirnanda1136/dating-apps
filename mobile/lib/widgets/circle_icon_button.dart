import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// Tombol ikon bundar (back, filter, notifikasi).
/// [dot] = titik merah kecil di sudut, biasanya untuk badge.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dot = false,
    this.size = 46,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.36),
          boxShadow: AppColors.softShadow(0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: size * 0.48),
            if (dot)
              Positioned(
                top: size * 0.24,
                right: size * 0.26,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
