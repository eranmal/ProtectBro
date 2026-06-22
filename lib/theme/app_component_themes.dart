import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppComponentThemes {
  static CardThemeData get cardTheme {
    return CardThemeData(
      color: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static DialogThemeData get dialogTheme {
    return const DialogThemeData(backgroundColor: AppColors.surfaceColor);
  }

  static InputDecorationTheme get inputDecorationTheme {
    return const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white54),
      hintStyle: TextStyle(color: Colors.white24),
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.neonGreen),
      ),
      filled: true,
      fillColor: Colors.transparent,
    );
  }

  static ElevatedButtonThemeData get elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static SwitchThemeData get switchTheme {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.neonGreen;
        }
        return Colors.white54;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.neonGreen.withValues(alpha: 0.5);
        }
        return Colors.white24;
      }),
    );
  }

  static AppBarTheme get appBarTheme {
    return const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  // Component-specific decorations and styling
  static BoxDecoration get commanderCardDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.neonGreen.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static const BorderSide commanderCardBorderSide = BorderSide(
    color: AppColors.neonGreen,
    width: 1.5,
  );

  static InputDecoration cyberInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, letterSpacing: 0),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.4),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
      ),
    );
  }
}

