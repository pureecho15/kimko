// chat_thread_screen.dart - FULL UPDATE
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class ChatThreadScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  const ChatThreadScreen({super.key, required this.taskId, required this.taskName});
  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  bool _isTyping = false;
  final String _geminiKey = 'AIzaSyBertTeN-NzFgvUsBhzN9BzDMGB37m65FM'; // <--- PASTE KEY HERE

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // 1. Save User Message
    await _supabase.from('war_room_chats').insert({
      'task_id': widget.taskId,
      'user_id': '00000000-0000-0000-0000-000000000000',
      'role': 'user',
      'content': text,
    });

    setState(() => _isTyping = true);

    try {
      // 2. Call Gemini (v1 STABLE)
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$_geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": "You are Kimiko, a helpful AI. Help me with: ${widget.taskName}. My message: $text"}]}]
        }),
      );

      final data = jsonDecode(response.body);
      final aiText = data['candidates'][0]['content']['parts'][0]['text'];

      // 3. Save AI Message
      await _supabase.from('war_room_chats').insert({
        'task_id': widget.taskId,
        'user_id': '00000000-0000-0000-0000-000000000000',
        'role': 'assistant',
        'content': aiText,
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(backgroundColor: const Color(0xFF0D0D0D), title: Text(widget.taskName, style: const TextStyle(color: Colors.white))),
      body: Column(children: [
        Expanded(child: StreamBuilder(
          stream: _supabase.from('war_room_chats').stream(primaryKey: ['id']).eq('task_id', widget.taskId).order('created_at'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data as List;
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(docs[i]['content'], style: TextStyle(color: docs[i]['role'] == 'user' ? Colors.white : Colors.purpleAccent)),
              ),
            );
          },
        )),
        if (_isTyping) const Text("Kimiko is thinking...", style: TextStyle(color: Colors.grey)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ask Kimiko...',
              suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ),
          ),
        ),
      ]),
    );
  }
}