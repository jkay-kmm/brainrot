import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/daily_usage_history.dart';
import '../model/weekly_summary.dart';
import '../model/app_block_info.dart';
import 'app_blocking_service.dart';

class UsageHistoryService {
  static const String _dailyHistoryBoxName = 'daily_usage_history';
  static const String _weeklySummaryBoxName = 'weekly_summary';
  
  static final UsageHistoryService _instance = UsageHistoryService._internal();
  factory UsageHistoryService() => _instance;
  UsageHistoryService._internal();

  Box<DailyUsageHistory>? _dailyHistoryBox;
  Box<WeeklySummary>? _weeklySummaryBox;
  
  // Stream controllers for real-time updates
  final StreamController<List<DailyUsageHistory>> _historyController = 
      StreamController.broadcast();
  final StreamController<WeeklySummary?> _weeklyController = 
      StreamController.broadcast();

  // Getters for streams
  Stream<List<DailyUsageHistory>> get historyStream => _historyController.stream;
  Stream<WeeklySummary?> get weeklyStream => _weeklyController.stream;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    try {
      debugPrint('🗄️ [HISTORY] Initializing UsageHistoryService...');
      
      // Initialize Hive if not already done
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DailyUsageHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(WeeklySummaryAdapter());
      }

      // Open boxes
      _dailyHistoryBox = await Hive.openBox<DailyUsageHistory>(_dailyHistoryBoxName);
      _weeklySummaryBox = await Hive.openBox<WeeklySummary>(_weeklySummaryBoxName);

      debugPrint('✅ [HISTORY] UsageHistoryService initialized');
      debugPrint('📊 [HISTORY] Found ${_dailyHistoryBox!.length} daily records');
      
      // Clean up old data (keep last 90 days)
      await _cleanupOldData();
      
    } catch (e) {
      debugPrint('❌ [HISTORY] Error initializing: $e');
      rethrow;
    }
  }

  /// Save today's usage data
  Future<void> saveTodayUsage() async {
    try {
      final today = DateTime.now();
      final todayKey = _getDayKey(today);
      
      debugPrint('💾 [HISTORY] Saving usage for $todayKey');

      // Get current app block status from blocking service
      final blockingService = AppBlockingService();
      final appBlockStatus = await blockingService.getAllAppBlockStatus();
      
      // Calculate usage data
      final appUsageMinutes = <String, int>{};
      final appNames = <String, String>{};
      int totalScreenTime = 0;
      int blockedCount = 0;

      for (final app in appBlockStatus.values) {
        if (app.dailyUsage != null) {
          final minutes = app.dailyUsage!.inMinutes;
          appUsageMinutes[app.packageName] = minutes;
          appNames[app.packageName] = app.appName;
          totalScreenTime += minutes;
        }
        
        if (app.isBlocked) blockedCount++;
      }

      // Get most used apps (top 5)
      final sortedApps = appUsageMinutes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostUsedApps = sortedApps.take(5).map((e) => e.key).toList();

      // Get active rules count
      final activeRulesCount = blockingService.rules.where((r) => r.isActive).length;
      
      // Get focus mode info
      final activeFocus = blockingService.activeFocusMode;
      String? focusModeName;
      int focusModeMinutes = 0;
      
      if (activeFocus != null) {
        focusModeName = activeFocus.name;
        // Calculate focus mode duration (simplified)
        if (activeFocus.startTime != null) {
          final focusDuration = DateTime.now().difference(activeFocus.startTime!);
          focusModeMinutes = focusDuration.inMinutes.clamp(0, totalScreenTime);
        }
      }

      // Create daily history record
      final dailyHistory = DailyUsageHistory(
        date: DateTime(today.year, today.month, today.day),
        appUsageMinutes: appUsageMinutes,
        totalScreenTimeMinutes: totalScreenTime,
        appsBlockedCount: blockedCount,
        rulesActiveCount: activeRulesCount,
        mostUsedApps: mostUsedApps,
        appNames: appNames,
        activeFocusMode: focusModeName,
        focusModeMinutes: focusModeMinutes,
      );

      // Save to Hive
      await _dailyHistoryBox!.put(todayKey, dailyHistory);
      
      debugPrint('✅ [HISTORY] Saved daily usage: ${dailyHistory.formattedTotalScreenTime}');
      
      // Update weekly summary
      await _updateWeeklySummary(today);
      
      // Notify listeners
      _historyController.add(await getRecentHistory(30));
      
    } catch (e) {
      debugPrint('❌ [HISTORY] Error saving today usage: $e');
    }
  }

  /// Get daily history for specific date
  Future<DailyUsageHistory?> getDayHistory(DateTime date) async {
    final key = _getDayKey(date);
    return _dailyHistoryBox!.get(key);
  }

  /// Get recent history (last N days)
  Future<List<DailyUsageHistory>> getRecentHistory(int days) async {
    final histories = <DailyUsageHistory>[];
    final today = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final history = await getDayHistory(date);
      if (history != null) {
        histories.add(history);
      }
    }
    
    // Sort by date (newest first)
    histories.sort((a, b) => b.date.compareTo(a.date));
    return histories;
  }

  /// Get history for specific date range
  Future<List<DailyUsageHistory>> getHistoryRange(DateTime startDate, DateTime endDate) async {
    final histories = <DailyUsageHistory>[];
    
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final history = await getDayHistory(currentDate);
      if (history != null) {
        histories.add(history);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return histories;
  }

  /// Get weekly summary for specific week
  Future<WeeklySummary?> getWeeklySummary(DateTime date) async {
    final weekStart = _getWeekStart(date);
    final key = _getWeekKey(weekStart);
    return _weeklySummaryBox!.get(key);
  }

  /// Get recent weekly summaries
  Future<List<WeeklySummary>> getRecentWeeklySummaries(int weeks) async {
    final summaries = <WeeklySummary>[];
    final today = DateTime.now();
    
    for (int i = 0; i < weeks; i++) {
      final weekDate = today.subtract(Duration(days: i * 7));
      final summary = await getWeeklySummary(weekDate);
      if (summary != null) {
        summaries.add(summary);
      }
    }
    
    // Sort by date (newest first)
    summaries.sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
    return summaries;
  }

  /// Get total usage statistics
  Future<Map<String, dynamic>> getTotalStats() async {
    final allHistories = _dailyHistoryBox!.values.toList();
    
    if (allHistories.isEmpty) {
      return {
        'totalDays': 0,
        'totalScreenTime': 0,
        'averageDailyTime': 0,
        'totalAppsBlocked': 0,
        'productiveDays': 0,
        'mostUsedApp': 'None',
      };
    }

    int totalScreenTime = 0;
    int totalAppsBlocked = 0;
    int productiveDays = 0;
    Map<String, int> appTotals = {};

    for (final history in allHistories) {
      totalScreenTime += history.totalScreenTimeMinutes;
      totalAppsBlocked += history.appsBlockedCount;
      if (history.isProductiveDay) productiveDays++;

      // Aggregate app usage
      history.appUsageMinutes.forEach((app, minutes) {
        appTotals[app] = (appTotals[app] ?? 0) + minutes;
      });
    }

    // Find most used app
    String mostUsedApp = 'None';
    if (appTotals.isNotEmpty) {
      final topApp = appTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      mostUsedApp = allHistories.first.appNames[topApp.key] ?? topApp.key;
    }

    return {
      'totalDays': allHistories.length,
      'totalScreenTime': totalScreenTime,
      'averageDailyTime': (totalScreenTime / allHistories.length).round(),
      'totalAppsBlocked': totalAppsBlocked,
      'productiveDays': productiveDays,
      'mostUsedApp': mostUsedApp,
    };
  }

  /// Update weekly summary
  Future<void> _updateWeeklySummary(DateTime date) async {
    try {
      final weekStart = _getWeekStart(date);
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      // Get all daily histories for this week
      final weekHistories = await getHistoryRange(weekStart, weekEnd);
      
      if (weekHistories.isNotEmpty) {
        final weeklySummary = WeeklySummary.fromDailyHistories(weekHistories);
        final key = _getWeekKey(weekStart);
        
        await _weeklySummaryBox!.put(key, weeklySummary);
        debugPrint('✅ [HISTORY] Updated weekly summary for $key');
        
        // Notify listeners
        _weeklyController.add(weeklySummary);
      }
    } catch (e) {
      debugPrint('❌ [HISTORY] Error updating weekly summary: $e');
    }
  }

  /// Clean up old data (keep last 90 days)
  Future<void> _cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final keysToDelete = <String>[];
      
      // Find old daily records
      for (final key in _dailyHistoryBox!.keys) {
        final date = DateTime.parse(key);
        if (date.isBefore(cutoffDate)) {
          keysToDelete.add(key);
        }
      }
      
      // Delete old records
      if (keysToDelete.isNotEmpty) {
        await _dailyHistoryBox!.deleteAll(keysToDelete);
        debugPrint('🧹 [HISTORY] Cleaned up ${keysToDelete.length} old records');
      }
      
      // Clean up old weekly summaries (keep last 12 weeks)
      final weekCutoff = DateTime.now().subtract(const Duration(days: 84)); // 12 weeks
      final weekKeysToDelete = <String>[];
      
      for (final key in _weeklySummaryBox!.keys) {
        final date = DateTime.parse(key);
        if (date.isBefore(weekCutoff)) {
          weekKeysToDelete.add(key);
        }
      }
      
      if (weekKeysToDelete.isNotEmpty) {
        await _weeklySummaryBox!.deleteAll(weekKeysToDelete);
        debugPrint('🧹 [HISTORY] Cleaned up ${weekKeysToDelete.length} old weekly summaries');
      }
      
    } catch (e) {
      debugPrint('❌ [HISTORY] Error cleaning up old data: $e');
    }
  }

  /// Get day key for storage
  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get week key for storage
  String _getWeekKey(DateTime weekStart) {
    return _getDayKey(weekStart);
  }

  /// Get week start date (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Dispose resources
  void dispose() {
    _historyController.close();
    _weeklyController.close();
  }

  /// Export data as JSON (for backup/sharing)
  Future<Map<String, dynamic>> exportData() async {
    final dailyData = _dailyHistoryBox!.values.map((h) => {
      'date': h.date.toIso8601String(),
      'totalScreenTime': h.totalScreenTimeMinutes,
      'appUsage': h.appUsageMinutes,
      'appNames': h.appNames,
      'appsBlocked': h.appsBlockedCount,
      'productivityScore': h.productivityScore,
    }).toList();

    final weeklyData = _weeklySummaryBox!.values.map((w) => {
      'weekStart': w.weekStartDate.toIso8601String(),
      'totalScreenTime': w.totalScreenTimeMinutes,
      'averageDaily': w.averageDailyScreenTime,
      'productiveDays': w.productiveDaysCount,
      'topApps': w.topAppsUsage,
    }).toList();

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'dailyHistory': dailyData,
      'weeklySummaries': weeklyData,
      'totalRecords': dailyData.length,
    };
  }
}