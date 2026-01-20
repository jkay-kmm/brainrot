import 'package:hive/hive.dart';
import 'daily_usage_history.dart';

part 'weekly_summary.g.dart';

@HiveType(typeId: 1)
class WeeklySummary extends HiveObject {
  @HiveField(0)
  DateTime weekStartDate; // Monday of the week

  @HiveField(1)
  int totalScreenTimeMinutes;

  @HiveField(2)
  int averageDailyScreenTime;

  @HiveField(3)
  Map<String, int> topAppsUsage; // Top 10 apps for the week

  @HiveField(4)
  int totalAppsBlocked;

  @HiveField(5)
  int productiveDaysCount;

  @HiveField(6)
  String mostUsedFocusMode;

  @HiveField(7)
  int totalFocusModeMinutes;

  WeeklySummary({
    required this.weekStartDate,
    required this.totalScreenTimeMinutes,
    required this.averageDailyScreenTime,
    required this.topAppsUsage,
    required this.totalAppsBlocked,
    required this.productiveDaysCount,
    required this.mostUsedFocusMode,
    required this.totalFocusModeMinutes,
  });

  /// Create weekly summary from daily histories
  factory WeeklySummary.fromDailyHistories(List<DailyUsageHistory> dailyHistories) {
    if (dailyHistories.isEmpty) {
      throw ArgumentError('Cannot create weekly summary from empty daily histories');
    }

    // Sort by date to get week start
    dailyHistories.sort((a, b) => a.date.compareTo(b.date));
    final weekStart = _getWeekStart(dailyHistories.first.date);

    // Calculate totals
    int totalScreenTime = 0;
    int totalAppsBlocked = 0;
    int productiveDays = 0;
    int totalFocusTime = 0;
    Map<String, int> appUsageTotals = {};
    Map<String, int> focusModeUsage = {};

    for (final day in dailyHistories) {
      totalScreenTime += day.totalScreenTimeMinutes;
      totalAppsBlocked += day.appsBlockedCount;
      totalFocusTime += day.focusModeMinutes;
      
      if (day.isProductiveDay) productiveDays++;

      // Aggregate app usage
      day.appUsageMinutes.forEach((app, minutes) {
        appUsageTotals[app] = (appUsageTotals[app] ?? 0) + minutes;
      });

      // Track focus mode usage
      if (day.activeFocusMode != null) {
        focusModeUsage[day.activeFocusMode!] = 
            (focusModeUsage[day.activeFocusMode!] ?? 0) + day.focusModeMinutes;
      }
    }

    // Get top 10 apps
    final topApps = Map<String, int>.fromEntries(
      appUsageTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10)
    );

    // Get most used focus mode
    String mostUsedFocus = 'None';
    if (focusModeUsage.isNotEmpty) {
      mostUsedFocus = focusModeUsage.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return WeeklySummary(
      weekStartDate: weekStart,
      totalScreenTimeMinutes: totalScreenTime,
      averageDailyScreenTime: (totalScreenTime / dailyHistories.length).round(),
      topAppsUsage: topApps,
      totalAppsBlocked: totalAppsBlocked,
      productiveDaysCount: productiveDays,
      mostUsedFocusMode: mostUsedFocus,
      totalFocusModeMinutes: totalFocusTime,
    );
  }

  /// Get week start date (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Get formatted total screen time
  String get formattedTotalScreenTime {
    final hours = totalScreenTimeMinutes ~/ 60;
    final minutes = totalScreenTimeMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Get formatted average daily screen time
  String get formattedAverageScreenTime {
    final hours = averageDailyScreenTime ~/ 60;
    final minutes = averageDailyScreenTime % 60;
    return '${hours}h ${minutes}m';
  }

  /// Get productivity percentage
  double get productivityPercentage {
    return (productiveDaysCount / 7.0) * 100;
  }

  /// Get week range string
  String get weekRangeString {
    final endDate = weekStartDate.add(const Duration(days: 6));
    return '${_formatDate(weekStartDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  @override
  String toString() {
    return 'WeeklySummary(week: $weekRangeString, totalTime: $formattedTotalScreenTime, productive: $productiveDaysCount/7 days)';
  }
}