import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Gambar dari internet. URL kosong / gagal → placeholder, bukan error merah.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const _Placeholder(loading: false);
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _Placeholder(loading: true);
      },
      errorBuilder: (context, error, stack) => const _Placeholder(loading: false),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blushDeep, AppColors.primarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.person_rounded, color: Colors.white, size: 48),
    );
  }
}
