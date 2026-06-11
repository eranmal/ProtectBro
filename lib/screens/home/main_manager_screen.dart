import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:ui';
import '../../models/models.dart';
import '../../services/scheduler_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cyber_button.dart';
import '../../widgets/commander_card.dart';
import '../../widgets/radar_matrix.dart';

class MainManagerScreen extends StatefulWidget {
  final String groupId; final bool isAdmin; final String groupName;
  const MainManagerScreen({super.key, required this.groupId, required this.isAdmin, required this.groupName});
  @override
  State<MainManagerScreen> createState() => _MainManagerScreenState();
}

class _MainManagerScreenState extends State<MainManagerScreen> {
  String? _selectedMyName; bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    return Scaffold(
      backgroundColor: const Color(0xFF090D09),
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: groupRef.collection('latest_schedule').snapshots(),
            builder: (context, scheduleSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: groupRef.collection('guards').snapshots(),
                builder: (context, guardSnap) {
                  if (!scheduleSnap.hasData || !guardSnap.hasData) return const SizedBox();
                  return IconButton(
                    icon: const Icon(Icons.share_rounded, color: Color(0xFF00B8FF)),
                    onPressed: () {
                      final guards = guardSnap.data!.docs.map((d) => Guard(id: d.id, name: d['name'], totalShifts: d['totalShifts'] ?? 0, totalDifficultyScore: d['totalDifficultyScore'] ?? 0, lastShiftEnd: (d['lastShiftEnd'] as Timestamp).toDate(), isActive: d['isActive'] ?? true, isCommander: d['isCommander'] ?? false)).toList();
                      _copyScheduleToClipboard(scheduleSnap.data!.docs, widget.groupName, guards);
                    },
                  );
                }
              );
            }
          ),
          if (widget.isAdmin) IconButton(icon: const Icon(Icons.vpn_key_rounded, color: Colors.orangeAccent), onPressed: () => _showCodes(groupRef)),
          if (widget.isAdmin) IconButton(icon: Icon(_isEditMode ? Icons.check_circle_outline : Icons.edit_note, color: Colors.white), onPressed: () => setState(() => _isEditMode = !_isEditMode))
        ]
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF0F2012), Color(0xFF090D09)],
                  center: Alignment.center,
                  radius: 2.0,
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: groupRef.collection('guards').snapshots(),
            builder: (context, guardSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: groupRef.collection('stations').snapshots(),
                builder: (context, stationSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: groupRef.collection('latest_schedule').orderBy('start').snapshots(),
                    builder: (context, scheduleSnap) {
                      if (!guardSnap.hasData || !stationSnap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)));
                      final guards = guardSnap.data!.docs.map((d) => Guard(id: d.id, name: d['name'], totalShifts: d['totalShifts'] ?? 0, totalDifficultyScore: d['totalDifficultyScore'] ?? 0, lastShiftEnd: (d['lastShiftEnd'] as Timestamp).toDate(), isActive: d['isActive'] ?? true, isCommander: d['isCommander'] ?? false)).toList();
                      final stations = stationSnap.data!.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return Station(id: d.id, name: data['name'], difficultyLevel: data['difficultyLevel'] ?? 3, guardsNeeded: data['guardsNeeded'] ?? 1, isAllDay: data['isAllDay'] ?? true, startHour: data['startHour'] ?? 0, endHour: data['endHour'] ?? 24, maxShiftMinutes: data['maxShiftMinutes']);
                      }).toList();
                      final docs = scheduleSnap.data?.docs ?? [];
                      final commander = guards.where((g) => g.isCommander).firstOrNull;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            if (commander != null) CommanderCard(commander: commander).animate().fadeIn().slideY(begin: -0.2),
                            if (_selectedMyName != null) _buildPersonal(docs, groupRef).animate().fadeIn().scale(),
                            if (!widget.isAdmin && _selectedMyName == null) _buildPicker(guards).animate().fadeIn(),
                            
                            // Matrix / Radar Dashboard
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.05), blurRadius: 10)]
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: RadarMatrix(
                                    docs: docs,
                                    stations: stations,
                                    allGuards: guards,
                                    groupRef: groupRef,
                                    isEditMode: _isEditMode,
                                    onLogTap: _showLog,
                                    onShiftEdit: _editShift,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                            
                            if (widget.isAdmin) ...[
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white12),
                              _buildSectionTitle("סד\"כ שומרים", Icons.group),
                              _buildSectionHeader(() => _addGuard(groupRef), onReset: () => _resetMetrics(groupRef), onBulkAdd: () => _bulkAddGuardsDialog(groupRef)),
                              ...guards.map((g) => _buildGuardTile(g, groupRef)).toList().animate(interval: 50.ms).fadeIn().slideX(begin: 0.1),
                              
                              const SizedBox(height: 20),
                              _buildSectionTitle("עמדות שמירה", Icons.security),
                              _buildSectionHeader(() => _addStation(groupRef)),
                              ...stations.map((s) => _buildStationTile(s, groupRef)).toList().animate(interval: 50.ms).fadeIn().slideX(begin: 0.1),
                              
                              const SizedBox(height: 30),
                              Padding(
                                padding: const EdgeInsets.all(16), 
                                child: CyberButton(text: "פרסם שיבוץ מלא (מחצות)", backgroundColor: AppTheme.neonGreen, textColor: Colors.black, onPressed: () => _runSchedule(guards, stations, groupRef))
                              ).animate().fadeIn(delay: 500.ms),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16), 
                                child: CyberButton(text: "עדכון לו\"ז (בלת\"ם)", backgroundColor: AppTheme.alertRed, textColor: Colors.white, icon: Icons.warning_amber, onPressed: () => _partialScheduleDialog(guards, stations, groupRef))
                              ).animate().fadeIn(delay: 600.ms),
                              const SizedBox(height: 50)
                            ]
                          ]
                        )
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      )
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B8FF), size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Color(0xFF00B8FF), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildGuardTile(Guard g, DocumentReference groupRef) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: ListTile(
        leading: Icon(g.isCommander ? Icons.stars : Icons.person, color: g.isCommander ? Colors.orangeAccent : Colors.white54),
        title: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("קושי: ${g.totalDifficultyScore} | שמירות: ${g.totalShifts}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white54), onPressed: () => _editGuardDialog(g, groupRef)), 
            Switch(activeColor: const Color(0xFF00FF87), value: g.isActive, onChanged: (v) => groupRef.collection('guards').doc(g.id).update({'isActive': v}))
          ]
        )
      ),
    );
  }

  Widget _buildStationTile(Station s, DocumentReference groupRef) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: ListTile(
        leading: const Icon(Icons.radar, color: Color(0xFF00B8FF)),
        title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("${s.guardsNeeded} שומרים | ${s.isAllDay ? "24/7" : "${s.startHour}:00-${s.endHour}:00"}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => groupRef.collection('stations').doc(s.id).delete())
      ),
    );
  }

  void _showLog(String sN, DocumentReference ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(backgroundColor: const Color(0xFF090D09), context: context, isScrollControlled: true, builder: (c) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom), child: Column(mainAxisSize: MainAxisSize.min, children: [AppBar(title: Text("יומן: $sN", style: const TextStyle(color: Color(0xFF00B8FF))), automaticallyImplyLeading: false, backgroundColor: const Color(0xFF111A11)), SizedBox(height: 400, child: StreamBuilder<QuerySnapshot>(stream: ref.collection('station_logs').where('station', isEqualTo: sN).orderBy('timestamp', descending: true).snapshots(), builder: (context, snap) { if (snap.hasError) return const Center(child: Text("שגיאה בטעינה", style: TextStyle(color: Colors.red))); if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))); return ListView.builder(reverse: true, itemCount: snap.data!.docs.length, itemBuilder: (c, i) { var m = snap.data!.docs[i]; return ListTile(title: Text(m['text'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), subtitle: Text("${m['sender']} • ${DateFormat('HH:mm').format((m['timestamp'] as Timestamp).toDate())}", style: const TextStyle(color: Colors.white54)), leading: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF00FF87))); }); })), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(style: const TextStyle(color: Colors.white), controller: ctrl, decoration: const InputDecoration(hintText: "דווח...", hintStyle: TextStyle(color: Colors.white24), border: OutlineInputBorder()))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send, color: Color(0xFF00FF87)), onPressed: () { if (ctrl.text.isEmpty) return; ref.collection('station_logs').add({'station': sN, 'text': ctrl.text, 'sender': _selectedMyName ?? "אורח", 'timestamp': Timestamp.now()}); ctrl.clear(); })]))])));
  }

  Widget _buildSectionHeader(VoidCallback n, {VoidCallback? onReset, VoidCallback? onBulkAdd}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [if (onReset != null) IconButton(icon: const Icon(Icons.restart_alt, color: Colors.redAccent), onPressed: onReset), if (onBulkAdd != null) IconButton(icon: const Icon(Icons.group_add, color: Color(0xFF00B8FF)), onPressed: onBulkAdd), IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF00FF87)), onPressed: n)]));

  // --- Functions from original code with minor UI tweaks --- //
  void _copyScheduleToClipboard(List<QueryDocumentSnapshot> docs, String groupName, List<Guard> guards) {
    if (docs.isEmpty) return;
    final cmd = guards.where((g) => g.isCommander).firstOrNull;
    StringBuffer buffer = StringBuffer();
    buffer.writeln("🗓️ *לו\"ז שמירות - $groupName*");
    buffer.writeln("----------------------------");
    Set<String> stationNames = docs.map((d) => d['station'] as String).toSet();
    List<String> sortedStations = stationNames.toList()..sort();
    for (var stationName in sortedStations) {
      buffer.writeln("\n📍 *עמדה: $stationName*");
      var stationShifts = docs.where((d) => d['station'] == stationName).toList();
      stationShifts.sort((a, b) => (a['start'] as Timestamp).compareTo(b['start'] as Timestamp));
      for (var shift in stationShifts) {
        String timeStr = DateFormat('HH:mm').format((shift['start'] as Timestamp).toDate());
        List guardsInShift = shift['guards'];
        buffer.writeln("- $timeStr: ${guardsInShift.join(", ")}");
      }
      buffer.writeln("----------------------------");
    }
    if (cmd != null) buffer.writeln("\n👑 *מפקד תורן:* ${cmd.name}");
    buffer.writeln("\n_הופק באמצעות ProtectBro_");
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("הלו\"ז הועתק לפי עמדות!"), backgroundColor: Color(0xFF00FF87)));
  }

  void _partialScheduleDialog(List<Guard> gs, List<Station> ss, DocumentReference ref) {
    int hour = DateTime.now().hour;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: const Text("בלת\"ם", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text("שבץ מחדש מהשעה:", style: TextStyle(color: Colors.white70)), DropdownButton<int>(dropdownColor: const Color(0xFF111A11), style: const TextStyle(color: Color(0xFF00FF87)), value: hour, items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("$i:00"))).toList(), onChanged: (v) => setS(() => hour = v!))]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () { Navigator.pop(c); _runPartialSchedule(gs, ss, ref, hour); }, child: const Text("שבץ", style: TextStyle(color: Colors.white)))])));
  }

  void _runPartialSchedule(List<Guard> gs, List<Station> ss, DocumentReference ref, int hour) async {
    DateTime start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, 0);
    final sRef = ref.collection('latest_schedule');
    var snap = await sRef.get();
    Map<String, int> sRefu = {}, dRefu = {};
    for (var doc in snap.docs) {
      if ((doc['start'] as Timestamp).toDate().isAtSameMomentAs(start) || (doc['start'] as Timestamp).toDate().isAfter(start)) {
        final st = ss.firstWhere((s) => s.name == doc['station']);
        for (String n in doc['guards']) { sRefu[n] = (sRefu[n] ?? 0) + 1; dRefu[n] = (dRefu[n] ?? 0) + st.difficultyLevel; }
        await doc.reference.delete();
      }
    }
    for (var g in gs) {
      DateTime nLE = start.subtract(const Duration(days: 1));
      var rem = snap.docs.where((d) => (d['start'] as Timestamp).toDate().isBefore(start) && (d['guards'] as List).contains(g.name)).toList();
      if (rem.isNotEmpty) { rem.sort((a, b) => (b['end'] as Timestamp).compareTo(a['end'] as Timestamp)); nLE = (rem.first['end'] as Timestamp).toDate(); }
      await ref.collection('guards').doc(g.id).update({'totalShifts': FieldValue.increment(-(sRefu[g.name] ?? 0)), 'totalDifficultyScore': FieldValue.increment(-(dRefu[g.name] ?? 0)), 'lastShiftEnd': Timestamp.fromDate(nLE)});
    }
    var upGs = (await ref.collection('guards').get()).docs.map((d) => Guard(id: d.id, name: d['name'], totalShifts: d['totalShifts'] ?? 0, totalDifficultyScore: d['totalDifficultyScore'] ?? 0, lastShiftEnd: (d['lastShiftEnd'] as Timestamp).toDate(), isActive: d['isActive'] ?? true, isCommander: d['isCommander'] ?? false)).toList();
    final newShifts = generateAdvancedSchedule(upGs, ss, start);
    for (var s in newShifts) { await sRef.add({'start': Timestamp.fromDate(s.start), 'end': Timestamp.fromDate(s.end), 'station': s.station.name, 'guards': s.assignedGuards.map((g) => g.name).toList()}); }
    Map<String, Guard> fM = {}; for (var sh in newShifts) { for (var g in sh.assignedGuards) { fM[g.id] = g; } }
    for (var e in fM.entries) { await ref.collection('guards').doc(e.key).update({'totalShifts': e.value.totalShifts, 'totalDifficultyScore': e.value.totalDifficultyScore, 'lastShiftEnd': Timestamp.fromDate(e.value.lastShiftEnd)}); }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("הלו\"ז חושב מחדש!", style: TextStyle(color: Colors.black)), backgroundColor: Color(0xFF00FF87)));
  }



  void _editShift(QueryDocumentSnapshot doc, List<Guard> allG, List<Station> allS, DocumentReference ref) {
    List<String> cur = List<String>.from(doc['guards']); final st = allS.firstWhere((s) => s.name == doc['station']);
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: const Text("החלפה ידנית", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: List.generate(cur.length, (i) => DropdownButtonFormField<String>(dropdownColor: const Color(0xFF111A11), style: const TextStyle(color: Color(0xFF00FF87)), value: cur[i], items: allG.map((g) => DropdownMenuItem(value: g.name, child: Text(g.name))).toList(), onChanged: (v) async {
      if (v == null || v == cur[i]) return;
      var oldG = allG.firstWhere((g) => g.name == cur[i]), newG = allG.firstWhere((g) => g.name == v);
      await ref.collection('guards').doc(oldG.id).update({'totalShifts': FieldValue.increment(-1), 'totalDifficultyScore': FieldValue.increment(-st.difficultyLevel)});
      await ref.collection('guards').doc(newG.id).update({'totalShifts': FieldValue.increment(1), 'totalDifficultyScore': FieldValue.increment(st.difficultyLevel), 'lastShiftEnd': doc['end']});
      cur[i] = v; await ref.collection('latest_schedule').doc(doc.id).update({'guards': cur}); if (mounted) Navigator.pop(c);
    }))))));
  }

  void _addGuard(DocumentReference ref) {
    String n = ""; int s = 0, d = 0; bool isC = false;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: const Text("הוסף שומר", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => n = v, decoration: const InputDecoration(labelText: "שם", labelStyle: TextStyle(color: Colors.white54))), TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => s = int.tryParse(v) ?? 0, decoration: const InputDecoration(labelText: "שמירות", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number), TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => d = int.tryParse(v) ?? 0, decoration: const InputDecoration(labelText: "קושי", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number), SwitchListTile(activeColor: const Color(0xFF00FF87), title: const Text("מפקד", style: TextStyle(color: Colors.white)), value: isC, onChanged: (v) => setS(() => isC = v))]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black), onPressed: () { ref.collection('guards').add({'name': n, 'totalShifts': s, 'totalDifficultyScore': d, 'lastShiftEnd': Timestamp.now(), 'isActive': true, 'isCommander': isC}); Navigator.pop(c); }, child: const Text("שמור"))])));
  }

  void _addStation(DocumentReference ref) {
    String n = ""; int d = 3, gN = 1; bool all = true; int? mM; TimeOfDay st = const TimeOfDay(hour: 0, minute: 0), en = const TimeOfDay(hour: 0, minute: 0);
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: const Text("עמדה", style: TextStyle(color: Colors.white)), content: SingleChildScrollView(child: Column(children: [TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => n = v, decoration: const InputDecoration(labelText: "שם", labelStyle: TextStyle(color: Colors.white54))), Slider(activeColor: const Color(0xFF00FF87), value: d.toDouble(), min: 1, max: 5, divisions: 4, label: d.toString(), onChanged: (v) => setS(() => d = v.toInt())), SwitchListTile(activeColor: const Color(0xFF00FF87), title: const Text("24/7", style: TextStyle(color: Colors.white)), value: all, onChanged: (v) => setS(() => all = v)), if (!all) ...[ListTile(title: Text("התחלה: ${st.format(c)}", style: const TextStyle(color: Colors.white70)), onTap: () async { var t = await showTimePicker(context: c, initialTime: st); if (t != null) setS(() => st = t); }), ListTile(title: Text("סוף: ${en.format(c)}", style: const TextStyle(color: Colors.white70)), onTap: () async { var t = await showTimePicker(context: c, initialTime: en); if (t != null) setS(() => en = t); })], TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => mM = int.tryParse(v), decoration: const InputDecoration(labelText: "דקות מקסימום לשמירה", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number), const SizedBox(height: 10), const Text("שומרים:", style: TextStyle(color: Colors.white54)), DropdownButton<int>(dropdownColor: const Color(0xFF111A11), style: const TextStyle(color: Color(0xFF00FF87)), isExpanded: true, value: gN, items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1}"))).toList(), onChanged: (v) => setS(() => gN = v!))])), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black), onPressed: () { ref.collection('stations').add({'name': n, 'guardsNeeded': gN, 'difficultyLevel': d, 'isAllDay': all, 'startHour': st.hour, 'endHour': en.hour, 'maxShiftMinutes': mM}); Navigator.pop(c); }, child: const Text("שמור"))])));
  }

  void _bulkAddGuardsDialog(DocumentReference ref) {
    final ctrl = TextEditingController(); int s = 0, d = 0;
    showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: const Text("הוספה מרובה", style: TextStyle(color: Colors.white)), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(style: const TextStyle(color: Colors.white), controller: ctrl, maxLines: 5, decoration: const InputDecoration(hintText: "שמות (בשורות חדשות)", hintStyle: TextStyle(color: Colors.white24), border: OutlineInputBorder())), TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => s = int.tryParse(v) ?? 0, decoration: const InputDecoration(labelText: "שמירות התחלתיות", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number), TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => d = int.tryParse(v) ?? 0, decoration: const InputDecoration(labelText: "קושי התחלתי", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number)])), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black), onPressed: () async { List<String> names = ctrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(); for (var n in names) { await ref.collection('guards').add({'name': n, 'totalShifts': s, 'totalDifficultyScore': d, 'lastShiftEnd': Timestamp.now(), 'isActive': true, 'isCommander': false}); } if (mounted) Navigator.pop(c); }, child: const Text("הוסף"))]));
  }

  void _editGuardDialog(Guard g, DocumentReference ref) {
    final sc = TextEditingController(text: g.totalShifts.toString()), dc = TextEditingController(text: g.totalDifficultyScore.toString()); bool isC = g.isCommander;
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: Text("ערוך: ${g.name}", style: const TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(style: const TextStyle(color: Colors.white), controller: sc, decoration: const InputDecoration(labelText: "שמירות", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number), TextField(style: const TextStyle(color: Colors.white), controller: dc, decoration: const InputDecoration(labelText: "קושי", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number), SwitchListTile(activeColor: const Color(0xFF00FF87), title: const Text("מפקד", style: TextStyle(color: Colors.white)), value: isC, onChanged: (v) => setS(() => isC = v))]), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black), onPressed: () { ref.collection('guards').doc(g.id).update({'totalShifts': int.tryParse(sc.text) ?? g.totalShifts, 'totalDifficultyScore': int.tryParse(dc.text) ?? g.totalDifficultyScore, 'isCommander': isC}); Navigator.pop(c); }, child: const Text("עדכן"))])));
  }

  void _showCodes(DocumentReference ref) async { var d = await ref.get(); if (!mounted) return; showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: const Color(0xFF111A11), title: const Text("קודי גישה (סודי)", style: TextStyle(color: Colors.orangeAccent)), content: Column(mainAxisSize: MainAxisSize.min, children: [Text("מפקד: ${d['adminCode']}", style: const TextStyle(color: Colors.white, fontSize: 18)), const SizedBox(height: 10), Text("שומר: ${d['userCode']}", style: const TextStyle(color: Colors.white54, fontSize: 18))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("סגור", style: TextStyle(color: Colors.white54)))])); }
  
  void _resetMetrics(DocumentReference ref) async {
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    var snap = await ref.collection('guards').get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snap.docs) { batch.update(doc.reference, {'totalShifts': 0, 'totalDifficultyScore': 0, 'lastShiftEnd': Timestamp.fromDate(yesterday)}); }
    await batch.commit();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("המדדים אופסו בהצלחה", style: TextStyle(color: Colors.black)), backgroundColor: Color(0xFF00FF87)));
  }

  Widget _buildPersonal(List<QueryDocumentSnapshot> docs, DocumentReference ref) { 
    final my = docs.where((d) => (d['guards'] as List).contains(_selectedMyName)).toList(); 
    if (my.isEmpty) return const SizedBox(); 
    final next = my.first; 
    return Container(
      margin: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: const Color(0xFF00FF87).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00FF87))),
      child: ListTile(
        title: Text("השמירה שלך: ${next['station']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        subtitle: Text("שעה: ${DateFormat('HH:mm').format((next['start'] as Timestamp).toDate())}", style: const TextStyle(color: Color(0xFF00FF87), fontSize: 16)), 
        trailing: IconButton(icon: const Icon(Icons.edit_note, color: Colors.white), onPressed: () => _showLog(next['station'], ref))
      )
    ); 
  }
  
  Widget _buildPicker(List<Guard> gs) => Padding(padding: const EdgeInsets.all(16), child: DropdownButtonFormField<String>(dropdownColor: const Color(0xFF111A11), style: const TextStyle(color: Color(0xFF00FF87)), decoration: const InputDecoration(labelText: "הזדהה למערכת", labelStyle: TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black45, border: OutlineInputBorder()), items: gs.map((g) => DropdownMenuItem(value: g.name, child: Text(g.name))).toList(), onChanged: (v) => setState(() => _selectedMyName = v)));

  void _runSchedule(List<Guard> gs, List<Station> ss, DocumentReference ref) async {
    DateTime start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0);
    final schedule = generateAdvancedSchedule(gs, ss, start);
    final sRef = ref.collection('latest_schedule');
    var old = await sRef.get(); for (var d in old.docs) { await d.reference.delete(); }
    for (var s in schedule) { await sRef.add({'start': Timestamp.fromDate(s.start), 'end': Timestamp.fromDate(s.end), 'station': s.station.name, 'guards': s.assignedGuards.map((g) => g.name).toList()}); }
    Map<String, Guard> updatedMap = {};
    for (var shift in schedule) { for (var g in shift.assignedGuards) { updatedMap[g.id] = g; } }
    for (var entry in updatedMap.entries) { await ref.collection('guards').doc(entry.key).update({'totalShifts': entry.value.totalShifts, 'totalDifficultyScore': entry.value.totalDifficultyScore, 'lastShiftEnd': Timestamp.fromDate(entry.value.lastShiftEnd)}); }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("השיבוץ פורסם!", style: TextStyle(color: Colors.black)), backgroundColor: Color(0xFF00FF87)));
  }
}
