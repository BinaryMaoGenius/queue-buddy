import 'package:flutter/material.dart';

class AppColors {
  // SIRA Premium Design System - Emerald & Gold
  static const Color primary = Color(0xFF064E3B); // Deepest Emerald
  static const Color primaryVibrant = Color(0xFF059669); // Radiant Emerald
  static const Color primaryGlow = Color(0xFF10B981);
  static const Color primarySubtle = Color(0xFFECFDF5);

  static const Color background = Color(0xFFF1F5F9); // Lighter Slate for contrast
  static const Color foreground = Color(0xFF0F172A); // Midnight Slate

  // Glassmorphism System
  static const Color glassBase = Color(0x99FFFFFF); // 60% White
  static const Color glassBorder = Color(0x33FFFFFF); // 20% White
  static const Color cardShadow = Color(0x0A000000); // Very subtle
  
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  
  static const Color accent = Color(0xFFD97706); // Refined Amber/Gold
  static const Color accentSubtle = Color(0xFFFFF7ED);

  static const Color statusOk = Color(0xFF10B981);
  static const Color statusWarn = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);

  static const Color secondary = Color(0xFFF8FAFC);
  static const Color mutedForeground = Color(0xFF64748B);

  // Premium Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF064E3B), // Deepest Emerald
      Color(0xFF065F46), // Dark Emerald
      Color(0xFF059669), // Radiant Emerald
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCCFFFFFF),
      Color(0x66FFFFFF),
    ],
  );
}
