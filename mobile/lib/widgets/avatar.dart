import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'net_image.dart';

/// Foto profil bulat. [ClipOval] memotong gambar jadi lingkaran.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.url,
    this.size = 52,
    this.online = false,
    this.ring = false,
  });

  final String url;
  final double size;
  final bool online;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(child: SizedBox.square(dimension: size, child: NetImage(url)));

    final framed = ring
        ? Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: image,
            ),
          )
        : image;

    if (!online) return framed;

    final dot = size * 0.26;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        framed,
        Positioned(
          right: ring ? 4 : 1,
          bottom: ring ? 4 : 1,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: AppColors.online,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }
}
