import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/app_usage_info.dart';
import '../data/services/real_app_usage_service.dart';
import '../data/services/daily_mood_service.dart';
import '../data/services/app_icon_service.dart';
import '../data/services/widget_service.dart';

class HomeViewModel extends ChangeNotifier {
  final RealAppUsageService _appUsageService = RealAppUsageService();
  final DailyMoodService _moodService = DailyMoodService();
  final AppIconService _iconService = AppIconService();
  final WidgetService _widgetService = WidgetService();

  List<AppUsageInfo> _appUsageList = [];
  bool _isLoading = false;
  String? _errorMessage;
  Duration _totalUsage = Duration.zero;
  double _currentScore = 100.0;
  DateTime _lastResetDate = DateTime.now();

  List<AppUsageInfo>? _cachedTopApps;
  Map<String, dynamic>? _cachedUsageStats;
  String? _cachedFormattedUsage;
  List<AppUsageInfo> get appUsageList => _appUsageList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Duration get totalUsage => _totalUsage;
  double get currentScore => _currentScore;

  String get formattedTotalUsage {
    if (_cachedFormattedUsage != null) return _cachedFormattedUsage!;

    final hours = _totalUsage.inHours;
    final minutes = _totalUsage.inMinutes.remainder(60);

    _cachedFormattedUsage = hours > 0
        ? '${hours}h $minutes m'
        : '$minutes m';
    return _cachedFormattedUsage!;
  }

  List<AppUsageInfo> get topApps {
    _cachedTopApps ??= _appUsageService.getTopUsedApps(_appUsageList, limit: 5);
    return _cachedTopApps!;
  }

  Map<String, dynamic> get usageStats {
    _cachedUsageStats ??= _appUsageService.getUsageStats(_appUsageList);
    return _cachedUsageStats!;
  }

  void _invalidateCaches() {
    _cachedTopApps = null;
    _cachedUsageStats = null;
    _cachedFormattedUsage = null;
  }

  bool get hasExcessiveScreenTime => _totalUsage.inMinutes > 180;
  String get screenTimeCategory {
    final minutes = _totalUsage.inMinutes;
    if (minutes < 60) return 'Light';
    if (minutes < 120) return 'Moderate';
    if (minutes < 180) return 'Heavy';
    return 'Excessive';
  }

  double calculateBrainHealthScore() {
    final totalMinutes = _totalUsage.inMinutes;
    final goalMinutes = 120;
    double preGoalImpact = 0.0;
    double postGoalImpact = 0.0;

    if (totalMinutes <= goalMinutes) {
      preGoalImpact =
          (totalMinutes / goalMinutes) * 10.0;
    } else {
      preGoalImpact = 10.0;
      final excessMinutes = totalMinutes - goalMinutes;
      postGoalImpact =
          (excessMinutes / 60.0) * 20.0;
    }

    final totalImpact = preGoalImpact + postGoalImpact;
    return (100 - totalImpact).clamp(0.0, 100.0);
  }

  Future<void> _checkAndResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastResetDateString = prefs.getString('last_reset_date');

    if (lastResetDateString != null) {
      _lastResetDate = DateTime.parse(lastResetDateString);
    }

    if (!_isSameDay(_lastResetDate, today)) {
      _currentScore = 100.0;
      _lastResetDate = today;
      await prefs.setString('last_reset_date', today.toIso8601String());
      await prefs.setDouble('current_score', _currentScore);

      notifyListeners();
    } else {
      _currentScore = prefs.getDouble('current_score') ?? 100.0;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _saveCurrentScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_score', _currentScore);
    await _moodService.saveDailyMood(
      DateTime.now(), 
      _currentScore,
      totalUsageMinutes: _totalUsage.inMinutes,
    );
  }

  Future<void> loadAppIcons() async {
    if (_appUsageList.isEmpty) {
      return;
    }

    try {
      final packageNames = _appUsageList.map((app) => app.packageName).toList();
      final iconsMap = await _iconService.getMultipleAppIcons(packageNames);

      _appUsageList =
          _appUsageList.map((app) {
            final iconBytes = iconsMap[app.packageName];
            return app.copyWith(iconBytes: iconBytes);
          }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading app icons: $e');
    }
  }

  Future<void> loadTodayUsage() async {
    await _loadUsage(() => _appUsageService.getTodayUsage());
  }

  Future<void> refreshTodayUsage() async {
    await _loadUsage(() => _appUsageService.refreshTodayUsage());
  }

  Future<void> loadUsageInRange(DateTime startTime, DateTime endTime) async {
    await _loadUsage(
          () => _appUsageService.getUsageInRange(startTime, endTime),
    );
  }

  Future<void> _loadUsage(
      Future<List<AppUsageInfo>> Function() loadFunction,
      ) async {
    try {
      _setLoading(true);
      _clearError();

      await _checkAndResetForNewDay();
      bool hasPermission = await _appUsageService.hasUsagePermission();
      if (!hasPermission) {
        bool granted = await _appUsageService.requestUsagePermission();
        if (!granted) {
          _setError('Usage access permission is required to track screen time');
          return;
        }
      }

      final usageList = await loadFunction();
      _appUsageList = usageList;

      _invalidateCaches();

      await loadAppIcons();
      _totalUsage = Duration.zero;
      for (final app in _appUsageList) {
        _totalUsage += app.usage;
      }

      final newScore = calculateBrainHealthScore();
      if (_currentScore != newScore) {
        _currentScore = newScore;
        await _saveCurrentScore();
      }

      await _updateWidget();

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load usage data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> silentRefresh() async {
    try {
      await _checkAndResetForNewDay();
      bool hasPermission = await _appUsageService.hasUsagePermission();
      if (!hasPermission) return;

      final usageList = await _appUsageService.getTodayUsage();
      _appUsageList = usageList;

      _invalidateCaches();

      await loadAppIcons();
      _totalUsage = Duration.zero;
      for (final app in _appUsageList) {
        _totalUsage += app.usage;
      }

      final newScore = calculateBrainHealthScore();
      if (_currentScore != newScore) {
        _currentScore = newScore;
        await _saveCurrentScore();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    }
  }

  Future<void> _updateWidget() async {
    try {
      await _widgetService.updateWidget(
        todayUsage: _totalUsage,
        goal: const Duration(hours: 4),
        score: _currentScore,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  Future<void> refresh() async {
    await refreshTodayUsage();
  }

  Future<void> forceResetScore() async {
    _currentScore = 100.0;
    _lastResetDate = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_reset_date', DateTime.now().toIso8601String());
    await prefs.setDouble('current_score', _currentScore);
    await _moodService.saveDailyMood(
      DateTime.now(), 
      _currentScore,
      totalUsageMinutes: _totalUsage.inMinutes,
    );

    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  double getUsagePercentage(AppUsageInfo app) {
    if (_totalUsage.inMilliseconds == 0) return 0.0;
    return (app.usage.inMilliseconds / _totalUsage.inMilliseconds) * 100;
  }

  Color getUsageColor(AppUsageInfo app) {
    final percentage = getUsagePercentage(app);
    if (percentage > 30) return Colors.red;
    if (percentage > 15) return Colors.orange;
    return Colors.green;
  }
}
