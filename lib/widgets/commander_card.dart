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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withOpacity(0.2), 
            blurRadius: 20, 
            spreadRadius: 2
          )
        ]
      ),
      child: Card(
        color: AppTheme.surfaceColor, 
        elevation: 0, 
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.neonGreen, width: 1.5), 
          borderRadius: BorderRadius.circular(16)
        ), 
        child: ListTile(
          leading: const Icon(Icons.military_tech, color: AppTheme.neonGreen, size: 40), 
          title: const Text("מפקד תורן (חמ\"ל)", style: TextStyle(color: Colors.white54, fontSize: 12)), 
          subtitle: Text(
            commander.name, 
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)
          )
        )
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white10);
  }
}
