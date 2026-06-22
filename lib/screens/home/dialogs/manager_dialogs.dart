import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../services/manager_db_service.dart';

class ManagerDialogs {
  static void showLog(BuildContext context, String stationName,
      DocumentReference groupRef, String? selectedMyName) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
        backgroundColor: AppColors.darkBg,
        context: context,
        isScrollControlled: true,
        builder: (c) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AppBar(
                  title: Text("יומן: $stationName",
                      style: const TextStyle(color: AppColors.neonBlue)),
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.surfaceColor),
              SizedBox(
                  height: 400,
                  child: StreamBuilder<QuerySnapshot>(
                      stream: groupRef
                          .collection('station_logs')
                          .where('station', isEqualTo: stationName)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(
                              child: Text("שגיאה בטעינה",
                                  style: TextStyle(color: AppColors.alertRed)));
                        }
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.neonGreen));
                        }
                        return ListView.builder(
                            reverse: true,
                            itemCount: snap.data!.docs.length,
                            itemBuilder: (c, i) {
                              var m = snap.data!.docs[i];
                              return ListTile(
                                  title: Text(m['text'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      "${m['sender']} • ${DateFormat('HH:mm').format((m['timestamp'] as Timestamp).toDate())}"),
                                  leading: const Icon(Icons.chat_bubble_outline,
                                      size: 16, color: AppColors.neonGreen));
                            });
                      })),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: ctrl,
                            decoration:
                                const InputDecoration(hintText: "דווח..."))),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: const Icon(Icons.send, color: AppColors.neonGreen),
                        onPressed: () {
                          if (ctrl.text.isEmpty) return;
                          groupRef.collection('station_logs').add({
                            'station': stationName,
                            'text': ctrl.text,
                            'sender': selectedMyName ?? "אורח",
                            'timestamp': Timestamp.now()
                          });
                          ctrl.clear();
                        })
                  ]))
            ])));
  }

  static void addGuard(BuildContext context, DocumentReference groupRef) {
    String n = "";
    int s = 0, d = 0;
    bool isC = false;
    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
                    title: const Text("הוסף שומר"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          onChanged: (v) => n = v,
                          decoration: const InputDecoration(labelText: "שם")),
                      const SizedBox(height: 12),
                      TextField(
                          onChanged: (v) => s = int.tryParse(v) ?? 0,
                          decoration:
                              const InputDecoration(labelText: "שמירות"),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      TextField(
                          onChanged: (v) => d = int.tryParse(v) ?? 0,
                          decoration: const InputDecoration(labelText: "קושי"),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      SwitchListTile(
                          title: const Text("מפקד"),
                          value: isC,
                          onChanged: (v) => setS(() => isC = v))
                    ]),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            groupRef.collection('guards').add({
                              'name': n,
                              'totalShifts': s,
                              'totalDifficultyScore': d,
                              'lastShiftEnd': Timestamp.now(),
                              'isActive': true,
                              'isCommander': isC
                            });
                            Navigator.pop(c);
                          },
                          child: const Text("שמור"))
                    ])));
  }

  static void addStation(BuildContext context, DocumentReference groupRef) {
    String n = "";
    int d = 3, gN = 1;
    bool all = true;
    int? mM;
    TimeOfDay st = const TimeOfDay(hour: 0, minute: 0),
        en = const TimeOfDay(hour: 0, minute: 0);
    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
                    title: const Text("עמדה"),
                    content: SingleChildScrollView(
                        child: Column(children: [
                      TextField(
                          onChanged: (v) => n = v,
                          decoration: const InputDecoration(labelText: "שם")),
                      const SizedBox(height: 12),
                      Slider(
                          activeColor: AppColors.neonGreen,
                          value: d.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: d.toString(),
                          onChanged: (v) => setS(() => d = v.toInt())),
                      SwitchListTile(
                          title: const Text("24/7"),
                          value: all,
                          onChanged: (v) => setS(() => all = v)),
                      if (!all) ...[
                        ListTile(
                            title: Text("התחלה: ${st.format(c)}"),
                            onTap: () async {
                              var t = await showTimePicker(
                                  context: c, initialTime: st);
                              if (t != null) setS(() => st = t);
                            }),
                        ListTile(
                            title: Text("סוף: ${en.format(c)}"),
                            onTap: () async {
                              var t = await showTimePicker(
                                  context: c, initialTime: en);
                              if (t != null) setS(() => en = t);
                            })
                      ],
                      const SizedBox(height: 12),
                      TextField(
                          onChanged: (v) => mM = int.tryParse(v),
                          decoration: const InputDecoration(
                              labelText: "דקות מקסימום לשמירה"),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                      const Text("שומרים:"),
                      DropdownButton<int>(
                          dropdownColor: AppColors.surfaceColor,
                          style: const TextStyle(color: AppColors.neonGreen),
                          isExpanded: true,
                          value: gN,
                          items: List.generate(
                              10,
                              (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text("${i + 1}"))).toList(),
                          onChanged: (v) => setS(() => gN = v!))
                    ])),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            groupRef.collection('stations').add({
                              'name': n,
                              'guardsNeeded': gN,
                              'difficultyLevel': d,
                              'isAllDay': all,
                              'startHour': st.hour,
                              'endHour': en.hour,
                              'maxShiftMinutes': mM
                            });
                            Navigator.pop(c);
                          },
                          child: const Text("שמור"))
                    ])));
  }

  static void bulkAddGuardsDialog(
      BuildContext context, DocumentReference groupRef) {
    final ctrl = TextEditingController();
    int s = 0, d = 0;
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text("הוספה מרובה"),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: ctrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          hintText: "שמות (בשורות חדשות)")),
                  const SizedBox(height: 12),
                  TextField(
                      onChanged: (v) => s = int.tryParse(v) ?? 0,
                      decoration:
                          const InputDecoration(labelText: "שמירות התחלתיות"),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(
                      onChanged: (v) => d = int.tryParse(v) ?? 0,
                      decoration:
                          const InputDecoration(labelText: "קושי התחלתי"),
                      keyboardType: TextInputType.number)
                ])),
                actions: [
                  ElevatedButton(
                      onPressed: () async {
                        List<String> names = ctrl.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        for (var n in names) {
                          await groupRef.collection('guards').add({
                            'name': n,
                            'totalShifts': s,
                            'totalDifficultyScore': d,
                            'lastShiftEnd': Timestamp.now(),
                            'isActive': true,
                            'isCommander': false
                          });
                        }
                        if (c.mounted) Navigator.pop(c);
                      },
                      child: const Text("הוסף"))
                ]));
  }

  static void editGuardDialog(
      BuildContext context, Guard g, DocumentReference groupRef) {
    final sc = TextEditingController(text: g.totalShifts.toString()),
        dc = TextEditingController(text: g.totalDifficultyScore.toString());
    bool isC = g.isCommander;
    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
                    title: Text("ערוך: ${g.name}"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: sc,
                          decoration:
                              const InputDecoration(labelText: "שמירות"),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      TextField(
                          controller: dc,
                          decoration: const InputDecoration(labelText: "קושי"),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      SwitchListTile(
                          title: const Text("מפקד"),
                          value: isC,
                          onChanged: (v) => setS(() => isC = v))
                    ]),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            groupRef.collection('guards').doc(g.id).update({
                              'totalShifts':
                                  int.tryParse(sc.text) ?? g.totalShifts,
                              'totalDifficultyScore': int.tryParse(dc.text) ??
                                  g.totalDifficultyScore,
                              'isCommander': isC
                            });
                            Navigator.pop(c);
                          },
                          child: const Text("עדכן"))
                    ])));
  }

  static void showCodes(
      BuildContext context, DocumentReference groupRef) async {
    var d = await groupRef.get();
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text("קודי גישה (סודי)",
                    style: TextStyle(color: AppColors.warningOrange)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("מפקד: ${d['adminCode']}",
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("שומר: ${d['userCode']}",
                      style: const TextStyle(fontSize: 18))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("סגור"))
                ]));
  }

  static void partialScheduleDialog(BuildContext context, List<Guard> gs,
      List<Station> ss, DocumentReference groupRef) {
    int hour = DateTime.now().hour;
    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
                    title: const Text("בלת\"ם"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text("שבץ מחדש מהשעה:"),
                      DropdownButton<int>(
                          dropdownColor: AppColors.surfaceColor,
                          style: const TextStyle(color: AppColors.neonGreen),
                          value: hour,
                          items: List.generate(
                              24,
                              (i) => DropdownMenuItem(
                                  value: i, child: Text("$i:00"))).toList(),
                          onChanged: (v) => setS(() => hour = v!))
                    ]),
                    actions: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.alertRed,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(c);
                            ManagerDbService.runPartialSchedule(
                                gs, ss, groupRef, hour, context);
                          },
                          child: const Text("שבץ"))
                    ])));
  }

  static void editShift(BuildContext context, QueryDocumentSnapshot doc,
      List<Guard> allG, List<Station> allS, DocumentReference groupRef) {
    List<String> cur = List<String>.from(doc['guards']);
    final st = allS.firstWhere((s) => s.name == doc['station']);
    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
                title: const Text("החלפה ידנית"),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        cur.length,
                        (i) => DropdownButtonFormField<String>(
                            dropdownColor: AppColors.surfaceColor,
                            style: const TextStyle(color: AppColors.neonGreen),
                            initialValue: cur[i],
                            items: allG
                                .map((g) => DropdownMenuItem(
                                    value: g.name, child: Text(g.name)))
                                .toList(),
                            onChanged: (v) async {
                              if (v == null || v == cur[i]) return;
                              var oldG =
                                      allG.firstWhere((g) => g.name == cur[i]),
                                  newG = allG.firstWhere((g) => g.name == v);

                              cur[i] = v;

                              await ManagerDbService.swapGuardInShift(
                                  shiftDoc: doc,
                                  station: st,
                                  oldGuard: oldG,
                                  newGuard: newG,
                                  groupRef: groupRef,
                                  updatedGuardNamesList: cur);

                              if (c.mounted) Navigator.pop(c);
                            }))))));
  }
}
