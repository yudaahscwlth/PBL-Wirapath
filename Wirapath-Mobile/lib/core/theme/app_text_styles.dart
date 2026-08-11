import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Shared text styles.
///
/// IMPORTANT: heading/body/label styles intentionally DO NOT set a `color`.
/// Leaving the color null lets each `Text` inherit the ambient theme color
/// (`colorScheme.onSurface`), so the same style renders dark text in light
/// mode and light text in dark mode automatically. Only styles that must be a
/// fixed color regardless of theme (button text, links, brand) set one.
class AppTextStyles {
  AppTextStyles._();

  // Headings — color inherited from theme (onSurface).
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Body — color inherited from theme (onSurface). Add `.copyWith(color:
  // onSurface.withOpacity(0.6))` at call sites that want secondary/muted text.
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Button — fixed white (sits on the primary-blue button background).
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // Label — color inherited from theme.
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Hint — muted gray that reads acceptably on both light and dark surfaces.
  static TextStyle hint = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // Link — fixed brand blue.
  static TextStyle link = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
  );

  // Brand name on splash — fixed brand color.
  static TextStyle brandName = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
    letterSpacing: 1.0,
  );
}
