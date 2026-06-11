import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (The "CSS Variables")
  static const Color neonGreen = Color(0xFF00FF87);
  static const Color neonBlue = Color(0xFF00B8FF);
  static const Color darkBg = Color(0xFF090D09);
  static const Color surfaceColor = Color(0xFF111A11);
  static const Color alertRed = Colors.redAccent;
  static const Color warningOrange = Colors.orangeAccent;

  static ThemeData get cyberTacticalTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: neonGreen,
        brightness: Brightness.dark,
        primary: neonGreen,
        secondary: neonBlue,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.heeboTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogBackgroundColor: surfaceColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Shared gradients
  static const RadialGradient backgroundGradient = RadialGradient(
    colors: [Color(0xFF0F2012), darkBg],
    center: Alignment.topCenter,
    radius: 1.5,
  );
}
