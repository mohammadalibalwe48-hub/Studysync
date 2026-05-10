import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// The student app pairs a deep indigo-violet primary with the brand's
/// signature sunset-orange as a secondary accent. The primary leads the
/// app shell (top bar, bottom nav, headers, big cards), while the
/// orange punches through on hero CTAs, streaks, the "AI" card, and
/// any "achievement"-flavoured surface — so the logo's orange is still
/// front-and-centre but no longer fights with itself across every
/// screen.
///
/// Hierarchy:
///
/// - [primary]/`indigo`: brand chrome, focused inputs, selected chips,
///   bottom-nav active dot, primary icons, large headers.
/// - [secondary]/`sunOrange`: hero CTAs, streaks, "completed/correct"
///   states, the AI Recommendation card — the warm "achievement" tone.
/// - [tertiary]/`blossom`: alternate subject card tint, soft accent.
/// - Surfaces step from `lavender-25` (nearly white) up through
///   lavender-tinted containers; outlines are tight cool sand.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Primary (indigo) ──────────────────────────

  /// Deep indigo-violet primary — the dominant colour in the redesign.
  static const Color indigo = Color(0xFF5B47E0);

  /// Slightly warmer indigo used at the top of vertical hero gradients.
  static const Color indigoLight = Color(0xFF8472F0);

  /// Deep night-violet used at the bottom of vertical hero gradients
  /// and for tab-bar backgrounds in dark surfaces.
  static const Color indigoDeep = Color(0xFF3925B5);

  /// Lavender container — pale violet used for big subject cards and
  /// soft purple chips.
  static const Color lavender = Color(0xFFE6DFFF);

  /// Hover-state / on-violet container.
  static const Color lavenderDeep = Color(0xFFC9BCFF);

  /// Three-stop indigo gradient — used on the bottom-nav rail, big
  /// study-path hero, and any place we want the brand violet to glow.
  static const List<Color> primaryGradient = <Color>[
    indigoLight,
    indigo,
    indigoDeep,
  ];

  // ─────────────────────── Secondary (sunset orange) ─────────────────────

  /// Bright yellow at the top of the orange gradient (logo top).
  static const Color sunYellow = Color(0xFFFFD000);

  /// The brand's signature mid-orange — used for hero CTAs, "Study
  /// Now" pill buttons, AI Recommendation surface fill, streaks.
  static const Color sunOrange = Color(0xFFFF9500);

  /// Deep sunset for streak / "hot" badges and the bottom of the
  /// orange gradient.
  static const Color sunset = Color(0xFFFF6B00);

  /// Three-stop sunset gradient mirroring the logo top→bottom fade.
  /// Reserved for the AI Recommendation card and streak surfaces so
  /// the brand orange still has a hero moment.
  static const List<Color> heroGradient = <Color>[
    sunYellow,
    sunOrange,
    sunset,
  ];

  // Backwards-compat aliases used by widgets shipped before the
  // purple repaint. Keep the names so this is a colour change only,
  // not a sweeping rename.
  static const Color primary = indigo;
  static const Color goldStart = sunYellow;
  static const Color goldEnd = sunset;
  static const Color streakAmber = sunset;

  // ─────────────────────── Tertiary (warm blossom) ───────────────────────

  /// Warm pink — the second subject-card tint and the "girly" accent
  /// you see on the second card in the screenshot. Stays gentle so it
  /// never shouts over the indigo primary.
  static const Color blossom = Color(0xFFFFB7C5);
  static const Color blossomDeep = Color(0xFFE08099);

  /// Soft fixed indigo (chips, pill backgrounds, "tag" surfaces).
  static const Color primaryFixed = lavender;

  /// Brighter brand tone used as dark-mode primary.
  static const Color primaryFixedDim = Color(0xFFB7A8FF);

  /// Secondary accent — the brand orange. (Keeping the name `secondary`
  /// makes any widget reading `scheme.secondary` light up orange.)
  static const Color secondary = sunOrange;

  static const Color secondaryContainer = Color(0xFFFFE2C7);

  /// Tertiary container — pale blossom for the alternate subject card.
  static const Color tertiary = blossom;
  static const Color tertiaryContainer = Color(0xFFFFE0E6);

  /// App background — barely-tinted lavender white.
  static const Color background = Color(0xFFF7F4FF);

  /// Pure white card surface.
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1ECFF);
  static const Color surfaceContainer = Color(0xFFE6DFFF);
  static const Color surfaceContainerHigh = Color(0xFFD7CCFF);

  /// Primary text on light surfaces — deep night violet so headings
  /// and body copy feel sharper against the lavender canvas.
  static const Color onBackground = Color(0xFF1A1633);

  /// Muted on-surface variant — cool taupe with a hint of indigo.
  static const Color onSurfaceVariant = Color(0xFF6F6A8A);

  /// Hairline outline used around cards and inputs.
  static const Color outline = Color(0xFFE2DDF5);
  static const Color outlineVariant = Color(0xFFF1ECFF);

  static const Color error = Color(0xFFC53030);
  static const Color errorContainer = Color(0xFFFFE0DA);

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: lavender,
      onPrimaryContainer: Color(0xFF1A1633),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF5C2410),
      tertiary: tertiary,
      onTertiary: Color(0xFF3A1622),
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF3A1622),
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
      surfaceContainerHighest: lavenderDeep,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF1A1633),
      scrim: Color(0xFF1A1633),
      inverseSurface: Color(0xFF231C4D),
      onInverseSurface: Color(0xFFF1ECFF),
      inversePrimary: primaryFixedDim,
      surfaceTint: primary,
    );
    return _buildTheme(scheme: scheme);
  }

  /// Dark mode reuses the same indigo + orange pairing over a deep
  /// night-violet canvas so the brand stays consistent without feeling
  /// oppressive.
  static ThemeData get dark {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB7A8FF), // indigo-300 (brighter for contrast)
      onPrimary: Color(0xFF1A1633),
      primaryContainer: Color(0xFF3925B5), // indigo-800
      onPrimaryContainer: Color(0xFFE6DFFF),
      secondary: Color(0xFFFFB347), // sun-orange-300
      onSecondary: Color(0xFF2C1605),
      secondaryContainer: Color(0xFF7A3C00), // sun-orange-800
      onSecondaryContainer: Color(0xFFFFE5C2),
      tertiary: Color(0xFFFFB7C5),
      onTertiary: Color(0xFF3A1622),
      tertiaryContainer: Color(0xFF6E2A40),
      onTertiaryContainer: Color(0xFFFFE0E6),
      error: Color(0xFFE89A82),
      onError: Color(0xFF4A150A),
      errorContainer: Color(0xFF7C2613),
      onErrorContainer: Color(0xFFFFE0DA),
      surface: Color(0xFF11102A),
      onSurface: Color(0xFFEDE9FB),
      surfaceContainerLowest: Color(0xFF0B0A20),
      surfaceContainerLow: Color(0xFF181736),
      surfaceContainer: Color(0xFF211F47),
      surfaceContainerHigh: Color(0xFF2D2A5C),
      surfaceContainerHighest: Color(0xFF3A3672),
      onSurfaceVariant: Color(0xFFB6B0D6),
      outline: Color(0xFF2D2A5C),
      outlineVariant: Color(0xFF211F47),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFEDE9FB),
      onInverseSurface: Color(0xFF11102A),
      inversePrimary: primary,
      surfaceTint: Color(0xFFB7A8FF),
    );
    return _buildTheme(scheme: scheme);
  }

  static ThemeData _buildTheme({required ColorScheme scheme}) {
    final bool isLight = scheme.brightness == Brightness.light;
    final Color card = scheme.surfaceContainerLowest;
    final Color hairline = isLight
        ? const Color(0xFFE2DDF5)
        : const Color(0xFF2D2A5C);
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
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: cairo.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        labelStyle: cairo.labelMedium,
        side: BorderSide(color: hairline, width: 1),
        shape: const StadiumBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
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
    required this.primaryGradient,
    required this.info,
    required this.goldGlow,
    required this.indigoGlow,
    required this.success,
  });

  /// Brand "gold" — the orange hero accent (sunOrange). Named `gold`
  /// for backwards-compat with widgets predating this palette refresh.
  /// Reads from `scheme.secondary` so light mode = saturated orange,
  /// dark mode = brighter sunset.
  final Color gold;

  /// Streak / "hot" accent — the deepest sunset.
  final Color warm;

  /// Action / focus tone — the indigo primary.
  final Color accent;

  final Color muted;
  final Color outline;
  final Color card;

  /// Soft surface colour used for chips and inert pill backgrounds.
  /// Named `champagne` for backwards-compat (pulls from
  /// `scheme.surfaceContainerLow`, which is now lavender).
  final Color champagne;

  final List<BoxShadow> cardShadow;

  /// Three-stop sunset gradient (yellow → orange → sunset). Reserved
  /// for "achievement"-flavoured surfaces — the AI Recommendation
  /// card, "Study Now" CTAs, streak badges. Named `goldGradient` for
  /// backwards-compat.
  final LinearGradient goldGradient;

  /// Three-stop indigo gradient. Used on the brand bottom-nav rail,
  /// big study-path heroes, and any place we want the brand violet to
  /// glow.
  final LinearGradient primaryGradient;

  /// Deep walnut historically; now a violet-tinted analytics tone
  /// pulled from the tertiary slot. Stays in the cool family so it
  /// never fights the brand orange when both are on screen.
  final Color info;

  /// Soft warm glow used behind hero CTAs and ring stats.
  final List<BoxShadow> goldGlow;

  /// Soft violet glow used behind primary buttons and indigo cards.
  final List<BoxShadow> indigoGlow;

  /// "Completed / correct / streak" success tone — bright sunset.
  final Color success;

  /// Build a palette from the active theme. Prefer this in widgets so
  /// dark/light mode flips automatically.
  static AppPalette of(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;
    return AppPalette(
      gold: scheme.secondary,
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
              ? const Color(0x141A1633) // indigo @ 8%
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
      indigoGlow: <BoxShadow>[
        BoxShadow(
          color: AppTheme.indigo.withOpacity(isLight ? 0.28 : 0.20),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ],
      goldGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppTheme.heroGradient,
      ),
      primaryGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppTheme.primaryGradient,
      ),
    );
  }
}
