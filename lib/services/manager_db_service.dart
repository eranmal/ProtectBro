import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'scheduler_service.dart';

class ManagerDbService {
  static Future<void> runSchedule(List<Guard> guards, List<Station> stations,
      DocumentReference groupRef, BuildContext context) async {
    DateTime start = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0);
    final schedule = generateAdvancedSchedule(guards, stations, start);
    final sRef = groupRef.collection('latest_schedule');

    var old = await sRef.get();
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. Delete old schedule
    for (var d in old.docs) {
      batch.delete(d.reference);
    }

    // 2. Add new schedule
    for (var s in schedule) {
      var newDocRef = sRef.doc();
      batch.set(newDocRef, {
        'start': Timestamp.fromDate(s.start),
        'end': Timestamp.fromDate(s.end),
        'station': s.station.name,
        'guards': s.assignedGuards.map((g) => g.name).toList()
      });
    }

    // 3. Update guard metrics
    Map<String, Guard> updatedMap = {};
    for (var shift in schedule) {
      for (var g in shift.assignedGuards) {
        updatedMap[g.id] = g;
      }
    }
    for (var entry in updatedMap.entries) {
      var guardRef = groupRef.collection('guards').doc(entry.key);
      batch.update(guardRef, {
        'totalShifts': entry.value.totalShifts,
        'totalDifficultyScore': entry.value.totalDifficultyScore,
        'lastShiftEnd': Timestamp.fromDate(entry.value.lastShiftEnd)
      });
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("השיבוץ פורסם בהצלחה!",
              style: TextStyle(color: Colors.black)),
          backgroundColor: AppColors.neonGreen));
    }
  }

  static Future<void> runPartialSchedule(
      List<Guard> guards,
      List<Station> stations,
      DocumentReference groupRef,
      int hour,
      BuildContext context) async {
    DateTime start = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, 0);
    final sRef = groupRef.collection('latest_schedule');
    var snap = await sRef.get();

    Map<String, int> shiftReductions = {};
    Map<String, int> difficultyReductions = {};
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. Find shifts to delete and calculate metric reductions
    for (var doc in snap.docs) {
      DateTime docStart = (doc['start'] as Timestamp).toDate();
      if (docStart.isAtSameMomentAs(start) || docStart.isAfter(start)) {
        final st = stations.firstWhere((s) => s.name == doc['station']);
        for (String n in doc['guards']) {
          shiftReductions[n] = (shiftReductions[n] ?? 0) + 1;
          difficultyReductions[n] =
              (difficultyReductions[n] ?? 0) + st.difficultyLevel;
        }
        batch.delete(doc.reference);
      }
    }

    // 2. Adjust guard metrics in memory before generating
    List<Guard> updatedGuardsInMemory = [];
    for (var g in guards) {
      Guard gCopy = g.copy();
      DateTime nLE = start.subtract(const Duration(days: 1));
      
      var remainingShifts = snap.docs
          .where((d) =>
              (d['start'] as Timestamp).toDate().isBefore(start) &&
              (d['guards'] as List).contains(g.name))
          .toList();
          
      if (remainingShifts.isNotEmpty) {
        remainingShifts.sort(
            (a, b) => (b['end'] as Timestamp).compareTo(a['end'] as Timestamp));
        nLE = (remainingShifts.first['end'] as Timestamp).toDate();
      }
      
      int reducedShifts = gCopy.totalShifts - (shiftReductions[g.name] ?? 0);
      int reducedDifficulty = gCopy.totalDifficultyScore - (difficultyReductions[g.name] ?? 0);
      
      gCopy.totalShifts = reducedShifts < 0 ? 0 : reducedShifts;
      gCopy.totalDifficultyScore = reducedDifficulty < 0 ? 0 : reducedDifficulty;
      gCopy.lastShiftEnd = nLE;
      updatedGuardsInMemory.add(gCopy);
    }

    // 3. Generate new partial schedule
    final newShifts =
        generateAdvancedSchedule(updatedGuardsInMemory, stations, start);

    // 4. Add new shifts to batch
    for (var s in newShifts) {
      var newDocRef = sRef.doc();
      batch.set(newDocRef, {
        'start': Timestamp.fromDate(s.start),
        'end': Timestamp.fromDate(s.end),
        'station': s.station.name,
        'guards': s.assignedGuards.map((g) => g.name).toList()
      });
    }

    // 5. Update final guard metrics to DB
    Map<String, Guard> finalGuardMap = {};
    for (var sh in newShifts) {
      for (var g in sh.assignedGuards) {
        finalGuardMap[g.id] = g;
      }
    }
    
    for (var entry in finalGuardMap.entries) {
      var guardRef = groupRef.collection('guards').doc(entry.key);
      batch.update(guardRef, {
        'totalShifts': entry.value.totalShifts,
        'totalDifficultyScore': entry.value.totalDifficultyScore,
        'lastShiftEnd': Timestamp.fromDate(entry.value.lastShiftEnd)
      });
    }

    // Note: Guards that were reduced but not picked in the new schedule must also be saved!
    for (var memoryGuard in updatedGuardsInMemory) {
      if (!finalGuardMap.containsKey(memoryGuard.id)) {
        var guardRef = groupRef.collection('guards').doc(memoryGuard.id);
        batch.update(guardRef, {
          'totalShifts': memoryGuard.totalShifts,
          'totalDifficultyScore': memoryGuard.totalDifficultyScore,
          'lastShiftEnd': Timestamp.fromDate(memoryGuard.lastShiftEnd)
        });
      }
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("הלו\"ז חושב מחדש!", style: TextStyle(color: Colors.black)),
          backgroundColor: AppColors.neonGreen));
    }
  }

  static Future<void> resetMetrics(
      DocumentReference groupRef, BuildContext context) async {
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    var snap = await groupRef.collection('guards').get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {
        'totalShifts': 0,
        'totalDifficultyScore': 0,
        'lastShiftEnd': Timestamp.fromDate(yesterday)
      });
    }
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("המדדים אופסו בהצלחה",
              style: TextStyle(color: Colors.black)),
          backgroundColor: AppColors.neonGreen));
    }
  }

  static Future<void> swapGuardInShift({
    required QueryDocumentSnapshot shiftDoc,
    required Station station,
    required Guard oldGuard,
    required Guard newGuard,
    required DocumentReference groupRef,
    required List<String> updatedGuardNamesList,
  }) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. Update old guard
    var oldGRef = groupRef.collection('guards').doc(oldGuard.id);
    batch.update(oldGRef, {
      'totalShifts': FieldValue.increment(-1),
      'totalDifficultyScore': FieldValue.increment(-station.difficultyLevel)
    });

    // 2. Update new guard
    var newGRef = groupRef.collection('guards').doc(newGuard.id);
    batch.update(newGRef, {
      'totalShifts': FieldValue.increment(1),
      'totalDifficultyScore': FieldValue.increment(station.difficultyLevel),
      'lastShiftEnd': shiftDoc['end']
    });

    // 3. Update shift
    var shiftRef = groupRef.collection('latest_schedule').doc(shiftDoc.id);
    batch.update(shiftRef, {'guards': updatedGuardNamesList});

    await batch.commit();
  }
}
