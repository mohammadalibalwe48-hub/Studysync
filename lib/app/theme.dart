import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// The look-and-feel follows the "Sunlit Gold" design system pulled
/// from the Educational Steps Platform logo (orange/yellow gradient
/// over stacked books):
///
/// - Warm cream canvas (a soft, low-glare off-white in light mode,
///   deep walnut in dark mode) — easy on the eyes during long study
///   sessions, never neon.
/// - Saffron gold brand primary (premium, optimistic, knowledge-coded).
/// - Sunset orange highlight gradient that mirrors the logo gradient.
/// - Honey amber success accent for streaks, progress and "completed".
/// - Mocha tertiary for analytics / data viz so charts stay readable.
/// - Solid surfaces, hairline borders, very soft single-layer shadows,
///   generous spacing. Subtle warm glow only behind hero CTAs.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Brand colours ──────────────────────────

  /// Brand primary — deep saffron gold. Calibrated to be readable as a
  /// fill colour on white surfaces (~4.5:1 against text white).
  static const Color primary = Color(0xFFD68A1A); // saffron-700

  /// Top stop of the hero gradient — warm honey gold.
  static const Color goldStart = Color(0xFFF5B544); // honey-400

  /// Bottom stop of the hero gradient — sunset orange.
  static const Color goldEnd = Color(0xFFE2862F); // sunset-600

  /// Soft fixed honey (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFFFEFCF); // cream-100

  /// Brighter brand tone used for highlights / dark-mode primary.
  static const Color primaryFixedDim = Color(0xFFF6C66B); // honey-300

  /// Secondary accent — clay rose (used for success, streaks, progress).
  /// A muted earthy warm tone that pairs cleanly with saffron without
  /// fighting it for attention.
  static const Color secondary = Color(0xFFC9602B); // clay-600

  /// Warm streak flame (reserved for the streak flame and CTA glow).
  static const Color streakAmber = Color(0xFFEF8E2A); // flame-500

  /// Tertiary — mocha brown for analytics / data viz / chart bars.
  static const Color tertiary = Color(0xFF8C5A38); // mocha-600

  static const Color tertiaryContainer = Color(0xFFF1DFC9); // mocha-100

  /// App background — warm cream (off-white with a hint of gold). Stays
  /// far from pure white so the gold accents don't blow out, and stays
  /// far from neon so it's gentle on the eyes during long sessions.
  static const Color background = Color(0xFFFFFAF1); // cream-50

  /// Pure white card surface (still warm-tinted).
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF6E6); // cream-100
  static const Color surfaceContainer = Color(0xFFFAEFD8); // cream-200
  static const Color surfaceContainerHigh = Color(0xFFF1E2C2); // cream-300

  /// Primary text on light surfaces — deep walnut (instead of slate-900
  /// which would feel cold against the warm cream background).
  static const Color onBackground = Color(0xFF2A1F12);

  /// Muted on-surface variant — soft mocha grey.
  static const Color onSurfaceVariant = Color(0xFF7A6754);

  /// Hairline outline used around cards and inputs (warm sand).
  static const Color outline = Color(0xFFEFE3CD); // sand-200
  static const Color outlineVariant = Color(0xFFF7EDDA); // sand-100

  static const Color error = Color(0xFFB23B1F); // burnt-clay-600 (warm red)
  static const Color errorContainer = Color(0xFFFADCD2); // burnt-clay-100

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixed,
      onPrimaryContainer: Color(0xFF5B3A0A), // dark gold
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFADAB7), // clay-100
      onSecondaryContainer: Color(0xFF5C2A0E),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF3F2715),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF5B1D0E),
      surface: background,
      onSurface: onBackground,
      surfaceContainerLowest: surfaceCardLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: Color(0xFFE6D4B2),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF2A1F12),
      scrim: Color(0xFF2A1F12),
      inverseSurface: Color(0xFF2D2317),
      onInverseSurface: Color(0xFFFFF6E6),
      inversePrimary: primaryFixedDim,
      surfaceTint: primary,
    );
    return _buildTheme(scheme: scheme);
  }

  /// Dark mode reuses the same gold accent system over a deep walnut
  /// canvas so the brand stays consistent without feeling oppressive.
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFF5C56C), // honey-300 (brighter for contrast)
      onPrimary: Color(0xFF2C1B05),
      primaryContainer: Color(0xFF6E460E),
      onPrimaryContainer: Color(0xFFFFE7BD),
      secondary: Color(0xFFE6925E), // clay-300
      onSecondary: Color(0xFF3A1808),
      secondaryContainer: Color(0xFF6B361A),
      onSecondaryContainer: Color(0xFFFADAB7),
      tertiary: Color(0xFFD9A678), // mocha-300
      onTertiary: Color(0xFF2A1A0B),
      tertiaryContainer: Color(0xFF563620),
      onTertiaryContainer: Color(0xFFF1DFC9),
      error: Color(0xFFE89A82),
      onError: Color(0xFF4A150A),
      errorContainer: Color(0xFF7C2613),
      onErrorContainer: Color(0xFFFADCD2),
      surface: Color(0xFF1A130A), // deep walnut
      onSurface: Color(0xFFF6E9D2),
      surfaceContainerLowest: Color(0xFF120D06),
      surfaceContainerLow: Color(0xFF221808),
      surfaceContainer: Color(0xFF2A1F0F),
      surfaceContainerHigh: Color(0xFF3A2B17),
      surfaceContainerHighest: Color(0xFF4A3621),
      onSurfaceVariant: Color(0xFFC4AE8E),
      outline: Color(0xFF3A2B17),
      outlineVariant: Color(0xFF2A1F0F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF6E9D2),
      onInverseSurface: Color(0xFF1A130A),
      inversePrimary: primary,
      surfaceTint: Color(0xFFF5C56C),
    );
    return _buildTheme(scheme: scheme);
  }

  static ThemeData _buildTheme({required ColorScheme scheme}) {
    final bool isLight = scheme.brightness == Brightness.light;
    final Color card = scheme.surfaceContainerLowest;
    final Color hairline = isLight
        ? const Color(0xFFEFE3CD) // sand-200
        : const Color(0xFF3A2B17); // walnut-300
    final Color muted = scheme.onSurfaceVariant;
    final Color appBg = scheme.surface;

    final TextTheme baseText =
        ThemeData(brightness: scheme.brightness).textTheme;
    // Cairo is the body/display font so Arabic glyphs render
    // beautifully across the entire app while keeping Latin numerals
    // crisp inside maths and option labels.
    final TextTheme cairo = GoogleFonts.cairoTextTheme(baseText)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          displayLarge: GoogleFonts.cairo(
            fontSize: 34,
            height: 42 / 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: scheme.onSurface,
          ),
          displayMedium: GoogleFonts.cairo(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
          headlineLarge: GoogleFonts.cairo(
            fontSize: 26,
            height: 34 / 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          headlineMedium: GoogleFonts.cairo(
            fontSize: 22,
            height: 30 / 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
          headlineSmall: GoogleFonts.cairo(
            fontSize: 19,
            height: 26 / 19,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleLarge: GoogleFonts.cairo(
            fontSize: 17,
            height: 24 / 17,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleMedium: GoogleFonts.cairo(
            fontSize: 15,
            height: 22 / 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          titleSmall: GoogleFonts.cairo(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          bodyLarge: GoogleFonts.cairo(
            fontSize: 16,
            height: 26 / 16,
            color: scheme.onSurface,
          ),
          bodyMedium: GoogleFonts.cairo(
            fontSize: 14,
            height: 22 / 14,
            color: scheme.onSurface,
          ),
          bodySmall: GoogleFonts.cairo(
            fontSize: 12,
            height: 18 / 12,
            color: muted,
          ),
          labelLarge: GoogleFonts.cairo(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          labelMedium: GoogleFonts.cairo(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
          labelSmall: GoogleFonts.cairo(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: muted,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: appBg,
      canvasColor: appBg,
      textTheme: cairo,
      appBarTheme: AppBarTheme(
        backgroundColor: appBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: cairo.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: hairline, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: muted,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: cairo.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: cairo.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: hairline, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: cairo.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: cairo.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: hairline, width: 1),
        labelStyle: cairo.labelMedium,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
        circularTrackColor: scheme.surfaceContainer,
      ),
    );
  }
}

/// Convenience accessor that maps the active [ThemeData] / [ColorScheme]
/// onto a small named palette of design-system tokens used throughout
/// the app.
///
/// Pulling these from the theme (instead of the static [AppTheme]
/// constants) means the palette automatically inverts in dark mode.
class AppPalette {
  const AppPalette({
    required this.gold,
    required this.warm,
    required this.accent,
    required this.muted,
    required this.outline,
    required this.card,
    required this.champagne,
    required this.cardShadow,
    required this.goldGradient,
    required this.info,
    required this.goldGlow,
    required this.success,
  });

  /// Primary brand colour (indigo). Named `gold` for backwards-compat.
  final Color gold;

  /// Streak amber — used for the flame icon only.
  final Color warm;

  /// Action / focus tone (matches [primary]).
  final Color accent;

  final Color muted;
  final Color outline;
  final Color card;

  /// Soft surface colour used for chips and inert pill backgrounds.
  /// Named `champagne` for backwards-compat.
  final Color champagne;

  final List<BoxShadow> cardShadow;

  /// Indigo → violet brand gradient used on hero CTAs.
  /// Named `goldGradient` for backwards-compat.
  final LinearGradient goldGradient;

  /// Sky blue used for analytics / informational chips.
  final Color info;

  /// Soft glow shadow used behind hero CTAs and ring stats.
  final List<BoxShadow> goldGlow;

  /// Emerald success tone (streak / completed / right answer).
  final Color success;

  /// Build a palette from the active theme. Prefer this in widgets so
  /// dark/light mode flips automatically.
  static AppPalette of(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;
    return AppPalette(
      gold: scheme.primary,
      warm: AppTheme.streakAmber,
      accent: scheme.primary,
      muted: scheme.onSurfaceVariant,
      outline: scheme.outline,
      card: scheme.surfaceContainerLowest,
      champagne: scheme.surfaceContainerLow,
      info: scheme.tertiary,
      success: scheme.secondary,
      cardShadow: <BoxShadow>[
        BoxShadow(
          color: isLight
              ? const Color(0x142A1F12) // walnut @ 8%
              : const Color(0x99000000),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      goldGlow: <BoxShadow>[
        BoxShadow(
          color: const Color(0xFFE89D2A).withOpacity(0.32),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ],
      goldGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[AppTheme.goldStart, AppTheme.goldEnd],
      ),
    );
  }
}
