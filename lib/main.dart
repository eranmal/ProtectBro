import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProtectBroApp());
}

class ProtectBroApp extends StatelessWidget {
  const ProtectBroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('he', 'IL'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('he', 'IL')],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D09),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF87),
          brightness: Brightness.dark,
          primary: const Color(0xFF00FF87),
          secondary: const Color(0xFF00B8FF),
          surface: const Color(0xFF111A11),
        ),
        textTheme:
            GoogleFonts.heeboTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white70,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090D09),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
