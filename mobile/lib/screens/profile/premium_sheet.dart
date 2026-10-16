import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pressable.dart';

/// Bottom sheet paket premium. [isScrollControlled] biar tingginya bisa lebih dari 50% layar.
Future<void> showPremiumSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PremiumSheet(),
  );
}

class _Plan {
  const _Plan(this.name, this.price, this.period, this.tag);
  final String name;
  final String price;
  final String period;
  final String? tag;
}

class _PremiumSheet extends StatefulWidget {
  const _PremiumSheet();

  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  int _selected = 1;

  static const _plans = [
    _Plan('1 bulan', 'Rp49.000', '/ bulan', null),
    _Plan('3 bulan', 'Rp43.000', '/ bulan', 'Populer'),
    _Plan('12 bulan', 'Rp33.250', '/ bulan', 'Hemat'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 22),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(gradient: AppColors.premiumGradient, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            Text('Klik Plus', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Like tanpa batas, lihat siapa yang menyukaimu, dan Super Like setiap hari.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.inkSoft, height: 1.45),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < _plans.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _PlanTile(
                plan: _plans[i],
                selected: _selected == i,
                onTap: () => setState(() => _selected = i),
              ),
            ],
            const SizedBox(height: 22),
            GradientButton(
              label: 'Lanjutkan',
              icon: Icons.favorite_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Paket ${_plans[_selected].name} menunggu integrasi pembayaran')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blush : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? AppColors.primaryGradient : null,
                border: selected ? null : Border.all(color: AppColors.line, width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (plan.tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(plan.tag!,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  Text(plan.period, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ],
              ),
            ),
            Text(plan.price, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDeep)),
          ],
        ),
      ),
    );
  }
}
