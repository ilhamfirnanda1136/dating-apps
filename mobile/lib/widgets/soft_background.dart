import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar gradasi putih-pink dengan dua "blob" blur di sudut.
/// [StatelessWidget] cukup: tidak ada state, hanya susunan widget.
class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: [
          const Positioned(top: -90, right: -70, child: _Blob(size: 240, color: Color(0x33FF4F8B))),
          const Positioned(bottom: 80, left: -110, child: _Blob(size: 260, color: Color(0x26FF9EC2))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Underscore `_Blob` = privat untuk file ini, tidak bisa diimport file lain.
class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
