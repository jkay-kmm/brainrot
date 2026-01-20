// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_usage_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyUsageHistoryAdapter extends TypeAdapter<DailyUsageHistory> {
  @override
  final int typeId = 0;

  @override
  DailyUsageHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyUsageHistory(
      date: fields[0] as DateTime,
      appUsageMinutes: (fields[1] as Map).cast<String, int>(),
      totalScreenTimeMinutes: fields[2] as int,
      appsBlockedCount: fields[3] as int,
      rulesActiveCount: fields[4] as int,
      mostUsedApps: (fields[5] as List).cast<String>(),
      appNames: (fields[6] as Map).cast<String, String>(),
      activeFocusMode: fields[7] as String?,
      focusModeMinutes: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsageHistory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.appUsageMinutes)
      ..writeByte(2)
      ..write(obj.totalScreenTimeMinutes)
      ..writeByte(3)
      ..write(obj.appsBlockedCount)
      ..writeByte(4)
      ..write(obj.rulesActiveCount)
      ..writeByte(5)
      ..write(obj.mostUsedApps)
      ..writeByte(6)
      ..write(obj.appNames)
      ..writeByte(7)
      ..write(obj.activeFocusMode)
      ..writeByte(8)
      ..write(obj.focusModeMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
