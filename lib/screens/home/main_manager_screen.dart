import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cyber_button.dart';
import '../../widgets/commander_card.dart';
import '../../widgets/radar_matrix.dart';
import '../../services/manager_db_service.dart';
import '../../utils/schedule_exporter.dart';
import 'dialogs/manager_dialogs.dart';

class MainManagerScreen extends StatefulWidget {
  final String groupId;
  final bool isAdmin;
  final String groupName;
  const MainManagerScreen(
      {super.key,
      required this.groupId,
      required this.isAdmin,
      required this.groupName});
  @override
  State<MainManagerScreen> createState() => _MainManagerScreenState();
}

class _MainManagerScreenState extends State<MainManagerScreen> {
  String? _selectedMyName;
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.groupName,
                style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              StreamBuilder<QuerySnapshot>(
                  stream: groupRef.collection('latest_schedule').snapshots(),
                  builder: (context, scheduleSnap) {
                    return StreamBuilder<QuerySnapshot>(
                        stream: groupRef.collection('guards').snapshots(),
                        builder: (context, guardSnap) {
                          if (!scheduleSnap.hasData || !guardSnap.hasData) {
                            return const SizedBox();
                          }
                          return IconButton(
                            icon: const Icon(Icons.share_rounded,
                                color: AppColors.neonBlue),
                            onPressed: () {
                              final guards = guardSnap.data!.docs
                                  .map((d) => Guard.fromFirestore(d))
                                  .toList();
                              ScheduleExporter.copyToClipboard(scheduleSnap.data!.docs,
                                  widget.groupName, guards, context);
                            },
                          );
                        });
                  }),
              if (widget.isAdmin)
                IconButton(
                    icon: const Icon(Icons.vpn_key_rounded,
                        color: AppColors.warningOrange),
                    onPressed: () => ManagerDialogs.showCodes(context, groupRef)),
              if (widget.isAdmin)
                IconButton(
                    icon: Icon(
                        _isEditMode
                            ? Icons.check_circle_outline
                            : Icons.edit_note,
                        color: Colors.white),
                    onPressed: () => setState(() => _isEditMode = !_isEditMode))
            ]),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.backgroundGradient,
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
                      stream: groupRef
                          .collection('latest_schedule')
                          .orderBy('start')
                          .snapshots(),
                      builder: (context, scheduleSnap) {
                        if (!guardSnap.hasData || !stationSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.neonGreen));
                        }
                        final guards = guardSnap.data!.docs
                            .map((d) => Guard.fromFirestore(d))
                            .toList();
                        final stations = stationSnap.data!.docs
                            .map((d) => Station.fromFirestore(d))
                            .toList();
                        final docs = scheduleSnap.data?.docs ?? [];
                        final commander =
                            guards.where((g) => g.isCommander).firstOrNull;

                        return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(children: [
                              if (commander != null)
                                CommanderCard(commander: commander)
                                    .animate()
                                    .fadeIn()
                                    .slideY(begin: -0.2),
                              if (_selectedMyName != null)
                                _buildPersonal(docs, groupRef)
                                    .animate()
                                    .fadeIn()
                                    .scale(),
                              if (!widget.isAdmin && _selectedMyName == null)
                                _buildPicker(guards).animate().fadeIn(),

                              // Matrix / Radar Dashboard
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppColors.neonGreen
                                              .withValues(alpha: 0.3)),
                                      boxShadow: [
                                        BoxShadow(
                                            color: AppColors.neonGreen
                                                .withValues(alpha: 0.05),
                                            blurRadius: 10)
                                      ]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: RadarMatrix(
                                      docs: docs,
                                      stations: stations,
                                      allGuards: guards,
                                      groupRef: groupRef,
                                      isEditMode: _isEditMode,
                                      onLogTap: (sN, ref) => ManagerDialogs.showLog(context, sN, ref, _selectedMyName),
                                      onShiftEdit: (doc, allG, allS, ref) => ManagerDialogs.editShift(context, doc, allG, allS, ref),
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .slideY(begin: 0.1),

                              if (widget.isAdmin) ...[
                                const SizedBox(height: 20),
                                const Divider(color: Colors.white12),
                                _buildSectionTitle("סד\"כ שומרים", Icons.group),
                                _buildSectionHeader(() => ManagerDialogs.addGuard(context, groupRef),
                                    onReset: () => ManagerDbService.resetMetrics(groupRef, context),
                                    onBulkAdd: () =>
                                        ManagerDialogs.bulkAddGuardsDialog(context, groupRef)),
                                ...guards
                                    .map((g) => _buildGuardTile(g, groupRef))
                                    .toList()
                                    .animate(interval: 50.ms)
                                    .fadeIn()
                                    .slideX(begin: 0.1),
                                const SizedBox(height: 20),
                                _buildSectionTitle(
                                    "עמדות שמירה", Icons.security),
                                _buildSectionHeader(
                                    () => ManagerDialogs.addStation(context, groupRef)),
                                ...stations
                                    .map((s) => _buildStationTile(s, groupRef))
                                    .toList()
                                    .animate(interval: 50.ms)
                                    .fadeIn()
                                    .slideX(begin: 0.1),
                                const SizedBox(height: 30),
                                Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: CyberButton(
                                            text: "פרסם שיבוץ מלא (מחצות)",
                                            backgroundColor: AppColors.neonGreen,
                                            textColor: Colors.black,
                                            onPressed: () => ManagerDbService.runSchedule(
                                                guards, stations, groupRef, context)))
                                    .animate()
                                    .fadeIn(delay: 500.ms),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: CyberButton(
                                        text: "עדכון לו\"ז (בלת\"ם)",
                                        backgroundColor: AppColors.alertRed,
                                        textColor: Colors.white,
                                        icon: Icons.warning_amber,
                                        onPressed: () => ManagerDialogs.partialScheduleDialog(
                                            context,
                                            guards,
                                            stations,
                                            groupRef))).animate().fadeIn(
                                    delay: 600.ms),
                                const SizedBox(height: 50)
                              ]
                            ]));
                      },
                    );
                  },
                );
              },
            ),
          ],
        ));
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonBlue, size: 20),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildGuardTile(Guard g, DocumentReference groupRef) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)),
      child: ListTile(
          leading: Icon(g.isCommander ? Icons.stars : Icons.person,
              color: g.isCommander ? Colors.orangeAccent : Colors.white54),
          title: Text(g.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(
              "קושי: ${g.totalDifficultyScore} | שמירות: ${g.totalShifts}",
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: Colors.white54),
                onPressed: () => ManagerDialogs.editGuardDialog(context, g, groupRef)),
            Switch(
                value: g.isActive,
                onChanged: (v) => groupRef
                    .collection('guards')
                    .doc(g.id)
                    .update({'isActive': v}))
          ])),
    );
  }

  Widget _buildStationTile(Station s, DocumentReference groupRef) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)),
      child: ListTile(
          leading: const Icon(Icons.radar, color: AppColors.neonBlue),
          title: Text(s.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(
              "${s.guardsNeeded} שומרים | ${s.isAllDay ? "24/7" : "${s.startHour}:00-${s.endHour}:00"}",
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.alertRed),
              onPressed: () =>
                  groupRef.collection('stations').doc(s.id).delete())),
    );
  }

  // Removed _showLog

  Widget _buildSectionHeader(VoidCallback n,
          {VoidCallback? onReset, VoidCallback? onBulkAdd}) =>
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (onReset != null)
              IconButton(
                  icon: const Icon(Icons.restart_alt, color: AppColors.alertRed),
                  onPressed: onReset),
            if (onBulkAdd != null)
              IconButton(
                  icon: const Icon(Icons.group_add, color: AppColors.neonBlue),
                  onPressed: onBulkAdd),
            IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.neonGreen),
                onPressed: n)
          ]));

  // --- Functions from original code with minor UI tweaks --- //
  // Removed UI dialogs and heavy database functions

  Widget _buildPersonal(
      List<QueryDocumentSnapshot> docs, DocumentReference ref) {
    final my = docs
        .where((d) => (d['guards'] as List).contains(_selectedMyName))
        .toList();
    if (my.isEmpty) return const SizedBox();
    final next = my.first;
    return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.neonGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonGreen)),
        child: ListTile(
            title: Text("השמירה שלך: ${next['station']}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
                "שעה: ${DateFormat('HH:mm').format((next['start'] as Timestamp).toDate())}",
                style: const TextStyle(color: AppColors.neonGreen, fontSize: 16)),
            trailing: IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white),
                onPressed: () => ManagerDialogs.showLog(context, next['station'] as String, ref, _selectedMyName))));
  }

  Widget _buildPicker(List<Guard> gs) => Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
          style: const TextStyle(color: AppColors.neonGreen),
          decoration: const InputDecoration(
              labelText: "הזדהה למערכת"),
          items: gs
              .map((g) => DropdownMenuItem(value: g.name, child: Text(g.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedMyName = v)));
}
