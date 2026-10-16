import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pressable.dart';

/// Tombol kembali auth. [maybePop] aman: tidak crash jika stack sudah habis.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
      ),
    );
  }
}

/// Pemisah "atau" di antara dua garis.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft)),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}

/// Placeholder Google/Apple (onPressed masih kosong).
class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlineSoftButton(
            label: 'Google',
            onPressed: () {},
            icon: const Text('G',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlineSoftButton(
            label: 'Apple',
            onPressed: () {},
            icon: const Icon(Icons.apple_rounded, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

/// Chip pilihan (gender, minat). [AnimatedContainer] mengisi warna saat selected.
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? Colors.transparent : AppColors.line),
          boxShadow: selected ? AppColors.softShadow(0.25) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: selected ? Colors.white : AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
