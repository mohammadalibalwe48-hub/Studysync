import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for "منصة خطوات التعليمية".
///
/// The brand is a refined gold → orange system inspired directly by the
/// app logo (a golden-orange figure on a stack of books).
///
/// Design rules to keep contrast strong and the UI readable:
/// - Surfaces are white. The canvas is a very faint warm off-white so
///   the eye still feels the warm tone but body text always has high
///   contrast on light surface.
/// - The gold→orange gradient is reserved for *brand moments* only —
///   the hero card, primary call-to-action, brand mark, and accent
///   icon plates. Body text and large fields are NEVER coloured with
///   the gradient.
/// - Body text is deep slate so 12sp / 13sp metadata is comfortably
///   readable on white cards.
/// - Outlines are warm, but very low contrast so cards have a soft
///   gilded edge instead of a heavy beige border.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Brand colours ──────────────────────────

  /// Brand primary — saturated orange, used for primary actions, key
  /// icons, and selected-state tints. (Brand "deep orange".)
  static const Color primary = Color(0xFFE76F0C);

  /// Top stop of the brand gradient — warm gold from the logo.
  static const Color goldStart = Color(0xFFFFC93C);

  /// Bottom stop of the brand gradient — deep saturated orange.
  static const Color goldEnd = Color(0xFFFF7A1A);

  /// Soft fixed gold (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFFFE7B8);

  /// Brighter accent gold used for highlights and badges.
  static const Color primaryFixedDim = Color(0xFFF6B33A);

  /// Secondary accent — a deeper amber/bronze used for secondary
  /// surfaces and dark-on-light text accents. Not purple.
  static const Color secondary = Color(0xFFB7541A);

  /// Tertiary accent — a calm teal that pairs with gold but stays
  /// visually distinct (used for analytics / data viz only).
  static const Color tertiary = Color(0xFF0E8F8F);

  static const Color tertiaryContainer = Color(0xFFB7E5E5);

  /// Very faint warm off-white canvas behind cards.
  static const Color background = Color(0xFFFFFAF1);

  /// Pure white surface for cards / inputs.
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF4E2);
  static const Color surfaceContainer = Color(0xFFFFEAC9);
  static const Color surfaceContainerHigh = Color(0xFFFFE0AF);

  /// Deep ink text on light cards (~14:1 contrast on white).
  static const Color onBackground = Color(0xFF1F1A12);

  /// Muted on-surface variant (secondary text). Tuned for 4.5:1
  /// contrast on white.
  static const Color onSurfaceVariant = Color(0xFF6B5B45);

  /// Hairline outline used around cards and inputs (warm, soft).
  static const Color outline = Color(0xFF9E8B6E);
  static const Color outlineVariant = Color(0xFFEAD9BF);

  static const Color error = Color(0xFFC02E1F);
  static const Color errorContainer = Color(0xFFFCE4DE);

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixed,
      onPrimaryContainer: Color(0xFF3F1F00),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFD9B4),
      onSecondaryContainer: Color(0xFF351600),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF003D3D),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF6B0E04),
      surface: background,
      onSurface: onBackground,
      surfaceContainerLowest: surfaceCardLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: Color(0xFFFFD79A),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF1F1A12),
      scrim: Color(0xFF1F1A12),
      inverseSurface: Color(0xFF2A2218),
      onInverseSurface: Color(0xFFFFF4E2),
      inversePrimary: primaryFixedDim,
      surfaceTint: primary,
    );
    return _buildTheme(scheme: scheme);
  }

  /// Dark mode reuses the same gold accent system over a deep
  /// chocolate canvas so the brand stays consistent.
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
    // Display/headline — Tajawal: a strong, geometric Arabic display
    // font that pairs well with Latin numerals and gives the brand a
    // confident voice.
    // Body — Cairo: a humanist Arabic sans that is exceptionally
    // readable at 12–16sp.
    final TextTheme manrope = GoogleFonts.cairoTextTheme(baseText)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          displayLarge: GoogleFonts.tajawal(
            fontSize: 36,
            height: 44 / 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.72,
            color: scheme.onSurface,
          ),
          displayMedium: GoogleFonts.tajawal(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
          headlineLarge: GoogleFonts.tajawal(
            fontSize: 30,
            height: 38 / 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
          headlineMedium: GoogleFonts.tajawal(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.24,
            color: scheme.onSurface,
          ),
          headlineSmall: GoogleFonts.tajawal(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
          titleLarge: GoogleFonts.tajawal(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
          titleMedium: GoogleFonts.tajawal(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
          titleSmall: GoogleFonts.tajawal(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w800,
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
          labelLarge: GoogleFonts.tajawal(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
          labelSmall: GoogleFonts.tajawal(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w800,
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
        titleTextStyle: GoogleFonts.tajawal(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardTheme(
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
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: GoogleFonts.cairo(color: muted),
        labelStyle: GoogleFonts.tajawal(
          color: muted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
        floatingLabelStyle: GoogleFonts.tajawal(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
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
          return GoogleFonts.tajawal(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

  /// Default brand gradient (top-left → bottom-right): warm gold →
  /// deep saturated orange. Mirrors the logo.
  LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent, warm],
      );

  /// Soft golden glow used under elevated CTAs and hero pieces.
  List<BoxShadow> get goldGlow => <BoxShadow>[
        BoxShadow(
          color: warm.withOpacity(0.32),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ];

  /// Soft, high-diffusion card shadow (Level 1 elevation). Tinted very
  /// faintly warm so cards feel held by the brand canvas instead of
  /// floating in cold grey.
  List<BoxShadow> get cardShadow => const <BoxShadow>[
        BoxShadow(
          color: Color(0x141F1A12),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x081F1A12),
          blurRadius: 4,
          offset: Offset(0, 1),
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
