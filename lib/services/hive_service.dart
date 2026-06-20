import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveService {
  static const String routineTaskBox  = 'routine_tasks';
  static const String routineDayBox   = 'routine_days';
  static const String notesBox        = 'notes';
  static const String gratitudeBox    = 'gratitude';
  static const String affirmationBox  = 'affirmations';
  static const String chatBox         = 'chat_messages';
  static const String appSettingsBox  = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(RoutineTaskAdapter());
    Hive.registerAdapter(DayRoutineAdapter());
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(GratitudeEntryAdapter());
    Hive.registerAdapter(AffirmationAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    await Hive.openBox<RoutineTask>(routineTaskBox);
    await Hive.openBox<DayRoutine>(routineDayBox);
    await Hive.openBox<NoteModel>(notesBox);
    await Hive.openBox<GratitudeEntry>(gratitudeBox);
    await Hive.openBox<Affirmation>(affirmationBox);
    await Hive.openBox<ChatMessage>(chatBox);
    await Hive.openBox<AppSettings>(appSettingsBox);
  }

  // ── Routine Tasks ────────────────────────────────────────────
  static Box<RoutineTask> get _taskBox => Hive.box<RoutineTask>(routineTaskBox);
  static Box<DayRoutine>  get _dayBox  => Hive.box<DayRoutine>(routineDayBox);

  static List<RoutineTask> getTasksForDay(DayRoutine day) {
    return day.taskIds
        .map((id) => _taskBox.get(id))
        .whereType<RoutineTask>()
        .toList()
      ..sort((a, b) {
        final aMin = _timeToMinutes(a.time);
        final bMin = _timeToMinutes(b.time);
        return aMin.compareTo(bMin);
      });
  }

  static int _timeToMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static DayRoutine? getRoutineForWeekday(int weekday) {
    try {
      final day = _dayBox.values.firstWhere((r) => r.weekday == weekday);
      day.tasks = getTasksForDay(day);
      return day;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveTask(RoutineTask task) async {
    await _taskBox.put(task.id, task);
  }

  static Future<void> saveRoutineDay(DayRoutine day) async {
    // persist tasks first
    for (final t in day.tasks) {
      await _taskBox.put(t.id, t);
    }
    day.taskIds = day.tasks.map((t) => t.id).toList();
    await _dayBox.put(day.id, day);
  }

  static Future<void> deleteTask(String taskId, DayRoutine day) async {
    day.tasks.removeWhere((t) => t.id == taskId);
    day.taskIds.remove(taskId);
    await _taskBox.delete(taskId);
    await _dayBox.put(day.id, day);
  }

  // ── Notes ────────────────────────────────────────────────────
  static Box<NoteModel> get notes => Hive.box<NoteModel>(notesBox);

  static List<NoteModel> getAllNotes() => notes.values.toList()
    ..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

  static Future<void> saveNote(NoteModel note) async =>
      notes.put(note.id, note);
  static Future<void> deleteNote(String id) async => notes.delete(id);

  // ── Gratitude ────────────────────────────────────────────────
  static Box<GratitudeEntry> get gratitude => Hive.box<GratitudeEntry>(gratitudeBox);

  static List<GratitudeEntry> getAllGratitude() => gratitude.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  static GratitudeEntry? getGratitudeForDate(DateTime date) {
    try {
      return gratitude.values.firstWhere((e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGratitude(GratitudeEntry entry) async =>
      gratitude.put(entry.id, entry);
  static Future<void> deleteGratitude(String id) async =>
      gratitude.delete(id);

  // streak = consecutive days with an entry ending today
  static int getGratitudeStreak() {
    final entries = getAllGratitude();
    if (entries.isEmpty) return 0;
    final days = entries.map((e) =>
        DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    int streak = 0;
    DateTime check = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    while (days.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Affirmations ─────────────────────────────────────────────
  static Box<Affirmation> get affirmations =>
      Hive.box<Affirmation>(affirmationBox);

  static List<Affirmation> getAllAffirmations() =>
      affirmations.values.toList()..sort((a, b) => a.order.compareTo(b.order));

  static Future<void> saveAffirmation(Affirmation a) async =>
      affirmations.put(a.id, a);
  static Future<void> deleteAffirmation(String id) async =>
      affirmations.delete(id);

  // Seed default affirmations on first run
  static Future<void> seedAffirmationsIfEmpty() async {
    if (affirmations.isNotEmpty) return;
    const defaults = [
      'I am enough, exactly as I am right now.',
      'I deserve happiness and I choose it today.',
      'My potential is limitless and I grow every day.',
      'I am stronger than any challenge I face.',
      'I radiate love, confidence, and positivity.',
      'Every day I am becoming a better version of myself.',
      'I am worthy of good things happening to me.',
      'My feelings are valid and I honour them.',
      'I have survived every hard day so far — I will survive this too.',
      'I choose peace over worry and joy over fear.',
    ];
    for (int i = 0; i < defaults.length; i++) {
      final a = Affirmation(
        id: 'default_$i',
        text: defaults[i],
        order: i,
      );
      await affirmations.put(a.id, a);
    }
  }

  // ── Chat Messages ────────────────────────────────────────────
  static Box<ChatMessage> get chat => Hive.box<ChatMessage>(chatBox);

  static List<ChatMessage> getAllChat() => chat.values.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  static Future<void> saveChat(ChatMessage msg) async =>
      chat.put(msg.id, msg);
  static Future<void> clearChat() async => chat.clear();

  // ── App Settings ─────────────────────────────────────────────
  static Box<AppSettings> get _settingsBox =>
      Hive.box<AppSettings>(appSettingsBox);

  static AppSettings getAppSettings() =>
      _settingsBox.get('settings') ?? AppSettings();

  static Future<void> saveAppSettings(AppSettings s) async =>
      _settingsBox.put('settings', s);

  // ── Clear All ────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _taskBox.clear();
    await _dayBox.clear();
    await notes.clear();
    await gratitude.clear();
    await affirmations.clear();
    await chat.clear();
  }
}
