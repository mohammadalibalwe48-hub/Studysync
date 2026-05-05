import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// The look-and-feel is a calm, modern academic palette: a cool
/// near-white canvas, deep indigo primary, violet companion gradient
/// stop, and a sky-blue functional accent for data visualisation.
/// Field names that historically referenced "gold" / "champagne" are
/// kept for backwards compatibility with widgets that still read them
/// from [AppPalette]; only their colour values were updated.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Brand colours ──────────────────────────

  /// Brand primary — deep indigo (used for primary actions, key icons,
  /// and selected-state tints).
  static const Color primary = Color(0xFF4F46E5);

  /// Top stop of the brand gradient (indigo).
  static const Color goldStart = Color(0xFF6366F1);

  /// Bottom stop of the brand gradient (violet).
  static const Color goldEnd = Color(0xFF8B5CF6);

  /// Soft fixed indigo (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFE0E7FF);

  /// Brighter accent indigo used for highlights and badges.
  static const Color primaryFixedDim = Color(0xFF818CF8);

  /// Secondary accent — saturated violet.
  static const Color secondary = Color(0xFF7C3AED);

  /// Subtle sky blue used for data visualisation / analytics.
  static const Color tertiary = Color(0xFF0EA5E9);

  static const Color tertiaryContainer = Color(0xFFBAE6FD);

  /// Cool near-white background.
  static const Color background = Color(0xFFF6F7FB);

  /// Pure white surface for cards / inputs.
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3F9);
  static const Color surfaceContainer = Color(0xFFE9ECF4);
  static const Color surfaceContainerHigh = Color(0xFFE2E6F0);

  /// Deep slate text on the cool canvas.
  static const Color onBackground = Color(0xFF111827);

  /// Muted on-surface variant (secondary text, label-caps overlines).
  static const Color onSurfaceVariant = Color(0xFF566177);

  /// Hairline outline used around cards and inputs.
  static const Color outline = Color(0xFF8A93A6);
  static const Color outlineVariant = Color(0xFFD7DCE8);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixed,
      onPrimaryContainer: Color(0xFF1E1B4B),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDE9FE),
      onSecondaryContainer: Color(0xFF2E1065),
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
      surfaceContainerHighest: Color(0xFFDADFEC),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF0F172A),
      scrim: Color(0xFF0F172A),
      inverseSurface: Color(0xFF1F2937),
      onInverseSurface: Color(0xFFF1F5F9),
      inversePrimary: primaryFixedDim,
      surfaceTint: primary,
    );
    return _buildTheme(scheme: scheme);
  }

  /// Dark mode reuses the same indigo accent system over a deep slate
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
///
/// Field names retain the historical "gold" / "champagne" naming for
/// backwards compatibility — they now hold cool indigo / slate values.
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

  /// Default brand gradient (top-left → bottom-right): indigo → violet.
  LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent, warm],
      );

  /// Soft indigo glow used under elevated CTAs and hero pieces.
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
          color: Color(0x14111827),
          blurRadius: 24,
          offset: Offset(0, 6),
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
