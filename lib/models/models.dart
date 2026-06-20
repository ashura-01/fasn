import 'package:hive/hive.dart';

part 'models.g.dart';

// ── Routine Models ─────────────────────────────────────────────

@HiveType(typeId: 0)
class RoutineTask extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String time;
  @HiveField(3) bool isChecked;
  @HiveField(4) bool isExpired;
  @HiveField(5) bool alarmEnabled;
  @HiveField(6) int order;

  RoutineTask({
    required this.id,
    required this.name,
    required this.time,
    this.isChecked = false,
    this.isExpired = false,
    this.alarmEnabled = true,
    this.order = 0,
  });
}

@HiveType(typeId: 1)
class DayRoutine extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) int weekday;
  @HiveField(2) String name;
  // Field 3 = taskIds stored by adapter to avoid nested HiveObject crash
  List<String> taskIds = [];
  List<RoutineTask> tasks = []; // transient, hydrated by HiveService
  @HiveField(4) bool isActive;
  @HiveField(5) int? copiedFromWeekday;

  DayRoutine({
    required this.id,
    required this.weekday,
    required this.name,
    List<RoutineTask>? tasks,
    this.isActive = true,
    this.copiedFromWeekday,
  }) : tasks = tasks ?? [];
}

// ── Note Models ────────────────────────────────────────────────

@HiveType(typeId: 2)
class NoteModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String content;
  @HiveField(3) String? richContent;
  @HiveField(4) DateTime createdAt;
  @HiveField(5) DateTime updatedAt;
  @HiveField(6) String? colorHex;
  @HiveField(7) bool isPinned;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.richContent,
    required this.createdAt,
    required this.updatedAt,
    this.colorHex,
    this.isPinned = false,
  });
}

// ── Gratitude & Affirmations Models ───────────────────────────

@HiveType(typeId: 3)
class GratitudeEntry extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) List<String> gratitudes; // 3 items
  @HiveField(3) String? freeWrite;
  @HiveField(4) String? moodTag; // 'peaceful','happy','anxious','tired','grateful'
  @HiveField(5) String? aiReflection; // cached AI response

  GratitudeEntry({
    required this.id,
    required this.date,
    required this.gratitudes,
    this.freeWrite,
    this.moodTag,
    this.aiReflection,
  });
}

@HiveType(typeId: 4)
class Affirmation extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String text;
  @HiveField(2) int order;
  @HiveField(3) bool isFavorite;

  Affirmation({
    required this.id,
    required this.text,
    this.order = 0,
    this.isFavorite = false,
  });
}

@HiveType(typeId: 5)
class ChatMessage extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String content;
  @HiveField(2) bool isUser;
  @HiveField(3) DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

// ── App Settings ───────────────────────────────────────────────

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0) bool showFloatingFlowers;
  @HiveField(1) String? lastMotivationDate;
  // User profile
  @HiveField(2) String? userName;
  @HiveField(3) String? userAge;
  @HiveField(4) String? userProfession;
  // AI config
  @HiveField(5) String? aiBaseUrl;
  @HiveField(6) String? aiApiKey;
  @HiveField(7) String? aiModel;

  AppSettings({
    this.showFloatingFlowers = true,
    this.lastMotivationDate,
    this.userName,
    this.userAge,
    this.userProfession,
    this.aiBaseUrl,
    this.aiApiKey,
    this.aiModel,
  });
}
