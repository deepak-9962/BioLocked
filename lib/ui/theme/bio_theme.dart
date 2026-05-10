import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bio-Locked Design System
/// Extracted from the reference HTML/Tailwind design spec.
///
/// Color palette from the Material 3 custom theme used in the HTML mockups.
/// Typography uses Space Grotesk for headlines/stats and Inter for body.

class BioColors {
  // ─── Primary ──────────────────────────────────────────────────────────────
  static const Color primaryFixed = Color(0xFFC3F400);      // Electric lime
  static const Color primaryFixedDim = Color(0xFFABD600);
  static const Color onPrimaryFixed = Color(0xFF161E00);
  static const Color onPrimaryContainer = Color(0xFF556D00);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF283500);

  // ─── Surface & Background ─────────────────────────────────────────────────
  static const Color background = Color(0xFF121317);
  static const Color surface = Color(0xFF121317);
  static const Color surfaceDim = Color(0xFF121317);
  static const Color surfaceContainerLowest = Color(0xFF0D0E12);
  static const Color surfaceContainerLow = Color(0xFF1A1B1F);
  static const Color surfaceContainer = Color(0xFF1E1F23);
  static const Color surfaceContainerHigh = Color(0xFF292A2E);
  static const Color surfaceContainerHighest = Color(0xFF343539);
  static const Color surfaceBright = Color(0xFF38393D);

  // ─── Card backgrounds (from the <style> overrides in the HTML) ────────────
  static const Color cardBg = Color(0xFF121212);
  static const Color cardBorder = Color(0xFF2C2C2E);
  static const Color innerBg = Color(0xFF1A1A1A);

  // ─── On-Surface ───────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE3E2E7);
  static const Color onSurfaceVariant = Color(0xFFC4C9AC);
  static const Color onBackground = Color(0xFFE3E2E7);

  // ─── Outline ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8E9379);
  static const Color outlineVariant = Color(0xFF444933);

  // ─── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFC8C6C5);
  static const Color secondaryContainer = Color(0xFF474746);
  static const Color onSecondary = Color(0xFF313030);

  // ─── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);

  // ─── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFD8E2FF);

  // ─── Accent colors used in specific UI elements ───────────────────────────
  static const Color orange500 = Color(0xFFFF9800);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color purple500 = Color(0xFF9C27B0);
  static const Color yellow500 = Color(0xFFFFEB3B);
  static const Color red500 = Color(0xFFEF5350);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);
  static const Color red900 = Color(0xFFB71C1C);
}

class BioTextStyles {
  // headline-xl: Space Grotesk 40/48 -0.02em 700
  static TextStyle headlineXl = GoogleFonts.spaceGrotesk(
    fontSize: 40,
    height: 48 / 40,
    letterSpacing: -0.8, // -0.02em
    fontWeight: FontWeight.w700,
    color: BioColors.onSurface,
  );

  // headline-lg: Space Grotesk 32/40 600
  static TextStyle headlineLg = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
    color: BioColors.onSurface,
  );

  // stat-display: Space Grotesk 48/52 700
  static TextStyle statDisplay = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w700,
    color: BioColors.onSurface,
  );

  // body-lg: Inter 18/28 400
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w400,
    color: BioColors.onSurface,
  );

  // body-md: Inter 16/24 400
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: BioColors.onSurface,
  );

  // label-caps: Inter 12/16 0.1em 600
  static TextStyle labelCaps = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 1.2, // 0.1em
    fontWeight: FontWeight.w600,
    color: BioColors.onSurface,
  );
}

/// Spacing constants matching the HTML design tokens.
class BioSpacing {
  static const double marginMain = 24;   // 1.5rem
  static const double gutterCard = 16;   // 1rem
  static const double stackGap = 32;     // 2rem
  static const double sectionPadding = 40; // 2.5rem
}

/// Decoration helpers matching `card-bg` and `inner-bg` CSS classes.
class BioDecorations {
  static BoxDecoration cardBg({double borderRadius = 8}) => BoxDecoration(
    color: BioColors.cardBg,
    border: Border.all(color: BioColors.cardBorder),
    borderRadius: BorderRadius.circular(borderRadius),
  );

  static BoxDecoration innerBg({double borderRadius = 8, Color? borderColor}) => BoxDecoration(
    color: BioColors.innerBg,
    border: Border.all(color: borderColor ?? BioColors.cardBorder),
    borderRadius: BorderRadius.circular(borderRadius),
  );
}

/// Build the app-level ThemeData to match the Bio-Locked reference design.
ThemeData buildBioTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BioColors.background,
    primaryColor: BioColors.primaryFixed,
    useMaterial3: true,
    textTheme: baseTextTheme.apply(
      bodyColor: BioColors.onSurface,
      displayColor: BioColors.onSurface,
    ),
    colorScheme: const ColorScheme.dark(
      primary: BioColors.primaryFixed,
      onPrimary: BioColors.onPrimaryFixed,
      secondary: BioColors.secondary,
      onSecondary: BioColors.onSecondary,
      surface: BioColors.surface,
      onSurface: BioColors.onSurface,
      error: BioColors.error,
      onError: BioColors.onError,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: BioColors.primaryFixed,
      inactiveTrackColor: BioColors.cardBorder,
      thumbColor: BioColors.primaryFixed,
      overlayColor: BioColors.primaryFixed.withValues(alpha: 0.12),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return BioColors.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return BioColors.primaryFixed;
        return BioColors.cardBorder;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BioColors.innerBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BioColors.cardBorder),
        ),
      ),
    ),
  );
}
