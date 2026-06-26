import 'dart:math';
import '../model/app_usage_info.dart';

class AppUsageService {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  Future<bool> hasUsagePermission() async {
    return true;
  }

  Future<bool> requestUsagePermission() async {
    return true;
  }

  Future<List<AppUsageInfo>> getTodayUsage() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      return _generateRealisticMockData();
    } catch (e) {
      print('Error getting today usage: $e');
      return [];
    }
  }

  Future<List<AppUsageInfo>> getUsageInRange(DateTime startTime, DateTime endTime) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return _generateRealisticMockData();
    } catch (e) {
      print('Error getting usage in range: $e');
      return [];
    }
  }

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
      final baseMinutes = app['baseMinutes'] as int;
      final variation = random.nextDouble() * 1.5 + 0.5;
      final actualMinutes = (baseMinutes * variation).round();
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

    usageList.sort((a, b) => b.usage.compareTo(a.usage));
    
    return usageList;
  }

  Duration getTotalUsage(List<AppUsageInfo> usageList) {
    return usageList.fold(
      Duration.zero,
      (total, app) => total + app.usage,
    );
  }

  List<AppUsageInfo> getTopUsedApps(List<AppUsageInfo> usageList, {int limit = 10}) {
    final sorted = List<AppUsageInfo>.from(usageList);
    sorted.sort((a, b) => b.usage.compareTo(a.usage));
    return sorted.take(limit).toList();
  }

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

  Future<List<AppUsageInfo>> refreshUsageData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _generateRealisticMockData();
  }

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
