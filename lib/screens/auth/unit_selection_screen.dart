import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/main_manager_screen.dart'; // לצורך ניווט ל-MainManagerScreen

class UnitSelectionScreen extends StatefulWidget {
  const UnitSelectionScreen({super.key});

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  final _codeController = TextEditingController();
  final _groupNameController = TextEditingController();
  String _selectedRole = 'שומר'; 
  bool _isLoading = false;

  Future<void> _joinUnit() async {
    if (_codeController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      // חיפוש יחידה לפי קוד מפקד או קוד שומר
      var adminQuery = await FirebaseFirestore.instance.collection('groups')
          .where('adminCode', isEqualTo: _codeController.text).get();
      
      bool isAdmin = adminQuery.docs.isNotEmpty;
      var targetDoc = isAdmin ? adminQuery.docs.first : null;

      if (!isAdmin) {
        var userQuery = await FirebaseFirestore.instance.collection('groups')
            .where('userCode', isEqualTo: _codeController.text).get();
        if (userQuery.docs.isNotEmpty) targetDoc = userQuery.docs.first;
      }

      if (targetDoc == null) {
        throw Exception("קוד יחידה לא נמצא");
      }

      String groupId = targetDoc.id;
      String groupName = targetDoc['groupName'];

      // שמירת השיוך של המשתמש ב-Database
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'email': user.email,
        'unitId': groupId,
        'role': _selectedRole,
        'isAdmin': isAdmin,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (c) => MainManagerScreen(groupId: groupId, isAdmin: isAdmin, groupName: groupName)
      ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('זיהוי מחלקתי'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.group_work, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'קוד יחידה (מפקד/שומר)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['שומר', 'מפקד תורן', 'סמל מחלקה']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
              decoration: const InputDecoration(labelText: 'הגדר את תפקידך', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            if (_isLoading) 
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _joinUnit, 
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('התחבר ליחידה')
              ),
          ],
        ),
      ),
    );
  }
}