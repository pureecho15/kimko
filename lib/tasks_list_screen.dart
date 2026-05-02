import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/keys.dart';
import 'task_detail_screen.dart';

const _bg            = Color(0xFF0D0D0D);
const _surface       = Color(0xFF1A1A1A);
const _surfaceHigh   = Color(0xFF242424);
const _border        = Color(0xFF2A2A2A);
const _textPrimary   = Color(0xFFEAEAEA);
const _textSecondary = Color(0xFF666666);
const _accent        = Color(0xFFB388FF);
// User ID sourced from config/keys.dart (kBypassUserId)

final _supabase = Supabase.instance.client;

Color _priorityColor(int p) => switch (p) {
  5 => const Color(0xFFFF3B30),
  4 => const Color(0xFFFF9500),
  3 => const Color(0xFFFFCC00),
  2 => const Color(0xFF30D158),
  _ => const Color(0xFF48484A),
};

class Task {
  final String id;
  final String name;
  final int    priority;
  final bool   checkedToday;

  const Task({
    required this.id,
    required this.name,
    required this.priority,
    required this.checkedToday,
  });

  factory Task.fromMap(Map<String, dynamic> m, {bool checkedToday = false}) => Task(
    id:           m['id'] as String,
    name:         m['name'] as String,
    priority:     (m['priority'] as num).toInt(),
    checkedToday: checkedToday,
  );
}

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  List<Task> _tasks         = [];
  Set<String> _todayChecked = {};
  bool    _loading          = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final taskRows = await _supabase
          .from('tasks')
          .select('id, name, priority, created_at')
          .eq('user_id', kBypassUserId)
          .eq('status', 'active')
          .order('priority', ascending: false)
          .order('created_at');

      final now      = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

      final contribRows = await _supabase
          .from('micro_contributions')
          .select('task_id')
          .eq('user_id', kBypassUserId)
          .eq('logged_date', todayStr);

      final checkedIds = <String>{
        for (final r in contribRows as List) r['task_id'] as String,
      };

      if (!mounted) return;
      setState(() {
        _todayChecked = checkedIds;
        _tasks = (taskRows as List)
            .map((r) => Task.fromMap(r, checkedToday: checkedIds.contains(r['id'])))
            .toList();
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createTask({
    required String name,
    required int    priority,
    int?    timeBudgetHours,
    String? purpose,
  }) async {
    try {
      await _supabase.from('tasks').insert({
        'user_id':  kBypassUserId,
        'name':     name,
        'priority': priority,
        'status':   'active',
        if (timeBudgetHours != null) 'time_budget_mins': timeBudgetHours * 60,
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      });
      await _loadTasks();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showSnack('Error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: _surface, behavior: SnackBarBehavior.floating),
  );

  void _openAddSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddTaskSheet(onCreate: _createTask),
    );
  }

  void _openTaskDetail(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: task.id, taskName: task.name),
      ),
    ).then((_) => _loadTasks()); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFAB(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    title: const Text('Kimiko',
      style: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
    actions: [
      if (!_loading && _error == null)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Text(
              '${_tasks.where((t) => t.checkedToday).length}/${_tasks.length}',
              style: const TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: _textSecondary, size: 20),
        onPressed: _loadTasks,
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _border),
    ),
  );

  Widget _buildFAB() => FloatingActionButton(
    backgroundColor: _accent,
    foregroundColor: Colors.black,
    elevation: 0,
    shape: const CircleBorder(),
    onPressed: _openAddSheet,
    child: const Icon(Icons.add, size: 28),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(_error!,
            style: const TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: _loadTasks,
          child: const Text('Retry', style: TextStyle(color: _accent))),
      ]));
    }
    if (_tasks.isEmpty) {
      return const Center(
        child: Text('No active tasks.\nTap + to begin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSecondary, fontSize: 15, height: 1.6)),
      );
    }
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: _loadTasks,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => Container(height: 1, color: _border),
        itemBuilder: (_, i) => _TaskRow(
          task: _tasks[i],
          onTap: () => _openTaskDetail(_tasks[i]),
        ),
      ),
    );
  }
}

// ── Task Row ──────────────────────────────────
class _TaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const _TaskRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    splashColor: Colors.white.withOpacity(0.03),
    highlightColor: Colors.white.withOpacity(0.02),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        _PriorityDot(priority: task.priority),
        const SizedBox(width: 14),
        Expanded(
          child: Text(task.name,
            style: TextStyle(
              color: task.checkedToday ? _textSecondary : _textPrimary,
              fontSize: 15,
              decoration: task.checkedToday ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: _textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 16),
        _CheckRing(checked: task.checkedToday, priority: task.priority),
      ]),
    ),
  );
}

class _PriorityDot extends StatelessWidget {
  final int priority;
  const _PriorityDot({required this.priority});
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
      color: _priorityColor(priority),
      shape: BoxShape.circle,
      boxShadow: priority >= 4
          ? [BoxShadow(color: _priorityColor(priority).withOpacity(0.5), blurRadius: 6)]
          : null,
    ),
  );
}

class _CheckRing extends StatelessWidget {
  final bool checked;
  final int  priority;
  const _CheckRing({required this.checked, required this.priority});
  @override
  Widget build(BuildContext context) {
    const size = 22.0; const stroke = 2.0;
    final color = _priorityColor(priority);
    return SizedBox(width: size, height: size,
      child: CustomPaint(
        painter: _RingPainter(checked: checked, ringColor: color, strokeWidth: stroke),
        child: checked ? Icon(Icons.check, size: size * 0.55, color: color) : null,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final bool checked; final Color ringColor; final double strokeWidth;
  const _RingPainter({required this.checked, required this.ringColor, required this.strokeWidth});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - strokeWidth) / 2;
    if (checked) canvas.drawCircle(c, r, Paint()..color = ringColor.withOpacity(0.12));
    canvas.drawCircle(c, r, Paint()
      ..color = checked ? ringColor : const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true);
  }
  @override
  bool shouldRepaint(_RingPainter o) => o.checked != checked || o.ringColor != ringColor;
}

// ── Add Task Sheet ─────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required int    priority,
    int?    timeBudgetHours,
    String? purpose,
  }) onCreate;
  const _AddTaskSheet({required this.onCreate});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _nameCtrl    = TextEditingController();
  final _hoursCtrl   = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _nameFocus   = FocusNode();

  int     _priority        = 3;
  bool    _creating        = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _nameFocus.requestFocus());
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _hoursCtrl.dispose();
    _purposeCtrl.dispose(); _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _validationError = 'Task name cannot be empty.'); return; }
    final hours   = int.tryParse(_hoursCtrl.text.trim());
    final purpose = _purposeCtrl.text.trim();
    HapticFeedback.mediumImpact();
    setState(() { _creating = true; _validationError = null; });
    await widget.onCreate(
      name: name, priority: _priority,
      timeBudgetHours: hours,
      purpose: purpose.isEmpty ? null : purpose,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + inset),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
          )),
          const Text('New Task', style: TextStyle(
            color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const SizedBox(height: 20),

          _SheetLabel('TASK NAME'),
          const SizedBox(height: 8),
          _SheetField(controller: _nameCtrl, focusNode: _nameFocus,
            hint: 'What needs to be done?', hasError: _validationError != null,
            onChanged: (_) { if (_validationError != null) setState(() => _validationError = null); },
            onSubmitted: (_) => _submit()),
          if (_validationError != null) ...[
            const SizedBox(height: 6),
            Text(_validationError!, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12)),
          ],
          const SizedBox(height: 20),

          _SheetLabel('TIME BUDGET (HOURS)'),
          const SizedBox(height: 8),
          _SheetField(controller: _hoursCtrl, hint: 'e.g. 100',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 20),

          _SheetLabel('PURPOSE'),
          const SizedBox(height: 8),
          _SheetField(controller: _purposeCtrl,
            hint: 'Why does this task matter?', maxLines: 3),
          const SizedBox(height: 24),

          _SheetLabel('PRIORITY'),
          const SizedBox(height: 10),
          Row(children: List.generate(5, (i) {
            final p = i + 1; final sel = _priority == p;
            final c = _priorityColor(p);
            return Expanded(child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _priority = p); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? c.withOpacity(0.15) : _surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? c.withOpacity(0.7) : _border, width: sel ? 1.5 : 1),
                  boxShadow: sel && p >= 4 ? [BoxShadow(color: c.withOpacity(0.25), blurRadius: 8)] : null,
                ),
                child: Center(child: Text('$p', style: TextStyle(
                  color: sel ? c : _textSecondary, fontSize: 15,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400))),
              ),
            ));
          })),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity,
            child: GestureDetector(
              onTap: _creating ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _creating ? _accent.withOpacity(0.4) : _accent,
                  borderRadius: BorderRadius.circular(14)),
                child: Center(child: _creating
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Create Task', style: TextStyle(
                        color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700))),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2));
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode?            focusNode;
  final String                hint;
  final bool                  hasError;
  final TextInputType         keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final int                   maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _SheetField({
    required this.controller,
    this.focusNode,
    required this.hint,
    this.hasError        = false,
    this.keyboardType    = TextInputType.text,
    this.inputFormatters = const [],
    this.maxLines        = 1,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: hasError ? const Color(0xFFFF3B30).withOpacity(0.6) : _border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    child: TextField(
      controller: controller, focusNode: focusNode,
      keyboardType: keyboardType, inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      cursorColor: _accent,
      textCapitalization: TextCapitalization.sentences,
      onChanged: onChanged, onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textSecondary, fontSize: 15),
        border: InputBorder.none, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}