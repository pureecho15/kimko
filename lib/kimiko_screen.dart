import 'package:flutter/material.dart';

class KimikoScreen extends StatelessWidget {
  const KimikoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Kimiko Command', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFF2A2A2A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('ACTIONABLE QUEUE', style: TextStyle(color: Color(0xFF666666), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          _buildAlertCard('UI Design Task ignored.', 'Priority 5 • Call Missed'),
          const SizedBox(height: 30),
          const Text('ACTIVITY FEED', style: TextStyle(color: Color(0xFF666666), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          _buildFeedItem('2:00 AM', 'Kimiko researched new UI trends.'),
          _buildFeedItem('Yesterday', 'Kimiko initiated a call for Workout task.'),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Boss?? You have a pending task??', style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(subtitle, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30), foregroundColor: Colors.white), child: const Text('Doing it now'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('Let\'s Chat', style: TextStyle(color: Colors.white)))),
        ])
      ]),
    );
  }

  Widget _buildFeedItem(String time, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Text(time, style: const TextStyle(color: Color(0xFFB388FF), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(width: 15),
        Expanded(child: Text(action, style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14))),
      ]),
    );
  }
}