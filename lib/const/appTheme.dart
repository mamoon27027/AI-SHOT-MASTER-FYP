import 'package:flutter/material.dart';

class AppColors {
  static const Color background     = Color(0xFF0F172A);
  static const Color surface        = Color(0xFF1E293B);
  static const Color inputBg        = Color(0xFF0F172A);
  static const Color accent         = Color(0xFF38BDF8); // sky blue
  static const Color accentGreen    = Color(0xFF84CC16); // lime green
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF94A3B8);
  static const Color textDim        = Color(0xFF64748B);
  static const Color border         = Color(0xFF38BDF8); // with opacity in use
  static const Color navBg          = Color(0xFF0F172A);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );

  static const TextStyle subheading = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 15,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle hint = TextStyle(
    color: AppColors.textDim,
    fontSize: 13,
  );

  static const TextStyle link = TextStyle(
    color: AppColors.accent,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

// Shared gradient background decoration
BoxDecoration get appBackgroundDecoration => const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
  ),
);