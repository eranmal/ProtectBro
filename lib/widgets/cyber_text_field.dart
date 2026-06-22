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
      style: AppTextTheme.cyberLabel,
      decoration: AppComponentThemes.cyberInputDecoration(
        label: label,
        icon: icon,
      ),
    );
  }
}

