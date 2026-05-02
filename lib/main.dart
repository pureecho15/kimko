import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tasks_list_screen.dart';
import 'brainstorming_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  Color(0xFF0D0D0D),
  ));

  await Supabase.initialize(
    url:     'https://osveifptdeeckjaqrofe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zdmVpZnB0ZGVlY2tqYXFyb2ZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjE3NTgsImV4cCI6MjA5MzE5Nzc1OH0.rLR7TSgQbyKNREE_Upq-CV2RptjjmpVFX1ggNnWAXZw',
  );

  runApp(const KimikoApp());
}

final supabase = Supabase.instance.client;

class KimikoApp extends StatelessWidget {
  const KimikoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Kimiko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        splashFactory: InkRipple.splashFactory,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    TasksListScreen(),
    _KimikoPlaceholder(),
    BrainstormingScreen(),
    _YouPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFB388FF).withOpacity(0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded, color: Color(0xFF666666)),
            selectedIcon: Icon(Icons.checklist_rounded, color: Color(0xFFB388FF)),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined, color: Color(0xFF666666)),
            selectedIcon: Icon(Icons.bolt_rounded, color: Color(0xFFB388FF)),
            label: 'Kimiko',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined, color: Color(0xFF666666)),
            selectedIcon: Icon(Icons.forum_rounded, color: Color(0xFFB388FF)),
            label: 'War Room',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Color(0xFF666666)),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFB388FF)),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

// ── Placeholder tabs (build out later) ───────
class _KimikoPlaceholder extends StatelessWidget {
  const _KimikoPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0D0D0D),
    body: Center(
      child: Text('Kimiko AI Enforcer\nComing next.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.6)),
    ),
  );
}

class _YouPlaceholder extends StatelessWidget {
  const _YouPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0D0D0D),
    body: Center(
      child: Text('The Ledger\nComing next.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.6)),
    ),
  );
}