import 'package:flutter/foundation.dart';
import '../data/services/app_blocking_service.dart';
import '../data/model/blocking_rule.dart';
import '../data/model/focus_mode.dart';
import '../data/model/app_block_info.dart';

class BlockingViewModel extends ChangeNotifier {
  final AppBlockingService _blockingService = AppBlockingService();
  List<BlockingRule> _rules = [];
  List<FocusMode> _focusModes = [];
  Map<String, AppBlockInfo> _appBlockStatus = {};
  bool _isLoading = false;
  String? _error;
  List<BlockingRule> get rules => _rules;

  List<FocusMode> get focusModes => _focusModes;

  Map<String, AppBlockInfo> get appBlockStatus => _appBlockStatus;

  bool get isLoading => _isLoading;

  String? get error => _error;

  FocusMode? get activeFocusMode => _blockingService.activeFocusMode;
  int get activeRulesCount =>
      _rules
          .where((rule) => rule.isActive)
          .length;

  int get blockedAppsCount =>
      _appBlockStatus.values
          .where((app) => app.isBlocked)
          .length;

  int get limitedAppsCount =>
      _appBlockStatus.values
          .where((app) => app.isLimited)
          .length;

  int get allowedAppsCount =>
      _appBlockStatus.values
          .where((app) => app.isAllowed)
          .length;
  Duration get timeUntilDailyReset {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  String get formattedTimeUntilReset {
    final duration = timeUntilDailyReset;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);

    try {
      await _blockingService.initialize();
      _blockingService.rulesStream.listen((rules) {
        _rules = rules;
        notifyListeners();
      });

      _blockingService.focusModesStream.listen((focusModes) {
        _focusModes = focusModes;
        notifyListeners();
      });

      _blockingService.blockStatusStream.listen((blockStatus) {
        _appBlockStatus = blockStatus;
        notifyListeners();
      });

      await _loadInitialData();
    } catch (e) {
      _setError('Failed to initialize blocking service: $e');
      debugPrint('❌ [BLOCKING_VM] Error initializing: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      _rules = _blockingService.rules;
      _focusModes = _blockingService.focusModes;
      _appBlockStatus = await _blockingService.getAllAppBlockStatus();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load initial data: $e');
      debugPrint('❌ [BLOCKING_VM] Error loading initial data: $e');
    }
  }

  Future<void> refresh() async {
    _setLoading(true);
    _setError(null);

    try {
      await _loadInitialData();
    } catch (e) {
      _setError('Failed to refresh data: $e');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> addRule(BlockingRule rule) async {
    try {
      await _blockingService.addRule(rule);
      debugPrint('✅ [BLOCKING_VM] Rule added: ${rule.name}');
    } catch (e) {
      _setError('Failed to add rule: $e');
      debugPrint('❌ [BLOCKING_VM] Error adding rule: $e');
      rethrow;
    }
  }

  Future<void> updateRule(BlockingRule rule) async {
    try {
      await _blockingService.updateRule(rule);
      debugPrint('✅ [BLOCKING_VM] Rule updated: ${rule.name}');
    } catch (e) {
      _setError('Failed to update rule: $e');
      debugPrint('❌ [BLOCKING_VM] Error updating rule: $e');
      rethrow;
    }
  }

  Future<void> deleteRule(String ruleId) async {
    try {
      await _blockingService.deleteRule(ruleId);
      debugPrint('✅ [BLOCKING_VM] Rule deleted: $ruleId');
    } catch (e) {
      _setError('Failed to delete rule: $e');
      debugPrint('❌ [BLOCKING_VM] Error deleting rule: $e');
      rethrow;
    }
  }

  Future<void> toggleRule(String ruleId) async {
    try {
      await _blockingService.toggleRule(ruleId);
      debugPrint('✅ [BLOCKING_VM] Rule toggled: $ruleId');
    } catch (e) {
      _setError('Failed to toggle rule: $e');
      debugPrint('❌ [BLOCKING_VM] Error toggling rule: $e');
      rethrow;
    }
  }

  List<BlockingRule> getRulesByType(BlockingType type) {
    return _rules.where((rule) => rule.type == type).toList();
  }

  List<BlockingRule> get activeRules {
    return _rules.where((rule) => rule.isActive).toList();
  }
  Future<void> startFocusMode(String focusModeId, {Duration? duration}) async {
    try {
      await _blockingService.startFocusMode(focusModeId, duration: duration);
      debugPrint('✅ [BLOCKING_VM] Focus mode started: $focusModeId');
    } catch (e) {
      _setError('Failed to start focus mode: $e');
      debugPrint('❌ [BLOCKING_VM] Error starting focus mode: $e');
      rethrow;
    }
  }

  Future<void> stopFocusMode() async {
    try {
      await _blockingService.stopFocusMode();
      debugPrint('✅ [BLOCKING_VM] Focus mode stopped');
    } catch (e) {
      _setError('Failed to stop focus mode: $e');
      debugPrint('❌ [BLOCKING_VM] Error stopping focus mode: $e');
      rethrow;
    }
  }

  bool isFocusModeActive(String focusModeId) {
    final activeFocus = activeFocusMode;
    return activeFocus != null && activeFocus.id == focusModeId;
  }
  AppBlockInfo? getAppBlockStatus(String packageName) {
    return _appBlockStatus[packageName];
  }

  List<AppBlockInfo> getAppsByStatus(AppBlockStatus status) {
    return _appBlockStatus.values.where((app) => app.status == status).toList();
  }

  bool isAppBlocked(String packageName) {
    final blockInfo = _appBlockStatus[packageName];
    return blockInfo?.isBlocked ?? false;
  }

  bool isAppLimited(String packageName) {
    final blockInfo = _appBlockStatus[packageName];
    return blockInfo?.isLimited ?? false;
  }
  void startAppSession(String packageName) {
    _blockingService.startAppSession(packageName);
  }

  void endAppSession(String packageName) {
    _blockingService.endAppSession(packageName);
  }

  Future<void> resetDailyUsage() async {
    try {
      await _blockingService.resetDailyUsage();
      await refresh();
      debugPrint('✅ [BLOCKING_VM] Daily usage reset');
    } catch (e) {
      _setError('Failed to reset daily usage: $e');
      debugPrint('❌ [BLOCKING_VM] Error resetting daily usage: $e');
    }
  }

  void resetSessionUsage() {
    _blockingService.resetSessionUsage();
    debugPrint('✅ [BLOCKING_VM] Session usage reset');
  }
  double getBlockingEffectiveness() {
    final blockedApps = getAppsByStatus(AppBlockStatus.blocked);
    final totalApps = _appBlockStatus.length;

    if (totalApps == 0) return 0.0;
    return (blockedApps.length / totalApps) * 100;
  }

  Map<String, int> getMostBlockedCategories() {
    return {
      'Social Media': blockedAppsCount,
      'Games': (blockedAppsCount * 0.6).round(),
      'Entertainment': (blockedAppsCount * 0.4).round(),
    };
  }

  Map<String, Duration> getDailyUsageSummary() {
    final summary = <String, Duration>{};

    for (final app in _appBlockStatus.values) {
      if (app.dailyUsage != null) {
        summary[app.appName] = app.dailyUsage!;
      }
    }

    return summary;
  }

  Duration getTimeSavedToday() {
    Duration totalSaved = Duration.zero;

    final blockedApps = getAppsByStatus(AppBlockStatus.blocked);
    totalSaved = Duration(minutes: blockedApps.length * 30);

    return totalSaved;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  @override
  void dispose() {
    _blockingService.dispose();
    super.dispose();
  }

}
