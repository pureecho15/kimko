import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/keys.dart';

const _bg            = Color(0xFF0D0D0D);
const _surface       = Color(0xFF1A1A1A);
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

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class _TaskDetail {
  final String id;
  final String name;
  final int    priority;
  final int?   timeBudgetMins;
  final String purpose;
  final double checkTargetValue;
  final String checkMetricLabel;

  const _TaskDetail({
    required this.id,
    required this.name,
    required this.priority,
    this.timeBudgetMins,
    required this.purpose,
    required this.checkTargetValue,
    required this.checkMetricLabel,
  });

  factory _TaskDetail.fromMap(Map<String, dynamic> m) => _TaskDetail(
    id:               m['id'] as String,
    name:             m['name'] as String,
    priority:         (m['priority'] as num).toInt(),
    timeBudgetMins:   m['time_budget_mins'] as int?,
    purpose:          m['purpose'] as String? ?? '—',
    checkTargetValue: (m['check_target_value'] as num?)?.toDouble() ?? 1.0,
    checkMetricLabel: m['check_metric_label'] as String? ?? 'units',
  );
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String taskName; // shown instantly while loading

  const TaskDetailScreen({super.key, required this.taskId, required this.taskName});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with SingleTickerProviderStateMixin {

  _TaskDetail?   _task;
  List<double>   _last7 = List.filled(7, 0.0);
  double         _totalLogged = 0;
  int            _streak = 0;
  int            _kimikoCount = 0;
  bool           _loading = true;
  String?        _error;

  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  late AnimationController _logAnim;
  late Animation<double>   _logScale;
  bool _loggedThisSession = false;

  @override
  void initState() {
    super.initState();
    _logAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _logScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _logAnim, curve: Curves.easeInOut));
    _loadAll();
  }

  @override
  void dispose() {
    _inputCtrl.dispose(); _inputFocus.dispose(); _logAnim.dispose();
    super.dispose();
  }

  // ── Load everything ───────────────────────
  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Task details
      final taskRow = await _supabase
          .from('tasks')
          .select()
          .eq('id', widget.taskId)
          .single();

      // All contributions for this task
      final contribs = await _supabase
          .from('micro_contributions')
          .select('logged_date, value')
          .eq('task_id', widget.taskId)
          .order('logged_date', ascending: false);

      // Kimiko interventions
      final kimikoRows = await _supabase
          .from('action_queue')
          .select('id')
          .eq('task_id', widget.taskId);

      if (!mounted) return;

      final detail = _TaskDetail.fromMap(taskRow);
      final contribList = contribs as List;

      // Total logged
      final total = contribList.fold<double>(
        0, (sum, r) => sum + ((r['value'] as num?)?.toDouble() ?? 0));

      // Last 7 days
      final today = DateTime.now();
      final last7 = List<double>.filled(7, 0.0);
      for (int i = 0; i < 7; i++) {
        final d = today.subtract(Duration(days: 6 - i));
        final ds = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        final match = contribList.where((r) => r['logged_date'] == ds);
        if (match.isNotEmpty) {
          last7[i] = (match.first['value'] as num?)?.toDouble() ?? 0;
        }
      }

      // Streak: count consecutive days going back from today that have a log
      int streak = 0;
      final dateSet = <String>{for (final r in contribList) r['logged_date'] as String};
      for (int i = 0; i <= 365; i++) {
        final d  = today.subtract(Duration(days: i));
        final ds = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        if (dateSet.contains(ds)) { streak++; } else { break; }
      }

      setState(() {
        _task        = detail;
        _last7       = last7;
        _totalLogged = total;
        _streak      = streak;
        _kimikoCount = (kimikoRows as List).length;
        _loading     = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Log contribution ──────────────────────
  Future<void> _logContribution() async {
    final raw   = _inputCtrl.text.trim();
    final value = double.tryParse(raw);
    if (value == null || value <= 0) { _inputFocus.requestFocus(); return; }

    HapticFeedback.mediumImpact();
    _logAnim.forward().then((_) => _logAnim.reverse());

    final now    = DateTime.now();
    final today  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    try {
      // Upsert (unique index on task_id + logged_date)
      await _supabase.from('micro_contributions').upsert({
        'task_id':     widget.taskId,
        'user_id':     kBypassUserId,
        'logged_date': today,
        'value':       value,
      }, onConflict: 'task_id,logged_date');

      _inputCtrl.clear();
      setState(() {
        _loggedThisSession = true;
        _last7[6] = (_last7[6] + value);
        _totalLogged += value;
      });
    } on PostgrestException catch (e) {
      _showSnack('Log failed: ${e.message}');
    } catch (e) {
      _showSnack('Log failed: $e');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: _surface, behavior: SnackBarBehavior.floating));

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _bg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textSecondary),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(widget.taskName,
      style: const TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: [
      if (_task != null)
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _priorityColor(_task!.priority).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _priorityColor(_task!.priority).withOpacity(0.4)),
          ),
          child: Text('P${_task!.priority}', style: TextStyle(
            color: _priorityColor(_task!.priority), fontSize: 12, fontWeight: FontWeight.w700)),
        ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _border)),
  );

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 1.5));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(_error!, style: const TextStyle(color: _textSecondary, fontSize: 13),
          textAlign: TextAlign.center)),
      const SizedBox(height: 16),
      TextButton(onPressed: _loadAll, child: const Text('Retry', style: TextStyle(color: _accent))),
    ]));

    final task = _task!;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _PillarsGrid(task: task),
          const SizedBox(height: 28),
          _SectionLabel('TODAY\'S CONTRIBUTION'),
          const SizedBox(height: 12),
          _InputEngine(
            task: task,
            controller: _inputCtrl,
            focusNode: _inputFocus,
            logScale: _logScale,
            loggedThisSession: _loggedThisSession,
            totalLogged: _totalLogged,
            onLog: _logContribution,
          ),
          const SizedBox(height: 32),
          _SectionLabel('VELOCITY TIMELINE · LAST 7 DAYS'),
          const SizedBox(height: 12),
          _VelocityChart(
            data: _last7,
            target: task.checkTargetValue,
            accentColor: _priorityColor(task.priority),
          ),
          const SizedBox(height: 28),
          _SectionLabel('VITAL SIGNS'),
          const SizedBox(height: 12),
          _VitalSigns(
            task: task,
            totalLogged: _totalLogged,
            streak: _streak + (_loggedThisSession ? 1 : 0),
            kimikoCount: _kimikoCount,
          ),
        ],
      ),
    );
  }
}

// ── Pillars Grid ──────────────────────────────
class _PillarsGrid extends StatelessWidget {
  final _TaskDetail task;
  const _PillarsGrid({required this.task});

  @override
  Widget build(BuildContext context) {
    final timeLabel = task.timeBudgetMins != null
        ? '${(task.timeBudgetMins! / 60).round()} Hrs'
        : '—';
    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border)),
      child: Column(children: [
        IntrinsicHeight(child: Row(children: [
          Expanded(child: _PillarCell(icon: Icons.schedule_rounded, label: 'TIME',
            value: timeLabel, accent: const Color(0xFF64D2FF), rightBorder: true)),
          Expanded(child: _PillarCell(icon: Icons.bolt_rounded, label: 'PRIORITY',
            value: 'Level ${task.priority}', accent: _priorityColor(task.priority))),
        ])),
        Container(height: 1, color: _border),
        IntrinsicHeight(child: Row(children: [
          Expanded(child: _PillarCell(icon: Icons.my_location_rounded, label: 'PURPOSE',
            value: task.purpose, accent: const Color(0xFFFF9F0A), rightBorder: true, isMultiLine: true)),
          Expanded(child: _PillarCell(icon: Icons.check_circle_outline_rounded, label: 'CHECK',
            value: '${task.checkTargetValue.toInt()} ${task.checkMetricLabel} / day', accent: _accent)),
        ])),
      ]),
    );
  }
}

class _PillarCell extends StatelessWidget {
  final IconData icon; final String label; final String value;
  final Color accent; final bool rightBorder; final bool isMultiLine;
  const _PillarCell({
    required this.icon, required this.label, required this.value,
    required this.accent, this.rightBorder = false, this.isMultiLine = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: rightBorder ? const Border(right: BorderSide(color: _border)) : null),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 12, color: accent),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
      ]),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
        maxLines: isMultiLine ? 3 : 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Input Engine ──────────────────────────────
class _InputEngine extends StatelessWidget {
  final _TaskDetail task;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Animation<double> logScale;
  final bool loggedThisSession;
  final double totalLogged;
  final VoidCallback onLog;

  const _InputEngine({
    required this.task, required this.controller, required this.focusNode,
    required this.logScale, required this.loggedThisSession,
    required this.totalLogged, required this.onLog});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border)),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Log in ${task.checkMetricLabel}',
        style: const TextStyle(color: _textSecondary, fontSize: 12)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(
          controller: controller, focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -1),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: _border, fontSize: 28, fontWeight: FontWeight.w300),
            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            suffixText: task.checkMetricLabel,
            suffixStyle: const TextStyle(color: _textSecondary, fontSize: 14),
          ),
        )),
        const SizedBox(width: 12),
        ScaleTransition(scale: logScale,
          child: GestureDetector(onTap: onLog,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: loggedThisSession ? const Color(0xFF30D158).withOpacity(0.15) : _accent,
                borderRadius: BorderRadius.circular(12),
                border: loggedThisSession ? Border.all(color: const Color(0xFF30D158).withOpacity(0.4)) : null,
              ),
              child: loggedThisSession
                  ? const Icon(Icons.check_rounded, color: Color(0xFF30D158), size: 22)
                  : const Text('Log', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          )),
      ]),
      const SizedBox(height: 14),
      _MicroProgressBar(
        logged: totalLogged,
        target: task.checkTargetValue * 200, // rough lifetime target proxy
        color: _priorityColor(task.priority),
      ),
    ]),
  );
}

class _MicroProgressBar extends StatelessWidget {
  final double logged; final double target; final Color color;
  const _MicroProgressBar({required this.logged, required this.target, required this.color});

  String _fmt(double v) => v >= 1000 ? '${(v/1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final pct = (logged / target).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${_fmt(logged)} total logged',
          style: const TextStyle(color: _textSecondary, fontSize: 11)),
        Text('${(pct * 100).toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct, minHeight: 3,
          backgroundColor: _border,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        )),
    ]);
  }
}

// ── Velocity Chart ────────────────────────────
class _VelocityChart extends StatelessWidget {
  final List<double> data;
  final double target;
  final Color accentColor;
  const _VelocityChart({required this.data, required this.target, required this.accentColor});

  List<String> _dayLabels() {
    const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return i == 6 ? 'Today' : names[d.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = _dayLabels();
    return Container(
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border)),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(children: [
        SizedBox(height: 120,
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _VelocityPainter(data: data, target: target, lineColor: accentColor),
          )),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.asMap().entries.map((e) {
            final isToday = e.key == 6;
            return Text(e.value, style: TextStyle(
              color: isToday ? accentColor : _textSecondary,
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            ));
          }).toList(),
        ),
      ]),
    );
  }
}

class _VelocityPainter extends CustomPainter {
  final List<double> data;
  final double target;
  final Color lineColor;
  const _VelocityPainter({required this.data, required this.target, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = data.reduce(math.max).clamp(target, double.infinity) * 1.15;
    final w = size.width; final h = size.height; final n = data.length;

    Offset pt(int i, double v) => Offset((i / (n - 1)) * w, h - (v / maxV) * h);

    // Dashed target line
    final targetY = h - (target / maxV) * h;
    const dashW = 6.0; const gapW = 5.0;
    final dashPaint = Paint()..color = lineColor.withOpacity(0.25)..strokeWidth = 1..style = PaintingStyle.stroke;
    double dx = 0;
    while (dx < w) {
      canvas.drawLine(Offset(dx, targetY), Offset(math.min(dx + dashW, w), targetY), dashPaint);
      dx += dashW + gapW;
    }

    // Zero dots
    for (int i = 0; i < n; i++) {
      if (data[i] == 0) canvas.drawCircle(pt(i, 0), 3.5, Paint()..color = const Color(0xFF2C2C2E)..style = PaintingStyle.fill);
    }

    // Build Catmull-Rom path
    final pts = List.generate(n, (i) => pt(i, data[i]));
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i-1] : pts[i];
      final p1 = pts[i]; final p2 = pts[i+1];
      final p3 = i+2 < pts.length ? pts[i+2] : pts[i+1];
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx)/6, p1.dy + (p2.dy - p0.dy)/6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx)/6, p2.dy - (p3.dy - p1.dy)/6);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Gradient fill
    final fill = Path.from(path)..lineTo(pts.last.dx, h)..lineTo(pts.first.dx, h)..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill);

    // Stroke
    canvas.drawPath(path, Paint()
      ..color = lineColor ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round ..isAntiAlias = true);

    // End-point dot
    final last = pts.last;
    canvas.drawCircle(last, 6,  Paint()..color = lineColor.withOpacity(0.2));
    canvas.drawCircle(last, 3.5, Paint()..color = lineColor);
    canvas.drawCircle(last, 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_VelocityPainter o) => o.data != data || o.target != target;
}

// ── Vital Signs ───────────────────────────────
class _VitalSigns extends StatelessWidget {
  final _TaskDetail task;
  final double totalLogged;
  final int streak;
  final int kimikoCount;
  const _VitalSigns({required this.task, required this.totalLogged, required this.streak, required this.kimikoCount});

  String _fmt(double v) => v >= 1000 ? '${(v/1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border)),
    child: IntrinsicHeight(child: Row(children: [
      Expanded(child: _StatCell(label: 'STREAK', value: '$streak',
        unit: 'days', accent: const Color(0xFFFF9F0A), rightBorder: true)),
      Expanded(child: _StatCell(label: 'TOTAL', value: _fmt(totalLogged),
        unit: task.checkMetricLabel, accent: _accent, rightBorder: true)),
      Expanded(child: _StatCell(label: 'KIMIKO', value: '$kimikoCount',
        unit: 'calls', accent: const Color(0xFFFF3B30))),
    ])),
  );
}

class _StatCell extends StatelessWidget {
  final String label, value, unit;
  final Color accent;
  final bool rightBorder;
  const _StatCell({required this.label, required this.value, required this.unit,
    required this.accent, this.rightBorder = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
    decoration: BoxDecoration(
      border: rightBorder ? const Border(right: BorderSide(color: _border)) : null),
    child: Column(children: [
      Text(label, style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      const SizedBox(height: 8),
      Text(value, textAlign: TextAlign.center,
        style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(unit, style: const TextStyle(color: _textSecondary, fontSize: 10)),
    ]),
  );
}

// ── Section Label ─────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2));
}