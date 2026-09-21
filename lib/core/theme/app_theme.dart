import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Spotly's light and dark themes.
///
/// The UI chrome is deliberately neutral (ink on white, or white on
/// graphite) so the category colours on the map are what stands out.
abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static final light = _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
    background: const Color(0xFFF4F5F7),
    surface: Colors.white,
    surfaceHigh: const Color(0xFFF0F2F5),
    ink: const Color(0xFF0F172A),
    inkMuted: const Color(0xFF64748B),
    outline: const Color(0xFFE2E8F0),
    error: const Color(0xFFDC2626),
  );

  static final dark = _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
    background: const Color(0xFF0B0D12),
    surface: const Color(0xFF161A22),
    surfaceHigh: const Color(0xFF1F242E),
    ink: const Color(0xFFF1F5F9),
    inkMuted: const Color(0xFF94A3B8),
    outline: const Color(0xFF2A303B),
    error: const Color(0xFFF87171),
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
    required Color ink,
    required Color inkMuted,
    required Color outline,
    required Color error,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: surface,
      primaryContainer: surfaceHigh,
      onPrimaryContainer: ink,
      secondary: palette.userLocation,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      surfaceContainerLowest: background,
      surfaceContainerLow: background,
      surfaceContainer: surfaceHigh,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      outline: outline,
      outlineVariant: outline,
      inverseSurface: ink,
      onInverseSurface: surface,
      shadow: palette.shadow,
      scrim: Colors.black54,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);

    final shape14 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      extensions: [palette],
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shape14,
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shape14,
          minimumSize: const Size(0, 48),
          foregroundColor: ink,
          side: BorderSide(color: outline),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          shape: shape14,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: surface),
        actionTextColor: surface,
        shape: shape14,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: ink),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.userLocation,
        selectionColor: palette.userLocation.withValues(alpha: 0.3),
        selectionHandleColor: palette.userLocation,
      ),
    );
  }
}
