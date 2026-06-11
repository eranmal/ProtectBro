import '../models/models.dart';

// פונקציית מיון השומרים לפי החוק הקדוש: שמירות -> מנוחה -> קושי
List<Guard> _getAvail(List<Guard> gs, List<ScheduledShift> shifts, DateTime start, DateTime end) {
  var avail = gs.where((g) {
    bool isActive = g.isActive;
    // בדיקה שהשומר לא שומר כבר בעמדה אחרת באותן שעות
    bool isBusy = shifts.any((s) => 
      start.isBefore(s.end) && end.isAfter(s.start) && 
      s.assignedGuards.any((ag) => ag.id == g.id)
    );
    return isActive && !isBusy;
  }).toList();

  avail.sort((a, b) {
    // 1. מי ששמר הכי פחות
    int shiftCompare = a.totalShifts.compareTo(b.totalShifts);
    if (shiftCompare != 0) return shiftCompare;
    // 2. מי שנח הכי הרבה (זמן סיום שמירה קודמת הכי מוקדם)
    int restCompare = a.lastShiftEnd.compareTo(b.lastShiftEnd);
    if (restCompare != 0) return restCompare;
    // 3. מי שצבר פחות דרגת קושי
    return a.totalDifficultyScore.compareTo(b.totalDifficultyScore);
  });
  
  return avail;
}

List<ScheduledShift> generateAdvancedSchedule(List<Guard> realGuards, List<Station> stations, DateTime startTime) {
  List<ScheduledShift> fullSchedule = [];
  List<Guard> tempGuards = realGuards.map((g) => g.copy()).toList();
  DateTime dayEnd = DateTime(startTime.year, startTime.month, startTime.day, 0, 0).add(const Duration(hours: 24));

  // שעון פנימי לכל עמדה
  Map<String, DateTime> stationClocks = { for (var s in stations) s.id: _getStart(s, startTime) };

  while (true) {
    // מוצאים את העמדה שהשעון שלה הוא המוקדם ביותר כרגע
    Station? nextStation;
    DateTime earliestTime = dayEnd;

    for (var st in stations) {
      DateTime currentClock = stationClocks[st.id]!;
      if (currentClock.isBefore(earliestTime)) {
        if (_isActive(st, currentClock)) {
          earliestTime = currentClock;
          nextStation = st;
        } else {
          // אם העמדה לא פעילה עכשיו, מקפיצים את השעון שלה להתחלה הבאה
          DateTime nextActive = _next(st, currentClock, dayEnd);
          stationClocks[st.id] = nextActive;
          if (nextActive.isBefore(earliestTime)) {
             earliestTime = nextActive;
             // אנחנו לא קובעים את nextStation כאן כי רק הקפצנו שעון
          }
        }
      }
    }

    // אם לא מצאנו שום עמדה שצריכה שיבוץ לפני סוף היום - סיימנו
    if (nextStation == null) break;

    DateTime sStart = stationClocks[nextStation.id]!;
    
    // חישוב אורך משמרת
    List<Guard> currentlyAvail = _getAvail(tempGuards, fullSchedule, sStart, sStart.add(const Duration(minutes: 5)));
    int dur = (currentlyAvail.length == 0) ? 60 : _roundUp5(nextStation.totalActiveMinutes ~/ (currentlyAvail.length ~/ nextStation.guardsNeeded).clamp(1, 100));
    if (nextStation.maxShiftMinutes != null && dur > nextStation.maxShiftMinutes!) dur = nextStation.maxShiftMinutes!;
    
    DateTime sEnd = sStart.add(Duration(minutes: dur));
    DateTime stEnd = _getEnd(nextStation, startTime);
    if (sEnd.isAfter(stEnd)) sEnd = stEnd;

    // שליפת שומרים סופית למשמרת הזו
    List<Guard> selected = _getAvail(tempGuards, fullSchedule, sStart, sEnd);

    if (selected.length >= nextStation.guardsNeeded) {
      List<Guard> picked = selected.take(nextStation.guardsNeeded).toList();
      fullSchedule.add(ScheduledShift(
        start: sStart, 
        end: sEnd, 
        station: nextStation, 
        assignedGuards: picked.map((g) => g.copy()).toList()
      ));

      // עדכון מדדים
      for (var p in picked) {
        var tg = tempGuards.firstWhere((t) => t.id == p.id);
        tg.totalShifts++;
        tg.totalDifficultyScore += nextStation.difficultyLevel;
        tg.lastShiftEnd = sEnd;
      }
      stationClocks[nextStation.id] = sEnd;
    } else {
      // אם אין מספיק שומרים, מקפיצים את הזמן ב-15 דקות ומנסים שוב (מצבי קצה)
      stationClocks[nextStation.id] = sStart.add(const Duration(minutes: 15));
    }
  }
  
  fullSchedule.sort((a, b) => a.start.compareTo(b.start));
  return fullSchedule;
}

// פונקציות עזר (ללא שינוי מהותי, רק תחזוקה)
int _roundUp5(int m) => (m % 5 == 0) ? m : m + (5 - m % 5);
DateTime _getStart(Station s, DateTime l) { DateTime b = DateTime(l.year, l.month, l.day, s.startHour, 0); return b.isBefore(l) ? l : b; }
bool _isActive(Station s, DateTime t) { if (s.isAllDay) return true; double h = t.hour + t.minute / 60.0, st = s.startHour.toDouble(), en = s.endHour == 0 ? 24.0 : s.endHour.toDouble(); return en > st ? (h >= st && h < en) : (h >= st || h < en); }
DateTime _getEnd(Station s, DateTime r) { if (s.isAllDay) return DateTime(r.year, r.month, r.day, 0, 0).add(const Duration(hours: 24)); int eH = s.endHour == 0 ? 24 : s.endHour; DateTime e = DateTime(r.year, r.month, r.day, eH, 0); return s.endHour < s.startHour ? e.add(const Duration(days: 1)) : e; }
DateTime _next(Station s, DateTime c, DateTime dE) { DateTime n = DateTime(c.year, c.month, c.day, s.startHour, 0); if (!n.isAfter(c)) n = n.add(const Duration(days: 1)); return n.isBefore(dE) ? n : dE; }