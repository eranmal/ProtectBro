import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';
import 'app_component_themes.dart';

export 'app_colors.dart';
export 'app_text_theme.dart';
export 'app_component_themes.dart';

class AppTheme {
  static ThemeData get cyberTacticalTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.neonGreen,
        brightness: Brightness.dark,
        primary: AppColors.neonGreen,
        secondary: AppColors.neonBlue,
        surface: AppColors.surfaceColor,
      ),
      textTheme: AppTextTheme.darkTextTheme,
      appBarTheme: AppComponentThemes.appBarTheme,
      cardTheme: AppComponentThemes.cardTheme,
      dialogTheme: AppComponentThemes.dialogTheme,
      inputDecorationTheme: AppComponentThemes.inputDecorationTheme,
      elevatedButtonTheme: AppComponentThemes.elevatedButtonTheme,
      switchTheme: AppComponentThemes.switchTheme,
    );
  }
}
