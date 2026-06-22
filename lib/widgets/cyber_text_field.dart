import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const CyberTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
          color: AppTheme.neonGreen,
          fontWeight: FontWeight.bold,
          letterSpacing: 2),
      decoration: InputDecoration(
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
          borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2),
        ),
      ),
    );
  }
}
