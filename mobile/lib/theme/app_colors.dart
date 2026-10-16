import 'package:flutter/material.dart';

/// Palet warna aplikasi. Konstruktor privat = dipakai sebagai namespace statis,
/// bukan di-instance: `AppColors.primary` bukan `AppColors()`.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFFF4F8B);
  static const primaryDeep = Color(0xFFE8336F);
  static const primarySoft = Color(0xFFFFB8CF);

  static const blush = Color(0xFFFFF5F8);
  static const blushDeep = Color(0xFFFFE6EF);
  static const surface = Colors.white;

  static const ink = Color(0xFF2A1621);
  static const inkSoft = Color(0xFF8C7381);
  static const line = Color(0xFFF7DDE7);

  static const online = Color(0xFF2ED47A);
  static const superLike = Color(0xFF7C6CFF);
  static const gold = Color(0xFFFFB547);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF85B3), Color(0xFFFF4F8B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFBFD), Color(0xFFFFEEF4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const premiumGradient = LinearGradient(
    colors: [Color(0xFFFF8FB8), Color(0xFFFF4F8B), Color(0xFFB45CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bayangan pink lembut. [withValues] menggantikan `withOpacity` yang deprecated.
  static List<BoxShadow> softShadow([double opacity = 0.12]) => [
        BoxShadow(
          color: primary.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}
