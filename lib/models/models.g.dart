part of 'models.dart';

// ── RoutineTask Adapter (typeId 0) ─────────────────────────────
class RoutineTaskAdapter extends TypeAdapter<RoutineTask> {
  @override final int typeId = 0;

  @override
  RoutineTask read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return RoutineTask(
      id: f[0] as String,
      name: f[1] as String,
      time: f[2] as String,
      isChecked: f[3] as bool,
      isExpired: f[4] as bool,
      alarmEnabled: f[5] as bool,
      order: f[6] as int,
    );
  }

  @override
  void write(BinaryWriter w, RoutineTask o) {
    w.writeByte(7);
    w..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.time)
     ..writeByte(3)..write(o.isChecked)
     ..writeByte(4)..write(o.isExpired)
     ..writeByte(5)..write(o.alarmEnabled)
     ..writeByte(6)..write(o.order);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is RoutineTaskAdapter && o.typeId == typeId;
}

// ── DayRoutine Adapter (typeId 1) ──────────────────────────────
class DayRoutineAdapter extends TypeAdapter<DayRoutine> {
  @override final int typeId = 1;

  @override
  DayRoutine read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return DayRoutine(
      id: f[0] as String,
      weekday: f[1] as int,
      name: f[2] as String,
      isActive: f[4] as bool? ?? true,
      copiedFromWeekday: f[5] as int?,
    )..taskIds = (f[3] as List?)?.cast<String>() ?? [];
  }

  @override
  void write(BinaryWriter w, DayRoutine o) {
    w.writeByte(6);
    w..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.weekday)
     ..writeByte(2)..write(o.name)
     ..writeByte(3)..write(o.taskIds)
     ..writeByte(4)..write(o.isActive)
     ..writeByte(5)..write(o.copiedFromWeekday);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is DayRoutineAdapter && o.typeId == typeId;
}

// ── NoteModel Adapter (typeId 2) ───────────────────────────────
class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override final int typeId = 2;

  @override
  NoteModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return NoteModel(
      id: f[0] as String,
      title: f[1] as String,
      content: f[2] as String,
      richContent: f[3] as String?,
      createdAt: f[4] as DateTime,
      updatedAt: f[5] as DateTime,
      colorHex: f[6] as String?,
      isPinned: f[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter w, NoteModel o) {
    w.writeByte(8);
    w..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.title)
     ..writeByte(2)..write(o.content)
     ..writeByte(3)..write(o.richContent)
     ..writeByte(4)..write(o.createdAt)
     ..writeByte(5)..write(o.updatedAt)
     ..writeByte(6)..write(o.colorHex)
     ..writeByte(7)..write(o.isPinned);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is NoteModelAdapter && o.typeId == typeId;
}

// ── GratitudeEntry Adapter (typeId 3) ──────────────────────────
class GratitudeEntryAdapter extends TypeAdapter<GratitudeEntry> {
  @override final int typeId = 3;

  @override
  GratitudeEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return GratitudeEntry(
      id: f[0] as String,
      date: f[1] as DateTime,
      gratitudes: (f[2] as List).cast<String>(),
      freeWrite: f[3] as String?,
      moodTag: f[4] as String?,
      aiReflection: f[5] as String?,
    );
  }

  @override
  void write(BinaryWriter w, GratitudeEntry o) {
    w.writeByte(6);
    w..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.date)
     ..writeByte(2)..write(o.gratitudes)
     ..writeByte(3)..write(o.freeWrite)
     ..writeByte(4)..write(o.moodTag)
     ..writeByte(5)..write(o.aiReflection);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is GratitudeEntryAdapter && o.typeId == typeId;
}

// ── Affirmation Adapter (typeId 4) ─────────────────────────────
class AffirmationAdapter extends TypeAdapter<Affirmation> {
  @override final int typeId = 4;

  @override
  Affirmation read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Affirmation(
      id: f[0] as String,
      text: f[1] as String,
      order: f[2] as int? ?? 0,
      isFavorite: f[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter w, Affirmation o) {
    w.writeByte(4);
    w..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.text)
     ..writeByte(2)..write(o.order)
     ..writeByte(3)..write(o.isFavorite);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is AffirmationAdapter && o.typeId == typeId;
}

// ── ChatMessage Adapter (typeId 5) ─────────────────────────────
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override final int typeId = 5;

  @override
  ChatMessage read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return ChatMessage(
      id: f[0] as String,
      content: f[1] as String,
      isUser: f[2] as bool,
      timestamp: f[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter w, ChatMessage o) {
    w.writeByte(4);
    w..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.content)
     ..writeByte(2)..write(o.isUser)
     ..writeByte(3)..write(o.timestamp);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is ChatMessageAdapter && o.typeId == typeId;
}

// ── AppSettings Adapter (typeId 6) ─────────────────────────────
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return AppSettings(
      showFloatingFlowers: f[0] as bool? ?? true,
      lastMotivationDate: f[1] as String?,
      userName: f[2] as String?,
      userAge: f[3] as String?,
      userProfession: f[4] as String?,
      aiBaseUrl: f[5] as String?,
      aiApiKey: f[6] as String?,
      aiModel: f[7] as String?,
    );
  }

  @override
  void write(BinaryWriter w, AppSettings o) {
    w.writeByte(8);
    w..writeByte(0)..write(o.showFloatingFlowers)
     ..writeByte(1)..write(o.lastMotivationDate)
     ..writeByte(2)..write(o.userName)
     ..writeByte(3)..write(o.userAge)
     ..writeByte(4)..write(o.userProfession)
     ..writeByte(5)..write(o.aiBaseUrl)
     ..writeByte(6)..write(o.aiApiKey)
     ..writeByte(7)..write(o.aiModel);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object o) => o is AppSettingsAdapter && o.typeId == typeId;
}
