import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// The look-and-feel follows the "Focus & Flow" design system, inspired
/// by Notion, Quizlet, Linear and Things 3:
///
/// - Calm slate background (almost pure white in light mode, deep
///   charcoal in dark mode).
/// - Indigo brand primary (premium, trustworthy, knowledge-coded).
/// - Vivid violet for highlight gradients.
/// - Emerald success accent for streaks, progress and "completed".
/// - Amber accent reserved for the streak flame only.
/// - No glassmorphism. Solid surfaces, hairline borders, very soft
///   single-layer shadows. Generous spacing.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Brand colours ──────────────────────────

  /// Brand primary — deep indigo. The single colour everything else
  /// is calibrated against.
  static const Color primary = Color(0xFF4F46E5); // indigo-600

  /// Top stop of the primary gradient (vivid indigo).
  static const Color goldStart = Color(0xFF6366F1); // indigo-500

  /// Bottom stop of the primary gradient (vivid violet).
  static const Color goldEnd = Color(0xFF8B5CF6); // violet-500

  /// Soft fixed indigo (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFE0E7FF); // indigo-100

  /// Brighter brand tone used for highlights.
  static const Color primaryFixedDim = Color(0xFFA5B4FC); // indigo-300

  /// Secondary accent — emerald (used for success, streaks, progress).
  static const Color secondary = Color(0xFF059669); // emerald-600

  /// Warm streak amber (reserved for the flame icon only).
  static const Color streakAmber = Color(0xFFF59E0B); // amber-500

  /// Tertiary — sky blue used for analytics / data viz only.
  static const Color tertiary = Color(0xFF0284C7); // sky-600

  static const Color tertiaryContainer = Color(0xFFBAE6FD); // sky-200

  /// App background — soft slate (off-white that's calmer than pure
  /// white on OLED screens).
  static const Color background = Color(0xFFF8FAFC); // slate-50

  /// Pure white card surface.
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9); // slate-100
  static const Color surfaceContainer = Color(0xFFE2E8F0); // slate-200
  static const Color surfaceContainerHigh = Color(0xFFCBD5E1); // slate-300

  /// Primary text on light surfaces (slate-900).
  static const Color onBackground = Color(0xFF0F172A);

  /// Muted on-surface variant (slate-500).
  static const Color onSurfaceVariant = Color(0xFF64748B);

  /// Hairline outline used around cards and inputs.
  static const Color outline = Color(0xFFCBD5E1); // slate-300
  static const Color outlineVariant = Color(0xFFE2E8F0); // slate-200

  static const Color error = Color(0xFFDC2626); // red-600
  static const Color errorContainer = Color(0xFFFEE2E2); // red-100

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixed,
      onPrimaryContainer: Color(0xFF312E81),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: Color(0xFF064E3B),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF075985),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF7F1D1D),
      surface: background,
      onSurface: onBackground,
      surfaceContainerLowest: surfaceCardLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: Color(0xFFB6C2D1),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF0F172A),
      scrim: Color(0xFF0F172A),
      inverseSurface: Color(0xFF1E293B),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: primaryFixedDim,
      surfaceTint: primary,
    );
    return _buildTheme(scheme: scheme);
  }

  /// Dark mode reuses the same indigo accent system over a deep slate
  /// canvas so the brand stays consistent without feeling oppressive.
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF818CF8), // indigo-400 (lighter for contrast)
      onPrimary: Color(0xFF1E1B4B),
      primaryContainer: Color(0xFF3730A3),
      onPrimaryContainer: Color(0xFFE0E7FF),
      secondary: Color(0xFF34D399), // emerald-400
      onSecondary: Color(0xFF064E3B),
      secondaryContainer: Color(0xFF065F46),
      onSecondaryContainer: Color(0xFFD1FAE5),
      tertiary: Color(0xFF38BDF8),
      onTertiary: Color(0xFF075985),
      tertiaryContainer: Color(0xFF0369A1),
      onTertiaryContainer: Color(0xFFBAE6FD),
      error: Color(0xFFF87171),
      onError: Color(0xFF7F1D1D),
      errorContainer: Color(0xFF991B1B),
      onErrorContainer: Color(0xFFFECACA),
      surface: Color(0xFF0B1220), // very deep slate
      onSurface: Color(0xFFE2E8F0),
      surfaceContainerLowest: Color(0xFF050810),
      surfaceContainerLow: Color(0xFF111827),
      surfaceContainer: Color(0xFF1E293B),
      surfaceContainerHigh: Color(0xFF334155),
      surfaceContainerHighest: Color(0xFF475569),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1E293B),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF1F5F9),
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: primary,
      surfaceTint: Color(0xFF818CF8),
    );
    return _buildTheme(scheme: scheme);
  }

  static ThemeData _buildTheme({required ColorScheme scheme}) {
    final bool isLight = scheme.brightness == Brightness.light;
    final Color card = scheme.surfaceContainerLowest;
    final Color hairline = isLight
        ? const Color(0xFFE2E8F0) // slate-200
        : const Color(0xFF1E293B);
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
              ? const Color(0x0A0F172A) // slate-900 @ 4%
              : const Color(0x99000000),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      goldGlow: <BoxShadow>[
        BoxShadow(
          color: scheme.primary.withOpacity(0.22),
          blurRadius: 28,
          offset: const Offset(0, 12),
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
