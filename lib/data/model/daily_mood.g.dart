// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_mood.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyMoodAdapter extends TypeAdapter<DailyMood> {
  @override
  final int typeId = 2;

  @override
  DailyMood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMood(
      date: fields[0] as DateTime,
      score: fields[1] as double,
      moodImage: fields[2] as String,
      timestamp: fields[3] as DateTime,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMood obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.moodImage)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
