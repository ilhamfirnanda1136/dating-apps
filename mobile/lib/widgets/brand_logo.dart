import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo "findlove": ikon hati + teks ber-gradient via [ShaderMask].
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.3,
          height: size * 1.3,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.42),
            boxShadow: AppColors.softShadow(0.3),
          ),
          child: Icon(Icons.favorite_rounded, color: Colors.white, size: size * 0.78),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
          child: Text(
            'findlove',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
          ),
        ),
      ],
    );
  }
}
