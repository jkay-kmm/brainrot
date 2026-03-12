import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/blocking_rule.dart';
import '../model/app_block_info.dart';
import '../model/focus_mode.dart';
import '../model/app_usage_info.dart';
import 'app_usage_service.dart';
import 'real_app_usage_service.dart';
import 'usage_history_service.dart';

class AppBlockingService {
  static final AppBlockingService _instance = AppBlockingService._internal();
  factory AppBlockingService() => _instance;
  AppBlockingService._internal();

  // Storage keys - must match Android native service keys
  static const String _rulesKey = 'flutter.blocking_rules';
  static const String _focusModesKey = 'flutter.focus_modes';
  static const String _dailyUsageKey = 'flutter.daily_usage_tracking';
  static const String _sessionUsageKey = 'flutter.session_usage_tracking';
  static const String _lastResetDateKey = 'flutter.last_reset_date';

  // In-memory cache
  List<BlockingRule> _rules = [];
  List<FocusMode> _focusModes = [];
  Map<String, Duration> _dailyUsageCache = {};
  Map<String, Duration> _sessionUsageCache = {};
  Map<String, DateTime> _sessionStartTimes = {};
  DateTime? _lastResetDate;

  // Stream controllers for real-time updates
  final StreamController<List<BlockingRule>> _rulesController =
      StreamController.broadcast();
  final StreamController<List<FocusMode>> _focusModesController =
      StreamController.broadcast();
  final StreamController<Map<String, AppBlockInfo>> _blockStatusController =
      StreamController.broadcast();

  // Getters for streams
  Stream<List<BlockingRule>> get rulesStream => _rulesController.stream;
  Stream<List<FocusMode>> get focusModesStream => _focusModesController.stream;
  Stream<Map<String, AppBlockInfo>> get blockStatusStream =>
      _blockStatusController.stream;

  // Services
  final AppUsageService _mockUsageService = AppUsageService();
  final RealAppUsageService _realUsageService = RealAppUsageService();
  final UsageHistoryService _historyService = UsageHistoryService();


  Timer? _periodicTimer;
  Timer? _dailyResetTimer;
  Future<void> initialize() async {

    await _loadRules();
    await _loadFocusModes();
    await _loadUsageTracking();
    await _loadLastResetDate();
    await _checkAndResetDailyUsage();
    _startPeriodicMonitoring();

    _startDailyResetScheduler();
  }

  void dispose() {
    _periodicTimer?.cancel();
    _dailyResetTimer?.cancel();
    _rulesController.close();
    _focusModesController.close();
    _blockStatusController.close();
  }

  List<BlockingRule> get rules => List.unmodifiable(_rules);
  Future<void> addRule(BlockingRule rule) async {
    _rules.add(rule);
    await _saveRules();
    _rulesController.add(_rules);
    await _updateBlockStatus();
  }

  Future<void> updateRule(BlockingRule updatedRule) async {

    final index = _rules.indexWhere((rule) => rule.id == updatedRule.id);
    if (index != -1) {
      _rules[index] = updatedRule.copyWith(updatedAt: DateTime.now());
      await _saveRules();
      _rulesController.add(_rules);
      await _updateBlockStatus();
    }
  }

  Future<void> deleteRule(String ruleId) async {

    _rules.removeWhere((rule) => rule.id == ruleId);
    await _saveRules();
    _rulesController.add(_rules);

    await _updateBlockStatus();
  }

  Future<void> toggleRule(String ruleId) async {
    final rule = _rules.firstWhere((r) => r.id == ruleId);
    final newStatus =
        rule.status == RuleStatus.active
            ? RuleStatus.inactive
            : RuleStatus.active;

    await updateRule(rule.copyWith(status: newStatus));
  }
  List<FocusMode> get focusModes => List.unmodifiable(_focusModes);

  FocusMode? get activeFocusMode {
    try {
      return _focusModes.firstWhere((mode) => mode.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<void> startFocusMode(String focusModeId, {Duration? duration}) async {
    for (int i = 0; i < _focusModes.length; i++) {
      if (_focusModes[i].isActive) {
        _focusModes[i] = _focusModes[i].copyWith(isActive: false);
      }
    }

    final index = _focusModes.indexWhere((mode) => mode.id == focusModeId);
    if (index != -1) {
      final now = DateTime.now();
      _focusModes[index] = _focusModes[index].copyWith(
        isActive: true,
        startTime: now,
        endTime: duration != null ? now.add(duration) : null,
        duration: duration,
      );

      await _saveFocusModes();
      _focusModesController.add(_focusModes);
      await _updateBlockStatus();
    }
  }

  Future<void> stopFocusMode() async {

    for (int i = 0; i < _focusModes.length; i++) {
      if (_focusModes[i].isActive) {
        _focusModes[i] = _focusModes[i].copyWith(isActive: false);
      }
    }

    await _saveFocusModes();
    _focusModesController.add(_focusModes);

    await _updateBlockStatus();
  }

  Future<AppBlockInfo> getAppBlockStatus(
    String packageName,
    String appName,
  ) async {
    // Get current usage
    final dailyUsage = _dailyUsageCache[packageName] ?? Duration.zero;
    final sessionUsage = _sessionUsageCache[packageName] ?? Duration.zero;

    // Check all active rules
    final activeRules = <String>[];
    AppBlockStatus status = AppBlockStatus.allowed;
    String? blockReason;
    Duration? dailyLimit;
    Duration? sessionLimit;
    bool canBypass = false;

    // Check focus mode first
    final activeFocus = activeFocusMode;
    if (activeFocus != null && activeFocus.shouldBlockPackage(packageName)) {
      status = AppBlockStatus.blocked;
      blockReason = 'Blocked by ${activeFocus.name}';
      canBypass = activeFocus.allowEmergency;
      activeRules.add(activeFocus.id);
    }

    // Check blocking rules
    for (final rule in _rules.where((r) => r.isActive)) {
      if (rule.shouldBlockPackage(packageName)) {
        activeRules.add(rule.id);

        switch (rule.type) {
          case BlockingType.allDayBlock:
          case BlockingType.schedule:
            status = AppBlockStatus.blocked;
            blockReason = rule.customBlockMessage ?? 'Blocked by ${rule.name}';
            canBypass = rule.allowEmergencyBypass;
            break;

          case BlockingType.timeLimit:
            dailyLimit = rule.dailyLimit;
            sessionLimit = rule.sessionLimit;

            // Check daily limit
            if (rule.dailyLimit != null && dailyUsage >= rule.dailyLimit!) {
              status = AppBlockStatus.blocked;
              blockReason = 'Daily time limit reached (${rule.name})';
              canBypass = rule.allowEmergencyBypass;
            }
            // Check session limit
            else if (rule.sessionLimit != null &&
                sessionUsage >= rule.sessionLimit!) {
              status = AppBlockStatus.blocked;
              blockReason = 'Session time limit reached (${rule.name})';
              canBypass = rule.allowEmergencyBypass;
            }
            // Check warning threshold
            else if (rule.showUsageWarning && rule.warningThreshold != null) {
              if (dailyUsage >= rule.warningThreshold!) {
                status = AppBlockStatus.warning;
                blockReason = 'Approaching time limit (${rule.name})';
              }
            }
            break;

          case BlockingType.focusMode:
            // Handled above in focus mode check
            break;
        }

        // If already blocked, no need to check further
        if (status == AppBlockStatus.blocked) break;
      }
    }

    return AppBlockInfo(
      packageName: packageName,
      appName: appName,
      status: status,
      dailyUsage: dailyUsage,
      dailyLimit: dailyLimit,
      sessionUsage: sessionUsage,
      sessionLimit: sessionLimit,
      activeRuleIds: activeRules,
      blockReason: blockReason,
      canBypass: canBypass,
    );
  }

  /// Get block status for all apps
  Future<Map<String, AppBlockInfo>> getAllAppBlockStatus() async {
    final Map<String, AppBlockInfo> result = {};

    // Get app usage data
    List<AppUsageInfo> usageData = [];
    try {
      usageData = await _realUsageService.getTodayUsage();
      if (usageData.isEmpty) {
        usageData = await _mockUsageService.getTodayUsage();
      }
    } catch (e) {
      usageData = await _mockUsageService.getTodayUsage();
    }

    // Check each app
    for (final app in usageData) {
      final blockInfo = await getAppBlockStatus(app.packageName, app.appName);
      result[app.packageName] = blockInfo;
    }

    return result;
  }

  void startAppSession(String packageName) {
    _sessionStartTimes[packageName] = DateTime.now();
  }

  void endAppSession(String packageName) {
    final startTime = _sessionStartTimes[packageName];
    if (startTime != null) {
      final sessionDuration = DateTime.now().difference(startTime);

      // Update session usage
      _sessionUsageCache[packageName] =
          (_sessionUsageCache[packageName] ?? Duration.zero) + sessionDuration;

      // Update daily usage
      _dailyUsageCache[packageName] =
          (_dailyUsageCache[packageName] ?? Duration.zero) + sessionDuration;

      _sessionStartTimes.remove(packageName);
      _saveUsageTracking();
    }
  }

  Future<void> resetDailyUsage() async {
    _dailyUsageCache.clear();
    await _saveUsageTracking();
  }

  void resetSessionUsage() {
    _sessionUsageCache.clear();
    _sessionStartTimes.clear();
  }

  void _startPeriodicMonitoring() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateBlockStatus();
      _checkFocusModeExpiry();
    });
  }

  Future<void> _updateBlockStatus() async {
    final blockStatus = await getAllAppBlockStatus();
    _blockStatusController.add(blockStatus);
  }

  void _checkFocusModeExpiry() {
    final activeFocus = activeFocusMode;
    if (activeFocus != null && activeFocus.endTime != null) {
      if (DateTime.now().isAfter(activeFocus.endTime!)) {
        stopFocusMode();
      }
    }
  }

  void _startDailyResetScheduler() {
    // Calculate time until next midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _dailyResetTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      
      // Then schedule periodic daily resets every 24 hours
      _dailyResetTimer = Timer.periodic(const Duration(days: 1), (timer) {
        _performDailyReset();
      });
    });
  }

  /// Perform daily reset at midnight
  Future<void> _performDailyReset() async {
    try {
      await _historyService.saveTodayUsage();
    } catch (e) {
    }
    
    await resetDailyUsage();
    await _saveLastResetDate(DateTime.now());
    await _updateBlockStatus();
  }
  Future<void> _checkAndResetDailyUsage() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastResetDate == null) {
      // First time running, set last reset to today
      await _saveLastResetDate(today);
      return;
    }
    final lastResetDay = DateTime(_lastResetDate!.year, _lastResetDate!.month, _lastResetDate!.day);
    if (lastResetDay.isBefore(today)) {
      await resetDailyUsage();
      await _saveLastResetDate(today);
    }
  }

  /// Load rules from storage
  Future<void> _loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getString(_rulesKey);

      if (rulesJson != null) {
        final List<dynamic> rulesList = jsonDecode(rulesJson);
        _rules = rulesList.map((json) => BlockingRule.fromJson(json)).toList();
      } else {
        _rules = _getDefaultRules();
        await _saveRules();
      }
    } catch (e) {
      _rules = _getDefaultRules();
    }
  }
  Future<void> _saveRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = jsonEncode(
        _rules.map((rule) => rule.toJson()).toList(),
      );
      await prefs.setString(_rulesKey, rulesJson);
    } catch (e) {
      debugPrint('❌ [BLOCKING] Error saving rules: $e');
    }
  }

  Future<void> _loadFocusModes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final focusModesJson = prefs.getString(_focusModesKey);

      if (focusModesJson != null) {
        final List<dynamic> focusModesList = jsonDecode(focusModesJson);
        _focusModes =
            focusModesList.map((json) => FocusMode.fromJson(json)).toList();
      } else {
        _focusModes = List.from(FocusMode.predefinedModes);
        await _saveFocusModes();
      }
    } catch (e) {
      _focusModes = List.from(FocusMode.predefinedModes);
    }
  }

  Future<void> _saveFocusModes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final focusModesJson = jsonEncode(
        _focusModes.map((mode) => mode.toJson()).toList(),
      );
      await prefs.setString(_focusModesKey, focusModesJson);
    } catch (e) {
    }
  }

  Future<void> _loadUsageTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load daily usage
      final dailyUsageJson = prefs.getString(_dailyUsageKey);
      if (dailyUsageJson != null) {
        final Map<String, dynamic> dailyUsageMap = jsonDecode(dailyUsageJson);
        _dailyUsageCache = dailyUsageMap.map(
          (key, value) => MapEntry(key, Duration(milliseconds: value)),
        );
      }

      // Load session usage
      final sessionUsageJson = prefs.getString(_sessionUsageKey);
      if (sessionUsageJson != null) {
        final Map<String, dynamic> sessionUsageMap = jsonDecode(
          sessionUsageJson,
        );
        _sessionUsageCache = sessionUsageMap.map(
          (key, value) => MapEntry(key, Duration(milliseconds: value)),
        );
      }
    } catch (e) {
      debugPrint('❌ [BLOCKING] Error loading usage tracking: $e');
    }
  }

  /// Save usage tracking data
  Future<void> _saveUsageTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyUsageMap = _dailyUsageCache.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      );
      await prefs.setString(_dailyUsageKey, jsonEncode(dailyUsageMap));
      final sessionUsageMap = _sessionUsageCache.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      );
      await prefs.setString(_sessionUsageKey, jsonEncode(sessionUsageMap));
    } catch (e) {
      debugPrint('❌ [BLOCKING] Error saving usage tracking: $e');
    }
  }

  /// Load last reset date
  Future<void> _loadLastResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetString = prefs.getString(_lastResetDateKey);
      
      if (lastResetString != null) {
        _lastResetDate = DateTime.parse(lastResetString);
        debugPrint('📥 [BLOCKING] Loaded last reset date: ${_lastResetDate}');
      } else {
        debugPrint('📥 [BLOCKING] No previous reset date found');
      }
    } catch (e) {
      debugPrint('❌ [BLOCKING] Error loading last reset date: $e');
    }
  }

  /// Save last reset date
  Future<void> _saveLastResetDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastResetDateKey, date.toIso8601String());
      _lastResetDate = date;
      debugPrint('💾 [BLOCKING] Saved last reset date: $date');
    } catch (e) {
      debugPrint('❌ [BLOCKING] Error saving last reset date: $e');
    }
  }

  /// Get default blocking rules
  List<BlockingRule> _getDefaultRules() {
    return [
      BlockingRule(
        id: 'social_media_limit',
        name: '2h Social Media Limit',
        description: '⏰ 120 minutes daily',
        type: BlockingType.timeLimit,
        targetPackages: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.tiktok',
          'com.snapchat.android',
        ],
        dailyLimit: const Duration(hours: 2),
        createdAt: DateTime.now(),
        status: RuleStatus.inactive,
        showUsageWarning: true,
        warningThreshold: const Duration(minutes: 90),
      ),
      BlockingRule(
        id: 'evening_focus',
        name: 'Evening Focus Mode',
        description: '📅 every day 20:00-23:59',
        type: BlockingType.schedule,
        targetPackages: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.tiktok',
        ],
        startTime: const TimeOfDay(hour: 20, minute: 0),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        createdAt: DateTime.now(),
        status: RuleStatus.inactive,
      ),
      BlockingRule(
        id: 'work_focus',
        name: 'Work Focus Mode',
        description: '📅 weekdays 09:00-17:00',
        type: BlockingType.schedule,
        targetPackages: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
          'com.tiktok',
          'com.snapchat.android',
        ],
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        daysOfWeek: [1, 2, 3, 4, 5], // Monday to Friday
        createdAt: DateTime.now(),
        status: RuleStatus.inactive,
      ),
      BlockingRule(
        id: 'social_media_block',
        name: 'Social Media Block',
        description: '🌙 all day',
        type: BlockingType.allDayBlock,
        targetPackages: [
          'com.instagram.android',
          'com.facebook.katana',
          'com.twitter.android',
        ],
        createdAt: DateTime.now(),
        status: RuleStatus.inactive,
      ),
    ];
  }
}
