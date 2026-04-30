import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// The look-and-feel follows the "Radiant Achievement" design system:
/// a soft champagne canvas, warm radiant-gold primary, rich amber
/// secondary, subtle blue functional accent for data visualisation,
/// and a tactile-luxury aesthetic with high-diffusion shadows and
/// glassmorphism layers.
class AppTheme {
  AppTheme._();

  // ────────────────────────── Brand colours ──────────────────────────

  /// Brand primary — deep gold (used for text-on-light, primary actions
  /// background fills behind text, and key iconography).
  static const Color primary = Color(0xFF7B5800);

  /// Top stop of the radiant-gold gradient (used on CTAs / hero).
  static const Color goldStart = Color(0xFFEBB12F);

  /// Bottom stop of the radiant-gold gradient (rich amber).
  static const Color goldEnd = Color(0xFFFF8927);

  /// Soft fixed gold (chips, hero glow, badge fill).
  static const Color primaryFixed = Color(0xFFFFDEA4);

  /// Brighter radiant gold used for highlights and badges.
  static const Color primaryFixedDim = Color(0xFFF8BD3B);

  /// Secondary accent — rich amber.
  static const Color secondary = Color(0xFF964900);

  /// Subtle blue used for data visualisation / analytics only.
  static const Color tertiary = Color(0xFF0060AC);

  static const Color tertiaryContainer = Color(0xFF8DBDFF);

  /// Champagne background.
  static const Color background = Color(0xFFFFF8F3);

  /// Pure off-white surface for cards / inputs.
  static const Color surfaceCardLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFDF2E3);
  static const Color surfaceContainer = Color(0xFFF8ECDE);
  static const Color surfaceContainerHigh = Color(0xFFF2E7D8);

  /// Deep charcoal text on the soft champagne background.
  static const Color onBackground = Color(0xFF201B12);

  /// Muted on-surface variant (secondary text, label-caps overlines).
  static const Color onSurfaceVariant = Color(0xFF4F4534);

  /// Hairline outline used around cards and inputs.
  static const Color outline = Color(0xFF827562);
  static const Color outlineVariant = Color(0xFFD3C5AE);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // ────────────────────────── Theme builders ─────────────────────────

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFixedDim,
      onPrimaryContainer: Color(0xFF624600),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFDCC6),
      onSecondaryContainer: Color(0xFF311400),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF004B89),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF93000A),
      surface: background,
      onSurface: onBackground,
      surfaceContainerLowest: surfaceCardLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: Color(0xFFECE1D3),
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF1A1A1A),
      scrim: Color(0xFF1A1A1A),
      inverseSurface: Color(0xFF353026),
      onInverseSurface: Color(0xFFFAEFE1),
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
    final TextTheme manrope = GoogleFonts.manropeTextTheme(baseText)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          displayLarge: GoogleFonts.manrope(
            fontSize: 36,
            height: 44 / 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.72,
            color: scheme.onSurface,
          ),
          displayMedium: GoogleFonts.manrope(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
          headlineLarge: GoogleFonts.manrope(
            fontSize: 30,
            height: 38 / 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
          headlineMedium: GoogleFonts.manrope(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.24,
            color: scheme.onSurface,
          ),
          headlineSmall: GoogleFonts.manrope(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleLarge: GoogleFonts.manrope(
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleMedium: GoogleFonts.manrope(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleSmall: GoogleFonts.manrope(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          bodyLarge: GoogleFonts.manrope(
            fontSize: 16,
            height: 26 / 16,
            color: scheme.onSurface,
          ),
          bodyMedium: GoogleFonts.manrope(
            fontSize: 14,
            height: 22 / 14,
            color: scheme.onSurface,
          ),
          bodySmall: GoogleFonts.manrope(
            fontSize: 12,
            height: 18 / 12,
            color: muted,
          ),
          labelLarge: GoogleFonts.manrope(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          labelSmall: GoogleFonts.manrope(
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
        titleTextStyle: GoogleFonts.manrope(
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
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: GoogleFonts.manrope(color: muted),
        labelStyle: GoogleFonts.manrope(
          color: muted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
        floatingLabelStyle: GoogleFonts.manrope(
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
          return GoogleFonts.manrope(
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
