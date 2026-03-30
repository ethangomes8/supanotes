import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supanote/myhomepage.dart';
import 'package:supanote/login_screen.dart';


Future<void> main() async {
  try {
    await Supabase.initialize(
      url: 'https://tlhlzovftqgapavtrfgr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRsaGx6b3ZmdHFnYXBhdnRyZmdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNjM3MjUsImV4cCI6MjA3ODkzOTcyNX0.cw-B_QLrJCnzfxZB7bh5AYE3bzLrR4FhJp39AQSuK14',
    );
    runApp(const MyApp());
  } catch (e) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erreur de connexion. Veuillez redémarrer l\'application.'),
          ),
        ),
      ),
    );
  }
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = supabase.auth.currentUser;
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _user = data.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supanotes',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => _user != null ? const MyHomePage(title: 'SupaNotes') : const LoginScreen(),
        '/home': (context) => const MyHomePage(title: 'SupaNotes'),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

