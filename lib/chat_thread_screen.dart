import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'config/keys.dart';

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
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom of the chat list after a short delay.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // 1. Save user message to Supabase
    await _supabase.from('war_room_chats').insert({
      'task_id': widget.taskId,
      'user_id': kBypassUserId,
      'role': 'user',
      'content': text,
    });

    if (!mounted) return;
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      // 2. Build conversation context from recent messages
      final recentMessages = await _supabase
          .from('war_room_chats')
          .select('role, content')
          .eq('task_id', widget.taskId)
          .order('created_at', ascending: true)
          .limit(20);

      final history = (recentMessages as List).map<Map<String, dynamic>>((msg) {
        final role = msg['role'] == 'user' ? 'user' : 'model';
        return {
          'role': role,
          'parts': [{'text': msg['content'] as String}],
        };
      }).toList();

      // Prepend a system-level instruction as the first user turn
      final contents = <Map<String, dynamic>>[
        {
          'role': 'user',
          'parts': [{'text': 'You are Kimiko, a helpful and energetic AI productivity enforcer. '
              'Help me brainstorm and execute this task: ${widget.taskName}. '
              'Be concise, actionable, and encouraging.'}],
        },
        {
          'role': 'model',
          'parts': [{'text': 'Understood! I\'m Kimiko, your AI enforcer. Let\'s crush this task: '
              '"${widget.taskName}". What do you need?'}],
        },
        ...history,
      ];

      // 3. Call Gemini API (v1beta endpoint for gemini-1.5-flash)
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents}),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Unknown API error (${response.statusCode})';
        throw Exception(errorMsg);
      }

      final data = jsonDecode(response.body);
      // Safely extract the AI reply text
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response candidates returned by the API.');
      }
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Empty response parts from the API.');
      }
      final aiText = parts[0]['text'] as String? ?? 'No reply generated.';

      // 4. Save AI reply to Supabase
      await _supabase.from('war_room_chats').insert({
        'task_id': widget.taskId,
        'user_id': kBypassUserId,
        'role': 'assistant',
        'content': aiText,
      });
    } catch (e) {
      // Persist a visible error message in the chat so the user sees feedback
      debugPrint('Gemini API error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kimiko could not reply: $e'),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Text(widget.taskName, style: const TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2A2A)),
        ),
      ),
      body: Column(children: [
        Expanded(child: StreamBuilder(
          stream: _supabase
              .from('war_room_chats')
              .stream(primaryKey: ['id'])
              .eq('task_id', widget.taskId)
              .order('created_at'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data as List;
            // Scroll to bottom when new messages arrive
            _scrollToBottom();
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final isUser = docs[i]['role'] == 'user';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1A1A1A) : const Color(0xFF2A1A3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser ? const Color(0xFF2A2A2A) : const Color(0xFFB388FF).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUser ? 'You' : 'Kimiko',
                        style: TextStyle(
                          color: isUser ? const Color(0xFF666666) : const Color(0xFFB388FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        docs[i]['content'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.purpleAccent.shade100,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        )),
        if (_isTyping)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Kimiko is thinking...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: const Color(0xFFB388FF),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ask Kimiko...',
                    hintStyle: TextStyle(color: Color(0xFF666666)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFFB388FF)),
                onPressed: _sendMessage,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}