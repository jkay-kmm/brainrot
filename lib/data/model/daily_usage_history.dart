import 'package:hive/hive.dart';

part 'daily_usage_history.g.dart';

@HiveType(typeId: 0)
class DailyUsageHistory extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  Map<String, int> appUsageMinutes; // packageName -> minutes used

  @HiveField(2)
  int totalScreenTimeMinutes;

  @HiveField(3)
  int appsBlockedCount;

  @HiveField(4)
  int rulesActiveCount;

  @HiveField(5)
  List<String> mostUsedApps; // Top 5 most used apps

  @HiveField(6)
  Map<String, String> appNames; // packageName -> app display name

  @HiveField(7)
  String? activeFocusMode; // Focus mode used that day

  @HiveField(8)
  int focusModeMinutes; // Minutes spent in focus mode

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

  /// Get formatted total screen time
  String get formattedTotalScreenTime {
    final hours = totalScreenTimeMinutes ~/ 60;
    final minutes = totalScreenTimeMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get top app usage for the day
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

  /// Get productivity score (0-100)
  int get productivityScore {
    if (totalScreenTimeMinutes == 0) return 100;
    
    // Calculate based on blocked apps vs total usage
    final blockedRatio = appsBlockedCount / (appsBlockedCount + mostUsedApps.length).clamp(1, double.infinity);
    final focusRatio = focusModeMinutes / totalScreenTimeMinutes.clamp(1, double.infinity);
    
    return ((blockedRatio * 50) + (focusRatio * 50)).round().clamp(0, 100);
  }

  /// Check if this is a productive day (score >= 70)
  bool get isProductiveDay => productivityScore >= 70;

  /// Get usage for specific app
  int getAppUsage(String packageName) {
    return appUsageMinutes[packageName] ?? 0;
  }

  /// Get formatted usage for specific app
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