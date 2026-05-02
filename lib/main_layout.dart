import 'package:flutter/material.dart';
import 'tasks_list_screen.dart';
import 'kimiko_screen.dart';
import 'brainstorming_screen.dart';
import 'you_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TasksListScreen(), // Pillar 1
    const KimikoScreen(),    // Pillar 2
    const BrainstormingScreen(), // Pillar 3
    const YouScreen(),       // Pillar 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0D0D0D),
        selectedItemColor: const Color(0xFFB388FF), // Kimiko Violet
        unselectedItemColor: const Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Kimiko'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Brainstorm'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'You'),
        ],
      ),
    );
  }
}