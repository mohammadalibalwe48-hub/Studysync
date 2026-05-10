import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform teachers
/// companion app.
///
/// Palette is sampled directly from the shared app logo (vivid orange
/// figure reaching for yellow stars on a stack of orange-gold books).
/// The dominant logo pixels cluster in the `#FF6B00 → #FF9500 → #FFD000`
/// range. The previous palette mapped the brand to a deep mustard
/// `#7B5800` primary plus an out-of-family blue `#0060AC` tertiary,
/// which made the teachers app look noticeably different from — and
/// less energetic than — its own logo. The tokens below stay 100% in
/// the warm family and exactly mirror the student app's palette so
/// both apps feel like one product.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Logo gradient ──────────────────────────

  /// Brightest yellow at the top of the logo (stars / arm tip).
  static const Color sunYellow = Color(0xFFFFD000);

  /// The signature mid-orange of the figure & books — the most-common
  /// pixel colour in the logo by a wide margin. This is the brand.
  static const Color sunOrange = Color(0xFFFF9500);

  /// Deep sunset orange at the bottom edge of the books, used for
  /// streaks, success and the gradient's bottom stop.
  static const Color sunset = Color(0xFFFF6B00);

  /// Three-stop gradient that mirrors the logo top→bottom fade.
  static const List<Color> heroGradient = <Color>[
    sunYellow,
    sunOrange,
    sunset,
  ];

  // Backwards-compat aliases. Keep the existing names so widgets that
  // reference `goldStart` / `goldEnd` / `primary` keep working.
  static const Color primary = sunOrange;
  static const Color goldStart = sunYellow;
  static const Color goldEnd = sunset;

  /// Soft fixed honey (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFFFE9C2);

  /// Brighter brand tone used for highlights and dark-mode primary.
  static const Color primaryFixedDim = Color(0xFFFFB347);

  /// Secondary accent — deeper sunset ember. Same gradient family as
  /// [sunOrange], just hotter, so streaks and "completed" states read
  /// as fire without introducing a foreign hue.
  static const Color secondary = Color(0xFFE25A0D);

  /// Tertiary — deep walnut. Reserved for analytics / chart axes /
  /// data viz. Stays in the warm family so it never fights the brand
  /// orange (replacing the previous `#0060AC` blue, which clashed).
  static const Color tertiary = Color(0xFF6B3F1A);

  static const Color tertiaryContainer = Color(0xFFF1DFC3);

  /// App background — barely-tinted warm white. Cleaner than the old
  /// `#FFF8F3` so the orange accents pop instead of getting absorbed.
  static const Color background = Color(0xFFFFFCF6);

  /// Pure off-white surface for cards / inputs.
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF7E8);
  static const Color surfaceContainer = Color(0xFFFFEED2);
  static const Color surfaceContainerHigh = Color(0xFFFADDA8);

  /// Deep walnut text on the soft cream background.
  static const Color onBackground = Color(0xFF1A1208);

  /// Muted on-surface variant (secondary text, label-caps overlines).
  static const Color onSurfaceVariant = Color(0xFF6F5A3F);

  /// Hairline outline used around cards and inputs.
  static const Color outline = Color(0xFFB89E78);
  static const Color outlineVariant = Color(0xFFF0DDB6);

  static const Color error = Color(0xFFC53030);
  static const Color errorContainer = Color(0xFFFFE0DA);

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixed,
      onPrimaryContainer: Color(0xFF5C2C00),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFD8B8),
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

  /// Dark mode reuses the same gold accent system over a deep charcoal
  /// canvas so the brand stays consistent.
  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryFixedDim,
      brightness: Brightness.dark,
    );
    return _buildTheme(scheme: scheme);
  }

  static ThemeData _buildTheme({required ColorScheme scheme}) {
    final bool isLight = scheme.brightness == Brightness.light;
    final Color card = isLight
        ? surfaceCardLowest
        : Color.lerp(scheme.surface, Colors.white, 0.04) ?? scheme.surface;
    final Color hairline = isLight
        ? outlineVariant
        : Color.lerp(scheme.surface, Colors.white, 0.10) ?? scheme.outline;
    final Color muted = isLight
        ? onSurfaceVariant
        : scheme.onSurface.withOpacity(0.70);
    final Color appBg = scheme.surface;

    final TextTheme baseText =
        ThemeData(brightness: scheme.brightness).textTheme;
    // Use Cairo as the body/display font so Arabic glyphs render
    // beautifully across the entire app while keeping Latin numerals
    // readable in question labels.
    final TextTheme manrope = GoogleFonts.cairoTextTheme(baseText)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          displayLarge: GoogleFonts.cairo(
            fontSize: 36,
            height: 44 / 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.72,
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
            fontSize: 30,
            height: 38 / 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
          headlineMedium: GoogleFonts.cairo(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.24,
            color: scheme.onSurface,
          ),
          headlineSmall: GoogleFonts.cairo(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleLarge: GoogleFonts.cairo(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleMedium: GoogleFonts.cairo(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleSmall: GoogleFonts.cairo(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          labelSmall: GoogleFonts.cairo(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: muted,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: appBg,
      textTheme: manrope,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: hairline, width: isLight ? 0.6 : 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: GoogleFonts.cairo(color: muted),
        labelStyle: GoogleFonts.cairo(
          color: muted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
        floatingLabelStyle: GoogleFonts.cairo(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withOpacity(0.14),
        height: 70,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final bool selected = states.contains(WidgetState.selected);
          return GoogleFonts.cairo(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : muted,
            fontSize: 11,
            letterSpacing: 0.6,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : muted,
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      extensions: <ThemeExtension<dynamic>>[
        AppPalette(
          muted: muted,
          outline: hairline,
          card: card,
          accent: goldStart,
          warm: goldEnd,
          gold: primaryFixedDim,
          champagne: surfaceContainerLow,
          info: tertiary,
        ),
      ],
    );
  }
}

/// Custom palette tokens shared across screens (muted text, hairline
/// outlines, accent colour etc.) without re-deriving them everywhere.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.muted,
    required this.outline,
    required this.card,
    required this.accent,
    required this.warm,
    required this.gold,
    required this.champagne,
    required this.info,
  });

  final Color muted;
  final Color outline;
  final Color card;
  final Color accent;
  final Color warm;
  final Color gold;
  final Color champagne;
  final Color info;

  /// Default radiant-gold gradient (top-left → bottom-right).
  LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent, warm],
      );

  /// Soft amber glow used under elevated CTAs and hero pieces.
  List<BoxShadow> get goldGlow => <BoxShadow>[
        BoxShadow(
          color: accent.withOpacity(0.25),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  /// Soft, high-diffusion card shadow (Level 1 elevation).
  List<BoxShadow> get cardShadow => const <BoxShadow>[
        BoxShadow(
          color: Color(0x0A1A1A1A),
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ];

  @override
  AppPalette copyWith({
    Color? muted,
    Color? outline,
    Color? card,
    Color? accent,
    Color? warm,
    Color? gold,
    Color? champagne,
    Color? info,
  }) {
    return AppPalette(
      muted: muted ?? this.muted,
      outline: outline ?? this.outline,
      card: card ?? this.card,
      accent: accent ?? this.accent,
      warm: warm ?? this.warm,
      gold: gold ?? this.gold,
      champagne: champagne ?? this.champagne,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      card: Color.lerp(card, other.card, t) ?? card,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      warm: Color.lerp(warm, other.warm, t) ?? warm,
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      champagne: Color.lerp(champagne, other.champagne, t) ?? champagne,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        const AppPalette(
          muted: AppTheme.onSurfaceVariant,
          outline: AppTheme.outlineVariant,
          card: AppTheme.surfaceCardLowest,
          accent: AppTheme.goldStart,
          warm: AppTheme.goldEnd,
          gold: AppTheme.primaryFixedDim,
          champagne: AppTheme.surfaceContainerLow,
          info: AppTheme.tertiary,
        );
  }
}
