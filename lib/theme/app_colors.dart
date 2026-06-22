import 'package:flutter/material.dart';

class AppColors {
  // Primary Accents
  static const Color neonGreen = Color(0xFF00FF87);
  static const Color neonBlue = Color(0xFF00B8FF);
  
  // Backgrounds
  static const Color darkBg = Color(0xFF090D09);
  static const Color surfaceColor = Color(0xFF111A11);
  
  // Alerts and Warnings
  static const Color alertRed = Colors.redAccent;
  static const Color warningOrange = Colors.orangeAccent;

  // Shared gradients
  static const RadialGradient backgroundGradient = RadialGradient(
    colors: [Color(0xFF0F2012), darkBg],
    center: Alignment.topCenter,
    radius: 1.5,
  );
}
