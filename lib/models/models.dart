import 'package:cloud_firestore/cloud_firestore.dart';

class Guard {
  final String id;
  final String name;
  int totalShifts;
  int totalDifficultyScore;
  DateTime lastShiftEnd;
  bool isActive;
  bool isCommander;

  Guard({
    required this.id,
    required this.name,
    this.totalShifts = 0,
    this.totalDifficultyScore = 0,
    required this.lastShiftEnd,
    this.isActive = true,
    this.isCommander = false,
  });

  factory Guard.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Guard(
      id: doc.id,
      name: d['name'] ?? 'Unknown',
      totalShifts: d['totalShifts'] ?? 0,
      totalDifficultyScore: d['totalDifficultyScore'] ?? 0,
      lastShiftEnd: d['lastShiftEnd'] != null ? (d['lastShiftEnd'] as Timestamp).toDate() : DateTime.now(),
      isActive: d['isActive'] ?? true,
      isCommander: d['isCommander'] ?? false,
    );
  }

  Guard copy() => Guard(
        id: id,
        name: name,
        totalShifts: totalShifts,
        totalDifficultyScore: totalDifficultyScore,
        lastShiftEnd: lastShiftEnd,
        isActive: isActive,
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

  const Station({
    required this.id,
    required this.name,
    required this.difficultyLevel,
    required this.guardsNeeded,
    this.isAllDay = true,
    this.startHour = 0,
    this.endHour = 24,
    this.maxShiftMinutes,
  }) : assert(guardsNeeded > 0, 'A station must require at least 1 guard'),
       assert(startHour >= 0 && startHour <= 24, 'Invalid start hour'),
       assert(endHour >= 0 && endHour <= 24, 'Invalid end hour');

  factory Station.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Station(
      id: doc.id,
      name: d['name'] ?? 'Unknown',
      difficultyLevel: d['difficultyLevel'] ?? 3,
      guardsNeeded: d['guardsNeeded'] ?? 1,
      isAllDay: d['isAllDay'] ?? true,
      startHour: d['startHour'] ?? 0,
      endHour: d['endHour'] ?? 24,
      maxShiftMinutes: d['maxShiftMinutes'],
    );
  }

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
  
  const ScheduledShift({
    required this.start,
    required this.end,
    required this.station,
    required this.assignedGuards,
  });
}
