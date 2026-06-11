import 'package:cloud_firestore/cloud_firestore.dart';

class Guard {
  final String id;
  final String name;
  int totalShifts;
  int totalDifficultyScore;
  DateTime lastShiftEnd;
  bool isActive;
  bool isCommander; // שדה מפקד

  Guard({
    required this.id,
    required this.name,
    this.totalShifts = 0,
    this.totalDifficultyScore = 0,
    required this.lastShiftEnd,
    this.isActive = true,
    this.isCommander = false,
  });

  Guard copy() => Guard(
    id: id, name: name, totalShifts: totalShifts, 
    totalDifficultyScore: totalDifficultyScore, 
    lastShiftEnd: lastShiftEnd, isActive: isActive,
    isCommander: isCommander,
  );
}

class Station {
  final String id;
  final String name;
  final int difficultyLevel;
  final int guardsNeeded;
  final bool isAllDay;
  final int startHour;
  final int endHour;
  final int? maxShiftMinutes;

  Station({
    required this.id, required this.name, required this.difficultyLevel,
    required this.guardsNeeded, this.isAllDay = true,
    this.startHour = 0, this.endHour = 24, this.maxShiftMinutes,
  });

  int get totalActiveMinutes {
    if (isAllDay) return 24 * 60;
    int s = startHour, e = endHour == 0 ? 24 : endHour;
    return e > s ? (e - s) * 60 : (24 - s + e) * 60;
  }
}

class ScheduledShift {
  final DateTime start;
  final DateTime end;
  final Station station;
  final List<Guard> assignedGuards;
  ScheduledShift({required this.start, required this.end, required this.station, required this.assignedGuards});
}