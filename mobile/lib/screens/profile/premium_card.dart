import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import 'premium_sheet.dart';

/// Kartu ajakan FindLove Plus. Tap membuka [showPremiumSheet].
class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, this.compact = false, this.isPro = false});

  final bool compact;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.softShadow(0.35),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Icon(Icons.favorite_rounded, size: 140, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          isPro ? 'FindLove Plus Aktif ✨' : 'FindLove Plus',
                          style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPro
                          ? (compact
                              ? 'Fitur Pro aktif: Auto-match saat swipe like & tanpa batas.'
                              : 'Status Pro aktif! Auto-match otomatis saat kamu swipe like, like tanpa batas, & 5 Super Like per hari.')
                          : (compact
                              ? 'Lihat siapa saja yang menyukaimu dan langsung match.'
                              : 'Like tanpa batas, lihat siapa yang suka kamu, dan 5 Super Like setiap hari.'),
                      style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.45),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 14),
                      Text(
                        isPro ? 'Langganan Aktif (1 Tahun)' : 'Mulai Rp49.000 / bulan',
                        style: text.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Pressable(
                onTap: () => showPremiumSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPro) ...[
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isPro ? 'Aktif' : 'Upgrade',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
