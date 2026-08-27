import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0A2A43);
  static const Color primaryLight = Color(0xFF0C4A6E);
  static const Color primaryDark = Color(0xFF081F33);

  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF1D4ED8);

  static const Color background = Color(0xFFF1F5F9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);

  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = accent;

  static const Color iconDark = Color(0xFF0F172A);
  static const Color iconLight = Color(0xFF64748B);

  static const Color shadow = Color(0x14000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0A2A43),
      Color(0xFF0C4A6E),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [
      Color(0xFF0A2A43),
      Color(0xFF0C4A6E),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
}