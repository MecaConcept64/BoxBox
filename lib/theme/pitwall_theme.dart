import 'package:flutter/material.dart';

const pitwallCoral = Color(0xFFFF7B68);
const pitwallBackground = Color(0xFF101719);
const pitwallSurface = Color(0xFF1B2529);
const pitwallMuted = Color(0xFFACBAC5);

ThemeData buildPitwallTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final accent = dark ? pitwallCoral : const Color(0xFFAD392A);
  final background = dark ? pitwallBackground : const Color(0xFFF5F6F6);
  final muted = dark ? pitwallMuted : const Color(0xFF526169);
  final scheme = ColorScheme.fromSeed(
    seedColor: pitwallCoral,
    brightness: brightness,
    primary: accent,
    onPrimary: dark ? pitwallBackground : Colors.white,
    surface: dark ? pitwallSurface : Colors.white,
    onSurfaceVariant: muted,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Titilium',
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
        backgroundColor: background, foregroundColor: scheme.onSurface),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      indicatorColor: accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontFamily: 'Titilium',
          fontSize: 12,
          color: states.contains(WidgetState.selected) ? accent : muted)),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : muted)),
    ),
  );
}
