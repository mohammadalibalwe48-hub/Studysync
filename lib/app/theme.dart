import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// Palette is sampled directly from the app logo (vivid orange figure
/// reaching for yellow stars, on a stack of orange-gold books). The
/// dominant logo pixels cluster in the `#FF6B00 → #FF9500 → #FFD000`
/// range, with bright `#FFEF0E` highlights at the stars and
/// `#FD5C00` shadows at the bottom edge of the books.
///
/// The previous palette mapped the brand to a desaturated saffron
/// (`#D68A1A`) which read muddy next to the logo's actual energy. The
/// new tokens below stay 100% in the warm family but use the logo's
/// real saturated stops, so:
///
/// - The brand primary actually matches the logo orange instead of
///   reading as a faded vintage tan.
/// - The hero gradient mirrors the logo's top→bottom yellow→sunset
///   fade exactly (so a CTA gradient feels like the logo glowed).
/// - The cream canvas is cleaner / less yellow-cast, so the orange
///   accents pop instead of getting absorbed by the background.
/// - Text contrast deepens (deeper walnut on lighter canvas) so the
///   app feels crisper and more legible.
///
/// Hierarchy:
///
/// - [primary]/`sunOrange`: brand CTA, focused inputs, selected chips,
///   ring fills, primary icons.
/// - [secondary]/`sunsetEmber`: streaks, "completed/correct", success
///   badges, progress accents — same warm family but more intense, so
///   it reads as "heat/achievement" without leaving the brand.
/// - [tertiary]/`walnut`: data-viz / chart axes / muted analytics
///   colour. Stays warm, never competes with the orange.
/// - Surfaces step from `cream-25` (nearly white) up through warm
///   honey containers; outlines are tight warm sand.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Logo gradient ──────────────────────────

  /// Brightest yellow at the top of the logo (stars / arm tip).
  /// Sampled from the `#FFEF0E` star pixels and warmed slightly so it
  /// stays readable on white.
  static const Color sunYellow = Color(0xFFFFD000);

  /// The signature mid-orange of the figure & books — the most-common
  /// pixel colour in the logo by a wide margin (`#F09000` cluster).
  /// This is the brand.
  static const Color sunOrange = Color(0xFFFF9500);

  /// Deep sunset orange at the bottom edge of the books (`#FD5C00`),
  /// used for streaks, success and the gradient's bottom stop.
  static const Color sunset = Color(0xFFFF6B00);

  /// Three-stop gradient that mirrors the logo top→bottom fade.
  static const List<Color> heroGradient = <Color>[
    sunYellow,
    sunOrange,
    sunset,
  ];

  // Backwards-compat aliases. Existing widgets reference `goldStart` /
  // `goldEnd` / `streakAmber` / `primary` — keep the names so this PR
  // is a colour change only, not a sweeping rename.
  static const Color primary = sunOrange;
  static const Color goldStart = sunYellow;
  static const Color goldEnd = sunset;
  static const Color streakAmber = sunset;

  /// Soft fixed honey (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFFFE9C2); // honey-100

  /// Brighter brand tone used for highlights / dark-mode primary.
  static const Color primaryFixedDim = Color(0xFFFFB347); // honey-300

  /// Secondary accent — deeper sunset ember. Same gradient family as
  /// [sunOrange], just hotter / more intense, so streaks and success
  /// states read as "fire" without introducing a foreign hue.
  static const Color secondary = Color(0xFFE25A0D);

  static const Color secondaryContainer = Color(0xFFFFD8B8);

  /// Tertiary — deep walnut. Reserved for analytics / chart text /
  /// data viz axes. Stays in the warm family so it never fights the
  /// brand orange.
  static const Color tertiary = Color(0xFF6B3F1A); // walnut-700

  static const Color tertiaryContainer = Color(0xFFF1DFC3); // walnut-100

  /// App background — barely-tinted warm white. Far enough from pure
  /// white to keep the warm brand identity, but much cleaner than the
  /// previous `#FFFAF1` which had a yellow cast that absorbed the
  /// orange accents.
  static const Color background = Color(0xFFFFFCF6);

  /// Pure white card surface (still warm-feeling against the cream
  /// canvas behind it).
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF7E8); // honey-50
  static const Color surfaceContainer = Color(0xFFFFEED2); // honey-100
  static const Color surfaceContainerHigh = Color(0xFFFADDA8); // honey-200

  /// Primary text on light surfaces — deep walnut, deepened from the
  /// previous `#2A1F12` so headings and body copy feel sharper against
  /// the lighter canvas.
  static const Color onBackground = Color(0xFF1A1208);

  /// Muted on-surface variant — warm taupe.
  static const Color onSurfaceVariant = Color(0xFF6F5A3F);

  /// Hairline outline used around cards and inputs (warm sand).
  static const Color outline = Color(0xFFF0DDB6); // sand-200
  static const Color outlineVariant = Color(0xFFFAF1DC); // sand-100

  static const Color error = Color(0xFFC53030); // crimson-600
  static const Color errorContainer = Color(0xFFFFE0DA); // crimson-100

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixed,
      onPrimaryContainer: Color(0xFF5C2C00), // deep cocoa
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF5C2410),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF3A2415),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF5B1408),
      surface: background,
      onSurface: onBackground,
      surfaceContainerLowest: surfaceCardLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: Color(0xFFEBC57A),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF1A1208),
      scrim: Color(0xFF1A1208),
      inverseSurface: Color(0xFF2D1F0F),
      onInverseSurface: Color(0xFFFFF7E8),
      inversePrimary: primaryFixedDim,
      surfaceTint: primary,
    );
    return _buildTheme(scheme: scheme);
  }

  /// Dark mode reuses the same logo gradient over a deep walnut canvas
  /// so the brand stays consistent without feeling oppressive.
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFB347), // sun-orange-300 (brighter for contrast)
      onPrimary: Color(0xFF2C1605),
      primaryContainer: Color(0xFF7A3C00), // sun-orange-800
      onPrimaryContainer: Color(0xFFFFE5C2),
      secondary: Color(0xFFFF8A4A), // sunset-300
      onSecondary: Color(0xFF3A1408),
      secondaryContainer: Color(0xFF7A2E0A), // sunset-800
      onSecondaryContainer: Color(0xFFFFD8B8),
      tertiary: Color(0xFFD9A678), // walnut-300
      onTertiary: Color(0xFF2A1A0B),
      tertiaryContainer: Color(0xFF563620),
      onTertiaryContainer: Color(0xFFF1DFC3),
      error: Color(0xFFE89A82),
      onError: Color(0xFF4A150A),
      errorContainer: Color(0xFF7C2613),
      onErrorContainer: Color(0xFFFFE0DA),
      surface: Color(0xFF15110A), // deeper walnut for crisper contrast
      onSurface: Color(0xFFF6E9D2),
      surfaceContainerLowest: Color(0xFF0F0B05),
      surfaceContainerLow: Color(0xFF1F1708),
      surfaceContainer: Color(0xFF2A1F0F),
      surfaceContainerHigh: Color(0xFF3A2B17),
      surfaceContainerHighest: Color(0xFF4A3621),
      onSurfaceVariant: Color(0xFFC4AE8E),
      outline: Color(0xFF3A2B17),
      outlineVariant: Color(0xFF2A1F0F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF6E9D2),
      onInverseSurface: Color(0xFF15110A),
      inversePrimary: primary,
      surfaceTint: Color(0xFFFFB347),
    );
    return _buildTheme(scheme: scheme);
  }

  static ThemeData _buildTheme({required ColorScheme scheme}) {
    final bool isLight = scheme.brightness == Brightness.light;
    final Color card = scheme.surfaceContainerLowest;
    final Color hairline = isLight
        ? const Color(0xFFF0DDB6) // sand-200
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

  /// Primary brand colour — the logo's signature mid-orange.
  /// Named `gold` for backwards-compat with widgets predating this
  /// palette refresh.
  final Color gold;

  /// Streak / "hot" accent — the logo's deepest sunset.
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

  /// Three-stop logo gradient (yellow → orange → sunset). Used on hero
  /// CTAs, hero headers, and the brand wordmark fill. Named
  /// `goldGradient` for backwards-compat.
  final LinearGradient goldGradient;

  /// Walnut tone used for analytics / informational chips. Stays warm
  /// so it never competes with the brand orange.
  final Color info;

  /// Soft warm glow used behind hero CTAs and ring stats.
  final List<BoxShadow> goldGlow;

  /// "Completed / correct / streak" success tone — the deeper sunset.
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
              ? const Color(0x141A1208) // walnut @ 8%
              : const Color(0x99000000),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      goldGlow: <BoxShadow>[
        BoxShadow(
          color: AppTheme.sunOrange.withOpacity(isLight ? 0.32 : 0.24),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ],
      goldGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppTheme.heroGradient,
      ),
    );
  }
}
