import 'package:hive/hive.dart';

part 'daily_usage_history.g.dart';

@HiveType(typeId: 0)
class DailyUsageHistory extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  Map<String, int> appUsageMinutes;

  @HiveField(2)
  int totalScreenTimeMinutes;

  @HiveField(3)
  int appsBlockedCount;

  @HiveField(4)
  int rulesActiveCount;

  @HiveField(5)
  List<String> mostUsedApps;

  @HiveField(6)
  Map<String, String> appNames;

  @HiveField(7)
  String? activeFocusMode;

  @HiveField(8)
  int focusModeMinutes;

  DailyUsageHistory({
    required this.date,
    required this.appUsageMinutes,
    required this.totalScreenTimeMinutes,
    required this.appsBlockedCount,
    required this.rulesActiveCount,
    required this.mostUsedApps,
    required this.appNames,
    this.activeFocusMode,
    this.focusModeMinutes = 0,
  });

  String get formattedTotalScreenTime {
    final hours = totalScreenTimeMinutes ~/ 60;
    final minutes = totalScreenTimeMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get topAppUsage {
    if (mostUsedApps.isEmpty) return 'No usage';
    
    final topApp = mostUsedApps.first;
    final minutes = appUsageMinutes[topApp] ?? 0;
    final appName = appNames[topApp] ?? topApp;
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    String timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    return '$appName ($timeStr)';
  }

  int get productivityScore {
    if (totalScreenTimeMinutes == 0) return 100;
    
    final blockedRatio = appsBlockedCount / (appsBlockedCount + mostUsedApps.length).clamp(1, double.infinity);
    final focusRatio = focusModeMinutes / totalScreenTimeMinutes.clamp(1, double.infinity);
    
    return ((blockedRatio * 50) + (focusRatio * 50)).round().clamp(0, 100);
  }

  bool get isProductiveDay => productivityScore >= 70;

  int getAppUsage(String packageName) {
    return appUsageMinutes[packageName] ?? 0;
  }

  String getFormattedAppUsage(String packageName) {
    final minutes = getAppUsage(packageName);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  @override
  String toString() {
    return 'DailyUsageHistory(date: $date, totalScreenTime: $formattedTotalScreenTime, topApp: $topAppUsage)';
  }
}