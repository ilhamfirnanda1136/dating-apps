import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_button.dart';

/// Halaman kosong yang rapi: ikon, judul, penjelasan, tombol opsional.
/// Dipakai Discover/Likes/Chat/Notifikasi saat database belum ada datanya.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow(0.28),
              ),
              child: Icon(icon, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 22),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.inkSoft, height: 1.5),
            ),
            if (child != null) ...[const SizedBox(height: 22), child!],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 220,
                child: GradientButton(label: actionLabel!, height: 50, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
