// brainstorming_screen.dart - FULL UPDATE
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_thread_screen.dart';

class BrainstormingScreen extends StatefulWidget {
  const BrainstormingScreen({super.key});
  @override
  State<BrainstormingScreen> createState() => _BrainstormingScreenState();
}

class _BrainstormingScreenState extends State<BrainstormingScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetchTasks(); }

  Future<void> _fetchTasks() async {
    final data = await _supabase.from('tasks').select().eq('status', 'active');
    setState(() { _tasks = data as List; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(backgroundColor: const Color(0xFF0D0D0D), title: const Text('Active Brainstorms', style: TextStyle(color: Colors.white))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.forum_outlined, color: Color(0xFFB388FF)),
          title: Text(_tasks[i]['name'], style: const TextStyle(color: Colors.white)),
          subtitle: const Text('Tap to start brainstorming with Kimiko', style: TextStyle(color: Color(0xFF666666))),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatThreadScreen(taskId: _tasks[i]['id'], taskName: _tasks[i]['name']))),
        ),
      ),
    );
  }
}