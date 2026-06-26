import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/daily_usage_history.dart';
import '../model/weekly_summary.dart';
import 'app_blocking_service.dart';

class UsageHistoryService {
  static const String _dailyHistoryBoxName = 'daily_usage_history';
  static const String _weeklySummaryBoxName = 'weekly_summary';
  
  static final UsageHistoryService _instance = UsageHistoryService._internal();
  factory UsageHistoryService() => _instance;
  UsageHistoryService._internal();

  Box<DailyUsageHistory>? _dailyHistoryBox;
  Box<WeeklySummary>? _weeklySummaryBox;
  
  final StreamController<List<DailyUsageHistory>> _historyController = 
      StreamController.broadcast();
  final StreamController<WeeklySummary?> _weeklyController = 
      StreamController.broadcast();
  Stream<List<DailyUsageHistory>> get historyStream => _historyController.stream;
  Stream<WeeklySummary?> get weeklyStream => _weeklyController.stream;

  Future<void> initialize() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DailyUsageHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(WeeklySummaryAdapter());
      }


      _dailyHistoryBox = await Hive.openBox<DailyUsageHistory>(_dailyHistoryBoxName);
      _weeklySummaryBox = await Hive.openBox<WeeklySummary>(_weeklySummaryBoxName);
      await _cleanupOldData();
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveTodayUsage() async {
    try {
      final today = DateTime.now();
      final todayKey = _getDayKey(today);

      final blockingService = AppBlockingService();
      final appBlockStatus = await blockingService.getAllAppBlockStatus();
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

      final sortedApps = appUsageMinutes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostUsedApps = sortedApps.take(5).map((e) => e.key).toList();

      final activeRulesCount = blockingService.rules.where((r) => r.isActive).length;
      final activeFocus = blockingService.activeFocusMode;
      String? focusModeName;
      int focusModeMinutes = 0;
      
      if (activeFocus != null) {
        focusModeName = activeFocus.name;
        if (activeFocus.startTime != null) {
          final focusDuration = DateTime.now().difference(activeFocus.startTime!);
          focusModeMinutes = focusDuration.inMinutes.clamp(0, totalScreenTime);
        }
      }

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

      await _dailyHistoryBox!.put(todayKey, dailyHistory);
      await _updateWeeklySummary(today);
      _historyController.add(await getRecentHistory(30));
    } catch (e) {
    }
  }

  Future<DailyUsageHistory?> getDayHistory(DateTime date) async {
    final key = _getDayKey(date);
    return _dailyHistoryBox!.get(key);
  }

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
    
    histories.sort((a, b) => b.date.compareTo(a.date));
    return histories;
  }

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

  Future<WeeklySummary?> getWeeklySummary(DateTime date) async {
    final weekStart = _getWeekStart(date);
    final key = _getWeekKey(weekStart);
    return _weeklySummaryBox!.get(key);
  }

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
    
    summaries.sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
    return summaries;
  }

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

      history.appUsageMinutes.forEach((app, minutes) {
        appTotals[app] = (appTotals[app] ?? 0) + minutes;
      });
    }

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

  Future<void> _updateWeeklySummary(DateTime date) async {
    try {
      final weekStart = _getWeekStart(date);
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekHistories = await getHistoryRange(weekStart, weekEnd);
      
      if (weekHistories.isNotEmpty) {
        final weeklySummary = WeeklySummary.fromDailyHistories(weekHistories);
        final key = _getWeekKey(weekStart);
        
        await _weeklySummaryBox!.put(key, weeklySummary);
        
        _weeklyController.add(weeklySummary);
      }
    } catch (e) {
      print('❌ [HISTORY] Error updating weekly summary: $e');
    }
  }

  Future<void> _cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final keysToDelete = <String>[];
      for (final key in _dailyHistoryBox!.keys) {
        final date = DateTime.parse(key);
        if (date.isBefore(cutoffDate)) {
          keysToDelete.add(key);
        }
      }
      if (keysToDelete.isNotEmpty) {
        await _dailyHistoryBox!.deleteAll(keysToDelete);
      }

      final weekCutoff = DateTime.now().subtract(const Duration(days: 84));
      final weekKeysToDelete = <String>[];
      
      for (final key in _weeklySummaryBox!.keys) {
        final date = DateTime.parse(key);
        if (date.isBefore(weekCutoff)) {
          weekKeysToDelete.add(key);
        }
      }
      
      if (weekKeysToDelete.isNotEmpty) {
        await _weeklySummaryBox!.deleteAll(weekKeysToDelete);
      }
      
    } catch (e) {
    }
  }

  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekKey(DateTime weekStart) {
    return _getDayKey(weekStart);
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  void dispose() {
    _historyController.close();
    _weeklyController.close();
  }

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