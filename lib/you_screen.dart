import 'package:flutter/material.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('The Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFF2A2A2A))),
      ),
      body: Center(
        child: Text('Global Analytics & Settings\nComing Soon', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF666666), fontSize: 16)),
      ),
    );
  }
}