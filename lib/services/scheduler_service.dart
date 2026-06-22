import '../models/models.dart';

// Guard sorting function based on the holy rule: shifts -> rest -> difficulty
List<Guard> _getAvail(
    List<Guard> gs, List<ScheduledShift> shifts, DateTime start, DateTime end) {
  var avail = gs.where((g) {
    bool isActive = g.isActive;
    // Check that the guard is not already guarding at another station during these hours
    bool isBusy = shifts.any((s) =>
        start.isBefore(s.end) &&
        end.isAfter(s.start) &&
        s.assignedGuards.any((ag) => ag.id == g.id));
    return isActive && !isBusy;
  }).toList();

  avail.sort((a, b) {
    // 1. Who guarded the least
    int shiftCompare = a.totalShifts.compareTo(b.totalShifts);
    if (shiftCompare != 0) return shiftCompare;
    // 2. Who rested the most (earliest end time of previous shift)
    int restCompare = a.lastShiftEnd.compareTo(b.lastShiftEnd);
    if (restCompare != 0) return restCompare;
    // 3. Who accumulated less difficulty score
    return a.totalDifficultyScore.compareTo(b.totalDifficultyScore);
  });

  return avail;
}

List<ScheduledShift> generateAdvancedSchedule(
    List<Guard> realGuards, List<Station> stations, DateTime startTime) {
  List<ScheduledShift> fullSchedule = [];
  List<Guard> tempGuards = realGuards.map((g) => g.copy()).toList();
  DateTime dayEnd =
      DateTime(startTime.year, startTime.month, startTime.day, 0, 0)
          .add(const Duration(hours: 24));

  // Internal clock for each station
  Map<String, DateTime> stationClocks = {
    for (var s in stations) s.id: _getStart(s, startTime)
  };

  while (true) {
    // Find the station whose clock is currently the earliest
    Station? nextStation;
    DateTime earliestTime = dayEnd;

    for (var st in stations) {
      DateTime currentClock = stationClocks[st.id]!;
      if (currentClock.isBefore(earliestTime)) {
        if (_isActive(st, currentClock)) {
          earliestTime = currentClock;
          nextStation = st;
        } else {
          // If the station is not active now, advance its clock to the next start
          DateTime nextActive = _next(st, currentClock, dayEnd);
          stationClocks[st.id] = nextActive;
          if (nextActive.isBefore(earliestTime)) {
            earliestTime = nextActive;
            // We don't set nextStation here because we only advanced the clock
          }
        }
      }
    }

    // If we didn't find any station that needs scheduling before the end of the day - we're done
    if (nextStation == null) break;

    DateTime sStart = stationClocks[nextStation.id]!;

    // Calculate shift duration
    List<Guard> currentlyAvail = _getAvail(tempGuards, fullSchedule, sStart,
        sStart.add(const Duration(minutes: 5)));
    int dur = (currentlyAvail.isEmpty)
        ? 60
        : _roundUp5(nextStation.totalActiveMinutes ~/
            (currentlyAvail.length ~/ nextStation.guardsNeeded).clamp(1, 100));
    if (nextStation.maxShiftMinutes != null &&
        dur > nextStation.maxShiftMinutes!) {
      dur = nextStation.maxShiftMinutes!;
    }

    DateTime sEnd = sStart.add(Duration(minutes: dur));
    DateTime stEnd = _getEnd(nextStation, startTime);
    if (sEnd.isAfter(stEnd)) sEnd = stEnd;

    // Final fetch of guards for this shift
    List<Guard> selected = _getAvail(tempGuards, fullSchedule, sStart, sEnd);

    if (selected.length >= nextStation.guardsNeeded) {
      List<Guard> picked = selected.take(nextStation.guardsNeeded).toList();
      fullSchedule.add(ScheduledShift(
          start: sStart,
          end: sEnd,
          station: nextStation,
          assignedGuards: picked.map((g) => g.copy()).toList()));

      // Update metrics
      for (var p in picked) {
        var tg = tempGuards.firstWhere((t) => t.id == p.id);
        tg.totalShifts++;
        tg.totalDifficultyScore += nextStation.difficultyLevel;
        tg.lastShiftEnd = sEnd;
      }
      stationClocks[nextStation.id] = sEnd;
    } else {
      // If there are not enough guards, advance time by 15 minutes and try again (edge cases)
      stationClocks[nextStation.id] = sStart.add(const Duration(minutes: 15));
    }
  }

  fullSchedule.sort((a, b) => a.start.compareTo(b.start));
  return fullSchedule;
}

// Helper functions (refactored for readability)
int _roundUp5(int minutes) => (minutes % 5 == 0) ? minutes : minutes + (5 - minutes % 5);

DateTime _getStart(Station station, DateTime referenceTime) {
  DateTime baseTime = DateTime(referenceTime.year, referenceTime.month, referenceTime.day, station.startHour, 0);
  return baseTime.isBefore(referenceTime) ? referenceTime : baseTime;
}

bool _isActive(Station station, DateTime time) {
  if (station.isAllDay) return true;
  double currentHour = time.hour + time.minute / 60.0;
  double startH = station.startHour.toDouble();
  double endH = station.endHour == 0 ? 24.0 : station.endHour.toDouble();
  
  return endH > startH 
      ? (currentHour >= startH && currentHour < endH) 
      : (currentHour >= startH || currentHour < endH);
}

DateTime _getEnd(Station station, DateTime referenceTime) {
  if (station.isAllDay) {
    return DateTime(referenceTime.year, referenceTime.month, referenceTime.day, 0, 0)
        .add(const Duration(hours: 24));
  }
  int endH = station.endHour == 0 ? 24 : station.endHour;
  DateTime endTime = DateTime(referenceTime.year, referenceTime.month, referenceTime.day, endH, 0);
  return station.endHour < station.startHour ? endTime.add(const Duration(days: 1)) : endTime;
}

DateTime _next(Station station, DateTime currentClock, DateTime dayEnd) {
  DateTime nextTime = DateTime(currentClock.year, currentClock.month, currentClock.day, station.startHour, 0);
  if (!nextTime.isAfter(currentClock)) {
    nextTime = nextTime.add(const Duration(days: 1));
  }
  return nextTime.isBefore(dayEnd) ? nextTime : dayEnd;
}
