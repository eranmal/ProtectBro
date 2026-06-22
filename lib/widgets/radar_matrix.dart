import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class RadarMatrix extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final List<Station> stations;
  final List<Guard> allGuards;
  final DocumentReference groupRef;
  final bool isEditMode;
  final Function(String, DocumentReference) onLogTap;
  final Function(
          QueryDocumentSnapshot, List<Guard>, List<Station>, DocumentReference)
      onShiftEdit;

  const RadarMatrix({
    super.key,
    required this.docs,
    required this.stations,
    required this.allGuards,
    required this.groupRef,
    required this.isEditMode,
    required this.onLogTap,
    required this.onShiftEdit,
  });

  @override
  Widget build(BuildContext context) {
    Set<String> times = docs
        .map((d) =>
            DateFormat('HH:mm').format((d['start'] as Timestamp).toDate()))
        .toSet();
    List<String> sTimes = times.toList()..sort();

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DataTable(
              headingTextStyle: AppTextTheme.radarHeading,
              dataTextStyle: const TextStyle(color: Colors.white),
              dividerThickness: 0.2,
              columns: [
                const DataColumn(label: Text("TIME")),
                ...stations.map((s) => DataColumn(
                    label: InkWell(
                        onTap: () => onLogTap(s.name, groupRef),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: AppColors.neonBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.neonBlue.withValues(alpha: 0.3))),
                            child: Row(children: [
                              Text(s.name),
                              const SizedBox(width: 4),
                              const Icon(Icons.radar,
                                  size: 14, color: AppColors.neonBlue)
                            ])))))
              ],
              rows: sTimes
                  .map((t) => DataRow(cells: [
                        DataCell(Text(t, style: AppTextTheme.radarTime)),
                        ...stations.map((s) {
                          final shift = docs
                              .where((d) =>
                                  DateFormat('HH:mm').format(
                                          (d['start'] as Timestamp).toDate()) ==
                                      t &&
                                  d['station'] == s.name)
                              .firstOrNull;
                          return DataCell(InkWell(
                              onTap: isEditMode && shift != null
                                  ? () => onShiftEdit(
                                      shift, allGuards, stations, groupRef)
                                  : null,
                              child: Text(
                                  shift != null
                                      ? (shift['guards'] as List).join(", ")
                                      : "-",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isEditMode
                                          ? AppColors.warningOrange
                                          : Colors.white70))));
                        })
                      ]))
                  .toList()),
        ));
  }
}
