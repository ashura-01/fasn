import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/hive_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/progress_ring.dart';

const List<String> kDayNames  = ['', 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
const List<String> kDayShort  = ['', 'Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});
  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDay = DateTime.now().weekday;
  Timer? _expireTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this, initialIndex: _selectedDay - 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedDay = _tabController.index + 1);
      }
    });
    _ensureAllDaysExist();
    _checkExpiredTasks();
    _expireTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkExpiredTasks());
  }

  Future<void> _ensureAllDaysExist() async {
    bool changed = false;
    for (int d = 1; d <= 7; d++) {
      if (HiveService.getRoutineForWeekday(d) == null) {
        final routine = DayRoutine(id: const Uuid().v4(), weekday: d, name: kDayNames[d]);
        await HiveService.saveRoutineDay(routine);
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _checkExpiredTasks() {
    final now = TimeOfDay.now();
    final today = DateTime.now().weekday;
    final routine = HiveService.getRoutineForWeekday(today);
    if (routine == null) return;
    bool changed = false;
    for (final task in routine.tasks) {
      if (!task.isChecked && !task.isExpired) {
        final parts = task.time.split(':');
        final taskHour = int.parse(parts[0]);
        final taskMin = int.parse(parts[1]);
        if (now.hour > taskHour || (now.hour == taskHour && now.minute > taskMin)) {
          task.isExpired = true;
          changed = true;
        }
      }
    }
    if (changed) {
      HiveService.saveRoutineDay(routine); // fire-and-forget: save is fast, UI updates immediately
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expireTimer?.cancel();
    super.dispose();
  }

  DayRoutine? get _currentRoutine => HiveService.getRoutineForWeekday(_selectedDay);

  double _progressFor(DayRoutine? r) {
    if (r == null || r.tasks.isEmpty) return 0;
    return r.tasks.where((t) => t.isChecked).length / r.tasks.length;
  }

  String _progressLabel(DayRoutine? r) {
    if (r == null || r.tasks.isEmpty) return '0%';
    final pct = (r.tasks.where((t) => t.isChecked).length / r.tasks.length * 100).round();
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        _buildHeader(),
        _buildDayTabs(),
        Expanded(child: _buildTaskList()),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    final today = DateTime.now().weekday;
    int totalTasks = 0, doneTasks = 0;
    for (int d = 1; d <= 7; d++) {
      final r = HiveService.getRoutineForWeekday(d);
      if (r != null) {
        totalTasks += r.tasks.length;
        doneTasks += r.tasks.where((t) => t.isChecked).length;
      }
    }
    final weekProgress = totalTasks > 0 ? doneTasks / totalTasks : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x0DFFB6C1), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          const Text('My Routines', style: TextStyle(fontFamily: 'Poppins',
            fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final d = i + 1;
                final r = HiveService.getRoutineForWeekday(d);
                final prog = _progressFor(r);
                final isToday = d == today;
                final isSelected = d == _selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = d);
                    _tabController.animateTo(i);
                  },
                  child: Column(children: [
                    BeautifulProgressRing(
                      progress: prog, size: 36, centerLabel: kDayShort[d].substring(0, 1),
                      strokeWidth: 4,
                      color: isToday ? AppTheme.primaryDark : isSelected ? AppTheme.accent : AppTheme.primary,
                      animate: false,
                    ),
                    const SizedBox(height: 1),
                    if (isToday)
                      Container(width: 4, height: 4,
                        decoration: const BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle)),
                  ]),
                );
              },
            ),
          ),
        ])),
        const SizedBox(width: 16),
        BeautifulProgressRing(
          progress: weekProgress, size: 86,
          centerLabel: _progressLabel(_currentRoutine), subLabel: 'today', strokeWidth: 8,
        ),
      ]),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.pinkGradient),
          borderRadius: BorderRadius.circular(12)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
        tabs: List.generate(7, (i) => Tab(text: kDayShort[i + 1])),
      ),
    );
  }

  Widget _buildTaskList() {
    final routine = _currentRoutine;
    if (routine == null || routine.tasks.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.playlist_add_rounded, size: 56, color: AppTheme.primary.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text('No tasks for ${kDayNames[_selectedDay]}',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        const Text('Tap + to add a task',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textHint)),
      ]));
    }

    final tasks = [...routine.tasks]..sort((a, b) {
      int aMin = int.parse(a.time.split(':')[0]) * 60 + int.parse(a.time.split(':')[1]);
      int bMin = int.parse(b.time.split(':')[0]) * 60 + int.parse(b.time.split(':')[1]);
      return aMin.compareTo(bMin);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskCard(
        task: tasks[index],
        onCheck: () => _toggleCheck(routine, tasks[index]),
        onDelete: () => _deleteTask(routine, tasks[index]),
        onEdit: () => _showEditTaskDialog(routine, tasks[index]),
      ),
    );
  }

  void _toggleCheck(DayRoutine routine, RoutineTask task) {
    task.isChecked = !task.isChecked;
    if (task.isChecked) task.isExpired = false;
    setState(() {});
    HiveService.saveRoutineDay(routine); // intentional fire-and-forget: UI leads, storage follows
  }

  void _deleteTask(DayRoutine routine, RoutineTask task) async {
    await HiveService.deleteTask(task.id, routine);
    await NotificationService.cancelTaskAlarm(task.id, routine.weekday);
    setState(() {});
  }

  void _showAddTaskDialog() => _showTaskDialog(title: 'Add Task');

  void _showEditTaskDialog(DayRoutine routine, RoutineTask task) =>
      _showTaskDialog(title: 'Edit Task', existingTask: task, existingRoutine: routine);

  void _showTaskDialog({
    required String title,
    RoutineTask? existingTask,
    DayRoutine? existingRoutine,
  }) {
    final isEdit = existingTask != null;
    final nameCtrl = TextEditingController(text: existingTask?.name ?? '');
    TimeOfDay selectedTime = existingTask != null
        ? TimeOfDay(hour: int.parse(existingTask.time.split(':')[0]),
                     minute: int.parse(existingTask.time.split(':')[1]))
        : TimeOfDay.now();
    bool alarmOn = existingTask?.alarmEnabled ?? true;
    int targetDay = existingRoutine?.weekday ?? _selectedDay;
    int? copyFromDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task name', prefixIcon: Icon(Icons.task_alt_rounded)),
                autofocus: !isEdit,
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx, initialTime: selectedTime,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppTheme.primaryDark)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDialogState(() => selectedTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider, width: 1.5)),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(selectedTime.format(ctx), style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 14,
                      fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: targetDay,
                decoration: const InputDecoration(
                  labelText: 'Day', prefixIcon: Icon(Icons.calendar_today_rounded)),
                items: List.generate(7, (i) =>
                  DropdownMenuItem(value: i + 1, child: Text(kDayNames[i + 1]))),
                onChanged: (v) => setDialogState(() => targetDay = v ?? _selectedDay),
              ),
              // Copy-from only shown when adding a new task
              if (!isEdit) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  value: copyFromDay,
                  decoration: const InputDecoration(
                    labelText: 'Copy all tasks from day (optional)',
                    prefixIcon: Icon(Icons.copy_rounded)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    ...List.generate(7, (i) =>
                      DropdownMenuItem<int?>(value: i + 1, child: Text(kDayNames[i + 1]))),
                  ],
                  onChanged: (v) => setDialogState(() => copyFromDay = v),
                ),
              ],
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.alarm_rounded, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 10),
                const Text('Enable alarm', style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 14, color: AppTheme.textPrimary)),
                const Spacer(),
                Switch(value: alarmOn, onChanged: (v) => setDialogState(() => alarmOn = v)),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await _saveTask(
                  name: nameCtrl.text.trim(), time: selectedTime, targetDay: targetDay,
                  alarmOn: alarmOn, existingTask: existingTask, copyFromDay: copyFromDay,
                );
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTask({
    required String name,
    required TimeOfDay time,
    required int targetDay,
    required bool alarmOn,
    RoutineTask? existingTask,
    int? copyFromDay,
  }) async {
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    DayRoutine? routine = HiveService.getRoutineForWeekday(targetDay);
    routine ??= DayRoutine(id: const Uuid().v4(), weekday: targetDay, name: kDayNames[targetDay]);

    if (copyFromDay != null) {
      final source = HiveService.getRoutineForWeekday(copyFromDay);
      if (source != null) {
        for (final t in source.tasks) {
          final newTask = RoutineTask(
            id: const Uuid().v4(), name: t.name, time: t.time, alarmEnabled: t.alarmEnabled);
          routine.tasks.add(newTask);
          if (newTask.alarmEnabled) {
            await NotificationService.scheduleTaskAlarm(newTask, targetDay);
          }
        }
      }
    }

    if (existingTask != null) {
      final idx = routine.tasks.indexWhere((t) => t.id == existingTask.id);
      if (idx != -1) {
        routine.tasks[idx].name = name;
        routine.tasks[idx].time = timeStr;
        routine.tasks[idx].alarmEnabled = alarmOn;
        await NotificationService.cancelTaskAlarm(existingTask.id, targetDay);
        if (alarmOn) await NotificationService.scheduleTaskAlarm(routine.tasks[idx], targetDay);
      }
    } else {
      final task = RoutineTask(id: const Uuid().v4(), name: name, time: timeStr, alarmEnabled: alarmOn);
      routine.tasks.add(task);
      if (alarmOn) await NotificationService.scheduleTaskAlarm(task, targetDay);
    }

    await HiveService.saveRoutineDay(routine);
    if (mounted) setState(() {});
  }
}

// ── Task Card ──────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final RoutineTask task;
  final VoidCallback onCheck;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({required this.task, required this.onCheck,
    required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isChecked = task.isChecked;
    final isExpired = task.isExpired && !task.isChecked;

    Color cardBg, borderColor;
    if (isChecked) {
      cardBg = AppTheme.taskCheckedBg; borderColor = AppTheme.taskCheckedText.withOpacity(0.3);
    } else if (isExpired) {
      cardBg = AppTheme.taskExpiredBg; borderColor = AppTheme.taskExpiredText.withOpacity(0.3);
    } else {
      cardBg = AppTheme.surface; borderColor = AppTheme.divider;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${task.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ).then((v) => v ?? false),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(18)),
          child: Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 24),
        ),
        onDismissed: (_) => onDelete(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: cardBg, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isChecked || isExpired ? [] : [
              BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            MiniProgressDot(isChecked: isChecked, isExpired: isExpired, onTap: onCheck),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.name, style: TextStyle(
                fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600,
                color: isChecked ? AppTheme.taskCheckedText
                     : isExpired ? AppTheme.taskExpiredText : AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 13,
                  color: isChecked ? AppTheme.taskCheckedText.withOpacity(0.7)
                       : isExpired ? AppTheme.taskExpiredText.withOpacity(0.7) : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(_formatTime(task.time), style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12,
                  color: isChecked ? AppTheme.taskCheckedText.withOpacity(0.7)
                       : isExpired ? AppTheme.taskExpiredText.withOpacity(0.7) : AppTheme.textSecondary)),
                if (task.alarmEnabled && !isChecked && !isExpired) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.alarm_on_rounded, size: 13, color: AppTheme.primaryDark.withOpacity(0.7)),
                ]
              ]),
            ])),
            IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textHint),
              onPressed: onEdit, splashRadius: 20),
          ]),
        ),
      ),
    );
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final suffix = h < 12 ? 'AM' : 'PM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:${m.toString().padLeft(2, '0')} $suffix';
  }
}
