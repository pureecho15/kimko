import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/keys.dart';
import 'tasks_list_screen.dart';
import 'kimiko_screen.dart';
import 'brainstorming_screen.dart';
import 'you_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    systemNavigationBarColor:  Color(0xFF0D0D0D),
  ));

  // Credentials are pulled from lib/config/keys.dart (gitignored).
  await Supabase.initialize(
    url:     supabaseUrl,
    anonKey: supabaseAnonKey,
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

  // Wired up the actual screens instead of placeholder widgets.
  static const _screens = [
    TasksListScreen(),
    KimikoScreen(),
    BrainstormingScreen(),
    YouScreen(),
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