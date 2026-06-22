import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ScheduleExporter {
  static void copyToClipboard(
      List<QueryDocumentSnapshot> docs, String groupName, List<Guard> guards, BuildContext context) {
    if (docs.isEmpty) return;
    
    final cmd = guards.where((g) => g.isCommander).firstOrNull;
    StringBuffer buffer = StringBuffer();
    
    buffer.writeln("🗓️ *לו\"ז שמירות - $groupName*");
    buffer.writeln("----------------------------");
    
    Set<String> stationNames = docs.map((d) => d['station'] as String).toSet();
    List<String> sortedStations = stationNames.toList()..sort();
    
    for (var stationName in sortedStations) {
      buffer.writeln("\n📍 *עמדה: $stationName*");
      var stationShifts =
          docs.where((d) => d['station'] == stationName).toList();
          
      stationShifts.sort((a, b) =>
          (a['start'] as Timestamp).compareTo(b['start'] as Timestamp));
          
      for (var shift in stationShifts) {
        String timeStr =
            DateFormat('HH:mm').format((shift['start'] as Timestamp).toDate());
        List guardsInShift = shift['guards'];
        buffer.writeln("- $timeStr: ${guardsInShift.join(", ")}");
      }
      buffer.writeln("----------------------------");
    }
    
    if (cmd != null) buffer.writeln("\n👑 *מפקד תורן:* ${cmd.name}");
    buffer.writeln("\n_הופק באמצעות ProtectBro_");
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("הלו\"ז הועתק לפי עמדות!"),
          backgroundColor: AppColors.neonGreen));
    }
  }
}
