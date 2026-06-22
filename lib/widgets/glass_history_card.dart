import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class GlassHistoryCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GlassHistoryCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: group['isAdmin']
                      ? AppTheme.neonGreen.withValues(alpha: 0.2)
                      : AppTheme.warningOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(group['isAdmin'] ? Icons.star : Icons.shield,
                    color: group['isAdmin']
                        ? AppTheme.neonGreen
                        : AppTheme.warningOrange),
              ),
              title: Text(group['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white)),
              subtitle: Text(group['isAdmin'] ? "גישת מפקד" : "גישת שומר",
                  style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white38),
                onPressed: onDelete,
              ),
              onTap: onTap,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1);
  }
}
