import 'package:flutter/material.dart';

ThemeData buildDicomViewerTheme() {
  const background = Color(0xFF101417);
  const surface = Color(0xFF171D21);
  const panel = Color(0xFF20272C);
  const primary = Color(0xFF39A9A7);
  const secondary = Color(0xFFE0B84D);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
    primary: primary,
    secondary: secondary,
    surface: surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: panel,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF313A40),
      thickness: 1,
      space: 1,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFFE4ECEF),
        fixedSize: const Size(40, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: panel,
        selectedBackgroundColor: const Color(0xFF244244),
        foregroundColor: const Color(0xFFDCE5E8),
        selectedForegroundColor: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(fontSize: 13),
      bodySmall: TextStyle(fontSize: 12),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
