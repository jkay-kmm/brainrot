// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklySummaryAdapter extends TypeAdapter<WeeklySummary> {
  @override
  final int typeId = 1;

  @override
  WeeklySummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklySummary(
      weekStartDate: fields[0] as DateTime,
      totalScreenTimeMinutes: fields[1] as int,
      averageDailyScreenTime: fields[2] as int,
      topAppsUsage: (fields[3] as Map).cast<String, int>(),
      totalAppsBlocked: fields[4] as int,
      productiveDaysCount: fields[5] as int,
      mostUsedFocusMode: fields[6] as String,
      totalFocusModeMinutes: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklySummary obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.weekStartDate)
      ..writeByte(1)
      ..write(obj.totalScreenTimeMinutes)
      ..writeByte(2)
      ..write(obj.averageDailyScreenTime)
      ..writeByte(3)
      ..write(obj.topAppsUsage)
      ..writeByte(4)
      ..write(obj.totalAppsBlocked)
      ..writeByte(5)
      ..write(obj.productiveDaysCount)
      ..writeByte(6)
      ..write(obj.mostUsedFocusMode)
      ..writeByte(7)
      ..write(obj.totalFocusModeMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklySummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
