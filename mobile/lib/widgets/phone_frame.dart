import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Di browser desktop (lebar ≥ 600), bungkus app seperti layar HP.
/// Di HP sungguhan, [child] ditampilkan penuh tanpa bingkai.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const _width = 412.0;
  static const _maxHeight = 892.0;

  @override
  Widget build(BuildContext context) {
    // [MediaQuery] berisi ukuran layar, padding notch, dsb.
    final media = MediaQuery.of(context);
    if (media.size.width < 600) return child;

    final height = min(media.size.height - 48, _maxHeight);

    return ColoredBox(
      color: const Color(0xFFFCE8F0),
      child: Center(
        child: Container(
          width: _width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: Colors.white, width: 8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 60,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Stack(
              children: [
                MediaQuery(
                  data: media.copyWith(
                    size: Size(_width - 16, height - 16),
                    padding: const EdgeInsets.only(top: 18, bottom: 12),
                    viewPadding: const EdgeInsets.only(top: 18, bottom: 12),
                  ),
                  child: child,
                ),
                const Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF2A1621),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: SizedBox(width: 92, height: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
