import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextTheme {
  static TextTheme get darkTextTheme {
    return GoogleFonts.heeboTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white,
    );
  }

  // Centered styles for components/widgets to clean up inline styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  );

  static const TextStyle cyberLabel = TextStyle(
    color: AppColors.neonGreen,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );

  static const TextStyle commanderTitle = TextStyle(
    color: Colors.white54,
    fontSize: 12,
  );

  static const TextStyle commanderSubtitle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  static const TextStyle radarTime = TextStyle(
    color: AppColors.neonGreen,
    fontWeight: FontWeight.w900,
    fontFamily: 'monospace',
  );

  static const TextStyle radarHeading = TextStyle(
    color: AppColors.neonBlue,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );
}

