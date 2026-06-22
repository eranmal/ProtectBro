import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CommanderCard extends StatelessWidget {
  final Guard commander;

  const CommanderCard({super.key, required this.commander});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppComponentThemes.commanderCardDecoration,
      child: Card(
        color: AppColors.surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: AppComponentThemes.commanderCardBorderSide,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.military_tech,
            color: AppColors.neonGreen,
            size: 40,
          ),
          title: const Text(
            "מפקד תורן (חמ\"ל)",
            style: AppTextTheme.commanderTitle,
          ),
          subtitle: Text(
            commander.name,
            style: AppTextTheme.commanderSubtitle,
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 3.seconds, color: Colors.white10);
  }
}

