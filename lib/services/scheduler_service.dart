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
        dur > nextStation.maxShiftMinutes!) dur = nextStation.maxShiftMinutes!;

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

// Helper functions (no major changes, just maintenance)
int _roundUp5(int m) => (m % 5 == 0) ? m : m + (5 - m % 5);
DateTime _getStart(Station s, DateTime l) {
  DateTime b = DateTime(l.year, l.month, l.day, s.startHour, 0);
  return b.isBefore(l) ? l : b;
}

bool _isActive(Station s, DateTime t) {
  if (s.isAllDay) return true;
  double h = t.hour + t.minute / 60.0,
      st = s.startHour.toDouble(),
      en = s.endHour == 0 ? 24.0 : s.endHour.toDouble();
  return en > st ? (h >= st && h < en) : (h >= st || h < en);
}

DateTime _getEnd(Station s, DateTime r) {
  if (s.isAllDay)
    return DateTime(r.year, r.month, r.day, 0, 0)
        .add(const Duration(hours: 24));
  int eH = s.endHour == 0 ? 24 : s.endHour;
  DateTime e = DateTime(r.year, r.month, r.day, eH, 0);
  return s.endHour < s.startHour ? e.add(const Duration(days: 1)) : e;
}

DateTime _next(Station s, DateTime c, DateTime dE) {
  DateTime n = DateTime(c.year, c.month, c.day, s.startHour, 0);
  if (!n.isAfter(c)) n = n.add(const Duration(days: 1));
  return n.isBefore(dE) ? n : dE;
}
