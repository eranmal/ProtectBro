import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/cyber_button.dart';
import '../../widgets/cyber_text_field.dart';
import '../../widgets/glass_history_card.dart';
import '../home/main_manager_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _savedGroups = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tactical_history_vFinal');
    if (raw != null) {
      setState(() =>
          _savedGroups = List<Map<String, dynamic>>.from(json.decode(raw)));
    }
  }

  void _completeLogin(String id, String name, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    _savedGroups.removeWhere((g) => g['id'] == id);
    _savedGroups.insert(0, {'id': id, 'name': name, 'isAdmin': isAdmin});
    await prefs.setString('tactical_history_vFinal', json.encode(_savedGroups));
    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => MainManagerScreen(
                groupId: id, isAdmin: isAdmin, groupName: name)));
  }

  void _promptForCode(Map<String, dynamic> group) {
    final TextEditingController verifyController = TextEditingController();
    bool isVerifying = false;

    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text("כניסה ליחידה: ${group['name']}"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(group['isAdmin']
                        ? "הכנס קוד מפקד להמשך:"
                        : "הכנס קוד שומר להמשך:"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: verifyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: "קוד גישה", border: OutlineInputBorder()),
                    ),
                    if (isVerifying)
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator())
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("ביטול")),
                  ElevatedButton(
                    onPressed: isVerifying
                        ? null
                        : () async {
                            setStateDialog(() => isVerifying = true);
                            try {
                              var doc = await FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(group['id'])
                                  .get();
                              if (doc.exists) {
                                String expectedCode = group['isAdmin']
                                    ? doc['adminCode']
                                    : doc['userCode'];
                                if (verifyController.text == expectedCode) {
                                  Navigator.pop(c);
                                  _completeLogin(group['id'], group['name'],
                                      group['isAdmin']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("קוד שגוי"),
                                          backgroundColor: Colors.red));
                                  setStateDialog(() => isVerifying = false);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "היחידה לא נמצאה במסד הנתונים"),
                                        backgroundColor: Colors.red));
                                setStateDialog(() => isVerifying = false);
                              }
                            } catch (e) {
                              setStateDialog(() => isVerifying = false);
                            }
                          },
                    child: const Text("היכנס"),
                  )
                ],
              );
            }));
  }

  void _createNewGroup() async {
    if (_nameController.text.isEmpty) return;
    String ac = (100000 + Random().nextInt(899999)).toString();
    String uc = (100000 + Random().nextInt(899999)).toString();
    var d = await FirebaseFirestore.instance.collection('groups').add({
      'groupName': _nameController.text,
      'adminCode': ac,
      'userCode': uc,
      'createdAt': Timestamp.now()
    });
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
                title: const Text("היחידה הוקמה!"),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("רשום את הקודים:"),
                      const SizedBox(height: 10),
                      Text("🔑 קוד מפקד: $ac",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent)),
                      Text("👤 קוד שומר: $uc",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent)),
                    ]),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(c);
                        _completeLogin(d.id, _nameController.text, true);
                      },
                      child: const Text("כניסה"))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF0F2012), Color(0xFF090D09)],
                  center: Alignment.topCenter,
                  radius: 1.5,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.military_tech,
                        size: 90, color: Color(0xFF00FF87)),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          duration: 2.seconds,
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.05, 1.05))
                      .shimmer(duration: 2.seconds, color: Colors.white24),
                  const SizedBox(height: 20),
                  Text(
                    "PROTECT BRO",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.5),
                  const SizedBox(height: 8),
                  Text("TACTICAL SHIFT MANAGER",
                          style: TextStyle(
                              color: const Color(0xFF00FF87).withValues(alpha: 0.8),
                              letterSpacing: 2))
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 50),
                  if (_savedGroups.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Text("יחידות שנשמרו",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold))
                          .animate()
                          .fadeIn(delay: 600.ms),
                    ),
                    const SizedBox(height: 10),
                    ..._savedGroups.map((g) => GlassHistoryCard(
                          group: g,
                          onTap: () => _promptForCode(g),
                          onDelete: () async {
                            setState(() => _savedGroups.remove(g));
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('tactical_history_vFinal',
                                json.encode(_savedGroups));
                          },
                        )),
                    const SizedBox(height: 30),
                  ],
                  CyberTextField(
                          controller: _codeController,
                          label: "הזן קוד יחידה (מפקד / שומר)",
                          icon: Icons.key_rounded)
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .slideX(begin: -0.2),
                  const SizedBox(height: 20),
                  CyberButton(
                      text: "התחבר ליחידה קיימת",
                      icon: Icons.login,
                      onPressed: () async {
                        var a = await FirebaseFirestore.instance
                            .collection('groups')
                            .where('adminCode', isEqualTo: _codeController.text)
                            .get();
                        if (a.docs.isNotEmpty) {
                          _completeLogin(
                              a.docs.first.id, a.docs.first['groupName'], true);
                          return;
                        }
                        var u = await FirebaseFirestore.instance
                            .collection('groups')
                            .where('userCode', isEqualTo: _codeController.text)
                            .get();
                        if (u.docs.isNotEmpty) {
                          _completeLogin(u.docs.first.id,
                              u.docs.first['groupName'], false);
                          return;
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("קוד גישה שגוי"),
                                  backgroundColor: Colors.redAccent));
                        }
                      }).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.2),
                  const SizedBox(height: 40),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),
                  CyberTextField(
                          controller: _nameController,
                          label: "שם פלוגה חדשה להקמה",
                          icon: Icons.add_box_rounded)
                      .animate()
                      .fadeIn(delay: 1200.ms),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _createNewGroup,
                    icon: const Icon(Icons.add_circle_outline,
                        color: Color(0xFF00B8FF)),
                    label: const Text("הקם חמ\"ל חדש",
                        style: TextStyle(
                            color: Color(0xFF00B8FF),
                            fontWeight: FontWeight.bold)),
                  ).animate().fadeIn(delay: 1400.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
