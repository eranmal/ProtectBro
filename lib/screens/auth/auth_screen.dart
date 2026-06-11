import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; 
  bool _isLoading = false;

  // כניסה מהירה עם גוגל (עבור Web)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      // משתמשים ב-Popup כי האפליקציה רצה בדפדפן
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("שגיאה בכניסת גוגל: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("אנא הזן מייל תקין וסיסמה בת 6 תווים לפחות")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "אירעה שגיאה"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141A14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // שימוש ב-Emoji במקום תמונה כפי שביקשת
              const Text(
                '🎖️',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'כניסה ל-ProtectBro' : 'הצטרפות לצוות',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              
              // כפתור כניסה עם גוגל
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.green),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.login, color: Colors.greenAccent),
                label: const Text("כניסה מהירה עם Google"),
                onPressed: _isLoading ? null : _signInWithGoogle,
              ),
              
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("או", style: TextStyle(color: Colors.grey))),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'אימייל',
                  labelStyle: TextStyle(color: Colors.greenAccent),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'סיסמה',
                  labelStyle: TextStyle(color: Colors.greenAccent),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.greenAccent)
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50)
                  ),
                  onPressed: _submit,
                  child: Text(_isLogin ? 'התחבר' : 'צור חשבון'),
                ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'אין חשבון? הרשמה' : 'כבר רשום? התחברות',
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}