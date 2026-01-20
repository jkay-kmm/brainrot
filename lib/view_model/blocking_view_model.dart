import 'package:flutter/foundation.dart';
import '../data/services/app_blocking_service.dart';
import '../data/model/blocking_rule.dart';
import '../data/model/focus_mode.dart';
import '../data/model/app_block_info.dart';

class BlockingViewModel extends ChangeNotifier {
  final AppBlockingService _blockingService = AppBlockingService();
  
  // State
  List<BlockingRule> _rules = [];
  List<FocusMode> _focusModes = [];
  Map<String, AppBlockInfo> _appBlockStatus = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BlockingRule> get rules => _rules;
  List<FocusMode> get focusModes => _focusModes;
  Map<String, AppBlockInfo> get appBlockStatus => _appBlockStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  FocusMode? get activeFocusMode => _blockingService.activeFocusMode;
  
  // Statistics
  int get activeRulesCount => _rules.where((rule) => rule.isActive).length;
  int get blockedAppsCount => _appBlockStatus.values.where((app) => app.isBlocked).length;
  int get limitedAppsCount => _appBlockStatus.values.where((app) => app.isLimited).length;
  int get allowedAppsCount => _appBlockStatus.values.where((app) => app.isAllowed).length;

  /// Get time until next daily reset (midnight)
  Duration get timeUntilDailyReset {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Get formatted time until daily reset
  String get formattedTimeUntilReset {
    final duration = timeUntilDailyReset;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Initialize the view model
  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _blockingService.initialize();
      
      // Listen to streams
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
      
      // Load initial data
      await _loadInitialData();
      
    } catch (e) {
      _setError('Failed to initialize blocking service: $e');
      debugPrint('❌ [BLOCKING_VM] Error initializing: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load initial data
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

  /// Refresh all data
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

  // ============================================================================
  // BLOCKING RULES MANAGEMENT
  // ============================================================================

  /// Add a new blocking rule
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

  /// Update an existing rule
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

  /// Delete a rule
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

  /// Toggle rule active status
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

  /// Get rules by type
  List<BlockingRule> getRulesByType(BlockingType type) {
    return _rules.where((rule) => rule.type == type).toList();
  }

  /// Get active rules
  List<BlockingRule> get activeRules {
    return _rules.where((rule) => rule.isActive).toList();
  }

  // ============================================================================
  // FOCUS MODES MANAGEMENT
  // ============================================================================

  /// Start a focus mode
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

  /// Stop the active focus mode
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

  /// Check if a focus mode is active
  bool isFocusModeActive(String focusModeId) {
    final activeFocus = activeFocusMode;
    return activeFocus != null && activeFocus.id == focusModeId;
  }

  // ============================================================================
  // APP BLOCKING STATUS
  // ============================================================================

  /// Get block status for a specific app
  AppBlockInfo? getAppBlockStatus(String packageName) {
    return _appBlockStatus[packageName];
  }

  /// Get apps by status
  List<AppBlockInfo> getAppsByStatus(AppBlockStatus status) {
    return _appBlockStatus.values.where((app) => app.status == status).toList();
  }

  /// Check if an app is blocked
  bool isAppBlocked(String packageName) {
    final blockInfo = _appBlockStatus[packageName];
    return blockInfo?.isBlocked ?? false;
  }

  /// Check if an app has time limits
  bool isAppLimited(String packageName) {
    final blockInfo = _appBlockStatus[packageName];
    return blockInfo?.isLimited ?? false;
  }

  // ============================================================================
  // USAGE TRACKING
  // ============================================================================

  /// Start tracking usage for an app
  void startAppSession(String packageName) {
    _blockingService.startAppSession(packageName);
  }

  /// End tracking usage for an app
  void endAppSession(String packageName) {
    _blockingService.endAppSession(packageName);
  }

  /// Reset daily usage
  Future<void> resetDailyUsage() async {
    try {
      await _blockingService.resetDailyUsage();
      await refresh(); // Refresh to update UI
      debugPrint('✅ [BLOCKING_VM] Daily usage reset');
    } catch (e) {
      _setError('Failed to reset daily usage: $e');
      debugPrint('❌ [BLOCKING_VM] Error resetting daily usage: $e');
    }
  }

  /// Reset session usage
  void resetSessionUsage() {
    _blockingService.resetSessionUsage();
    debugPrint('✅ [BLOCKING_VM] Session usage reset');
  }

  // ============================================================================
  // STATISTICS AND INSIGHTS
  // ============================================================================

  /// Get blocking effectiveness (percentage of time saved)
  double getBlockingEffectiveness() {
    final blockedApps = getAppsByStatus(AppBlockStatus.blocked);
    final totalApps = _appBlockStatus.length;
    
    if (totalApps == 0) return 0.0;
    return (blockedApps.length / totalApps) * 100;
  }

  /// Get most blocked app categories
  Map<String, int> getMostBlockedCategories() {
    // This would be implemented with actual app category data
    // For now, return mock data
    return {
      'Social Media': blockedAppsCount,
      'Games': (blockedAppsCount * 0.6).round(),
      'Entertainment': (blockedAppsCount * 0.4).round(),
    };
  }

  /// Get daily usage summary
  Map<String, Duration> getDailyUsageSummary() {
    final summary = <String, Duration>{};
    
    for (final app in _appBlockStatus.values) {
      if (app.dailyUsage != null) {
        summary[app.appName] = app.dailyUsage!;
      }
    }
    
    return summary;
  }

  /// Get time saved today (estimated)
  Duration getTimeSavedToday() {
    Duration totalSaved = Duration.zero;
    
    final blockedApps = getAppsByStatus(AppBlockStatus.blocked);
    // Estimate 30 minutes saved per blocked app (this could be more sophisticated)
    totalSaved = Duration(minutes: blockedApps.length * 30);
    
    return totalSaved;
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Dispose resources
  @override
  void dispose() {
    _blockingService.dispose();
    super.dispose();
  }

  // ============================================================================
  // QUICK ACTIONS
  // ============================================================================

  /// Quick action: Block social media for 1 hour
  Future<void> quickBlockSocialMedia() async {
    try {
      await startFocusMode('work', duration: const Duration(hours: 1));
    } catch (e) {
      _setError('Failed to start social media block: $e');
    }
  }

  /// Quick action: Start study mode
  Future<void> quickStartStudyMode() async {
    try {
      await startFocusMode('study', duration: const Duration(hours: 2));
    } catch (e) {
      _setError('Failed to start study mode: $e');
    }
  }

  /// Quick action: Enable bedtime mode
  Future<void> quickStartBedtimeMode() async {
    try {
      await startFocusMode('sleep', duration: const Duration(hours: 8));
    } catch (e) {
      _setError('Failed to start bedtime mode: $e');
    }
  }

  /// Quick action: Disable all blocking
  Future<void> quickDisableAllBlocking() async {
    try {
      // Stop focus mode
      if (activeFocusMode != null) {
        await stopFocusMode();
      }
      
      // Disable all active rules
      final activeRuleIds = activeRules.map((rule) => rule.id).toList();
      for (final ruleId in activeRuleIds) {
        await toggleRule(ruleId);
      }
      
      debugPrint('✅ [BLOCKING_VM] All blocking disabled');
    } catch (e) {
      _setError('Failed to disable all blocking: $e');
    }
  }
}
