import 'package:flutter/material.dart';

/// Curated color palette for Scale Finder.
///
/// Uses deep blues and purples for the dark theme with vibrant accents
/// for interactive elements and musical visualizations.
class AppColors {
  AppColors._();

  // ─── Primary Palette ────────────────────────────────────────
  static const primary = Color(0xFF6C63FF);        // Vibrant purple
  static const primaryLight = Color(0xFF9D97FF);
  static const primaryDark = Color(0xFF4A43D4);

  // ─── Secondary / Accent ─────────────────────────────────────
  static const accent = Color(0xFF00D9FF);          // Cyan accent
  static const accentLight = Color(0xFF66E8FF);
  static const accentDark = Color(0xFF00A3BF);

  // ─── Background (Dark Theme) ────────────────────────────────
  static const backgroundDark = Color(0xFF0D0D1A);
  static const surfaceDark = Color(0xFF1A1A2E);
  static const surfaceElevatedDark = Color(0xFF252540);
  static const surfaceHighDark = Color(0xFF30305A);

  // ─── Background (Light Theme) ───────────────────────────────
  static const backgroundLight = Color(0xFFF5F5FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFF0F0F8);

  // ─── Text ───────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFE8E8F0);
  static const textSecondaryDark = Color(0xFF9898B0);
  static const textTertiaryDark = Color(0xFF6868A0);

  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF505070);

  // ─── Semantic Colors ────────────────────────────────────────
  static const success = Color(0xFF00D68F);
  static const warning = Color(0xFFFFAA00);
  static const error = Color(0xFFFF4D6A);

  // ─── Musical Colors (for piano/fretboard) ───────────────────
  static const noteActive = Color(0xFF6C63FF);
  static const noteHighlight = Color(0xFF00D9FF);
  static const noteRoot = Color(0xFFFF6B8A);
  static const pianoWhiteKey = Color(0xFFF5F5F5);
  static const pianoBlackKey = Color(0xFF1A1A2E);
  static const pianoWhiteKeyActive = Color(0xFFB8B3FF);
  static const pianoBlackKeyActive = Color(0xFF6C63FF);

  // ─── Confidence Colors ──────────────────────────────────────
  static const confidenceHigh = Color(0xFF00D68F);    // >= 80%
  static const confidenceMedium = Color(0xFFFFAA00);  // >= 50%
  static const confidenceLow = Color(0xFFFF4D6A);     // < 50%

  // ─── Gradients ──────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF8B5CF6)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF0066FF)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceDark, backgroundDark],
  );

  /// Get confidence color based on score.
  static Color confidenceColor(double confidence) {
    if (confidence >= 0.8) return confidenceHigh;
    if (confidence >= 0.5) return confidenceMedium;
    return confidenceLow;
  }
}
