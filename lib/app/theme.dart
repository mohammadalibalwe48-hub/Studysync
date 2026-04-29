import 'package:flutter/material.dart';

/// Centralised theming for the Educational Steps Platform app.
///
/// Provides a refreshed Material 3 look & feel built around an indigo
/// seed, with carefully tuned card / input / app-bar styles for both
/// light and dark modes.
class AppTheme {
  AppTheme._();

  /// Brand primary — deep indigo.
  static const Color seed = Color(0xFF4F46E5);

  /// Secondary accent used for highlights, badges, charts.
  static const Color accent = Color(0xFF06B6D4);

  /// Warm tone used by streak / fire badges.
  static const Color warm = Color(0xFFF59E0B);

  static const Color _lightSurface = Color(0xFFF6F5FB);
  static const Color _lightCard = Colors.white;
  static const Color _lightOutline = Color(0xFFE5E7EB);

  static const Color _darkSurface = Color(0xFF0B0B12);
  static const Color _darkCard = Color(0xFF15151F);
  static const Color _darkOutline = Color(0xFF26263A);

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _buildTheme(
      scheme: scheme,
      surface: _lightSurface,
      card: _lightCard,
      outline: _lightOutline,
      onSurfaceMuted: const Color(0xFF6B7280),
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _buildTheme(
      scheme: scheme,
      surface: _darkSurface,
      card: _darkCard,
      outline: _darkOutline,
      onSurfaceMuted: const Color(0xFF9CA3AF),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color surface,
    required Color card,
    required Color outline,
    required Color onSurfaceMuted,
  }) {
    final TextTheme base = ThemeData(brightness: scheme.brightness).textTheme;
    final TextTheme text = base
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: TextStyle(color: onSurfaceMuted),
        labelStyle: TextStyle(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
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
          vertical: 16,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withOpacity(0.14),
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : onSurfaceMuted,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : onSurfaceMuted,
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      extensions: <ThemeExtension<dynamic>>[
        AppPalette(
          muted: onSurfaceMuted,
          outline: outline,
          card: card,
          accent: accent,
          warm: warm,
        ),
      ],
    );
  }
}

/// Custom palette tokens shared across screens (muted text, hairline
/// outlines, accent color etc.) without re-deriving them everywhere.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.muted,
    required this.outline,
    required this.card,
    required this.accent,
    required this.warm,
  });

  final Color muted;
  final Color outline;
  final Color card;
  final Color accent;
  final Color warm;

  @override
  AppPalette copyWith({
    Color? muted,
    Color? outline,
    Color? card,
    Color? accent,
    Color? warm,
  }) {
    return AppPalette(
      muted: muted ?? this.muted,
      outline: outline ?? this.outline,
      card: card ?? this.card,
      accent: accent ?? this.accent,
      warm: warm ?? this.warm,
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
    );
  }

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        const AppPalette(
          muted: Color(0xFF6B7280),
          outline: Color(0xFFE5E7EB),
          card: Colors.white,
          accent: AppTheme.accent,
          warm: AppTheme.warm,
        );
  }
}
