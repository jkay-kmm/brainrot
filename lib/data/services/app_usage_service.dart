import 'dart:math';
import '../model/app_usage_info.dart';

class AppUsageService {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  /// Check if usage access permission is granted
  Future<bool> hasUsagePermission() async {
    // For development, always return true
    // In production, you would implement actual permission checking
    return true;
  }

  /// Request usage access permission
  Future<bool> requestUsagePermission() async {
    // For development, always return true
    // In production, you would implement actual permission request
    return true;
  }

  /// Get app usage data for today
  Future<List<AppUsageInfo>> getTodayUsage() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      return _generateRealisticMockData();
    } catch (e) {
      print('Error getting today usage: $e');
      return [];
    }
  }

  /// Get app usage data for a specific date range
  Future<List<AppUsageInfo>> getUsageInRange(DateTime startTime, DateTime endTime) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate realistic mock data
      return _generateRealisticMockData();
    } catch (e) {
      print('Error getting usage in range: $e');
      return [];
    }
  }

  /// Generate realistic mock data with random variations
  List<AppUsageInfo> _generateRealisticMockData() {
    final random = Random();
    final now = DateTime.now();
    
    final apps = [
      {'package': 'com.instagram.android', 'name': 'Instagram', 'baseMinutes': 90},
      {'package': 'com.tiktok.musically', 'name': 'TikTok', 'baseMinutes': 80},
      {'package': 'com.whatsapp', 'name': 'WhatsApp', 'baseMinutes': 70},
      {'package': 'com.youtube.android', 'name': 'YouTube', 'baseMinutes': 60},
      {'package': 'com.spotify.music', 'name': 'Spotify', 'baseMinutes': 45},
      {'package': 'com.android.chrome', 'name': 'Chrome', 'baseMinutes': 35},
      {'package': 'com.facebook.katana', 'name': 'Facebook', 'baseMinutes': 25},
      {'package': 'com.discord', 'name': 'Discord', 'baseMinutes': 20},
      {'package': 'com.twitter.android', 'name': 'Twitter', 'baseMinutes': 15},
      {'package': 'com.snapchat.android', 'name': 'Snapchat', 'baseMinutes': 12},
      {'package': 'com.linkedin.android', 'name': 'LinkedIn', 'baseMinutes': 8},
      {'package': 'com.reddit.frontpage', 'name': 'Reddit', 'baseMinutes': 18},
    ];

    List<AppUsageInfo> usageList = [];
    
    for (var app in apps) {
      // Add random variation (-50% to +100%)
      final baseMinutes = app['baseMinutes'] as int;
      final variation = random.nextDouble() * 1.5 + 0.5; // 0.5 to 2.0
      final actualMinutes = (baseMinutes * variation).round();
      
      // Skip apps with very low usage sometimes
      if (actualMinutes < 5 && random.nextBool()) continue;
      
      final startTime = now.subtract(Duration(hours: random.nextInt(12) + 1));
      
      usageList.add(AppUsageInfo(
        packageName: app['package'] as String,
        appName: app['name'] as String,
        usage: Duration(minutes: actualMinutes),
        startTime: startTime,
        endTime: now,
      ));
    }

    // Sort by usage duration (highest first)
    usageList.sort((a, b) => b.usage.compareTo(a.usage));
    
    return usageList;
  }

  /// Get total usage time for all apps
  Duration getTotalUsage(List<AppUsageInfo> usageList) {
    return usageList.fold(
      Duration.zero,
      (total, app) => total + app.usage,
    );
  }

  /// Get top N most used apps
  List<AppUsageInfo> getTopUsedApps(List<AppUsageInfo> usageList, {int limit = 10}) {
    final sorted = List<AppUsageInfo>.from(usageList);
    sorted.sort((a, b) => b.usage.compareTo(a.usage));
    return sorted.take(limit).toList();
  }

  /// Get usage statistics
  Map<String, dynamic> getUsageStats(List<AppUsageInfo> usageList) {
    if (usageList.isEmpty) {
      return {
        'totalApps': 0,
        'totalUsage': Duration.zero,
        'averageUsage': Duration.zero,
        'mostUsedApp': null,
      };
    }

    final totalUsage = getTotalUsage(usageList);
    final mostUsed = usageList.first;

    return {
      'totalApps': usageList.length,
      'totalUsage': totalUsage,
      'averageUsage': Duration(milliseconds: totalUsage.inMilliseconds ~/ usageList.length),
      'mostUsedApp': mostUsed,
    };
  }

  /// Simulate refreshing data with new variations
  Future<List<AppUsageInfo>> refreshUsageData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _generateRealisticMockData();
  }

  /// Get usage trend (mock data)
  Map<String, int> getUsageTrend() {
    final random = Random();
    return {
      'Monday': random.nextInt(300) + 200,
      'Tuesday': random.nextInt(300) + 200,
      'Wednesday': random.nextInt(300) + 200,
      'Thursday': random.nextInt(300) + 200,
      'Friday': random.nextInt(300) + 200,
      'Saturday': random.nextInt(400) + 300,
      'Sunday': random.nextInt(400) + 300,
    };
  }
}
