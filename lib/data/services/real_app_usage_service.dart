import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../model/app_usage_info.dart';

class RealAppUsageService {
  static const MethodChannel _channel = MethodChannel('com.example.brainrot/usage');
  static final RealAppUsageService _instance = RealAppUsageService._internal();
  factory RealAppUsageService() => _instance;
  RealAppUsageService._internal();

  Future<bool> hasUsagePermission() async {
    try {
      final bool? hasPermission = await _channel.invokeMethod('hasUsagePermission');
      return hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestUsagePermission() async {
    try {
      final bool? granted = await _channel.invokeMethod('requestUsagePermission');
      return granted ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<AppUsageInfo>> getTodayUsage() async {
    try {
      final List<dynamic>? rawData = await _channel.invokeMethod('getUsageStats');

      if (rawData != null && rawData.isNotEmpty) {
        List<AppUsageInfo> usageList = rawData.map((data) {
          final Map<String, dynamic> appData = Map<String, dynamic>.from(data);
          final now = DateTime.now();
          return AppUsageInfo(
            packageName: appData['packageName'] ?? '',
            appName: appData['appName'] ?? 'Unknown App',
            usage: Duration(milliseconds: (appData['usageTimeMillis'] ?? 0).toInt()),
            startTime: DateTime(now.year, now.month, now.day),
            endTime: now,
          );
        }).toList();

        usageList = usageList.where((app) => app.usage.inSeconds >= 10).toList();
        usageList.sort((a, b) => b.usage.compareTo(a.usage));

        for (var app in usageList.take(5)) {
          debugPrint('   ${app.appName}: ${app.formattedUsage}');
        }

        return usageList;
      } else {
        bool hasPermission = await hasUsagePermission();
        if (!hasPermission) {
          await requestUsagePermission();
        }

        return _getFallbackData();
      }

    } catch (e) {

      return _getFallbackData();
    }
  }

  Future<List<AppUsageInfo>> refreshTodayUsage() async {
    try {
      final List<dynamic>? rawData = await _channel.invokeMethod('refreshUsageStats');
      if (rawData != null && rawData.isNotEmpty) {
        List<AppUsageInfo> usageList = rawData.map((data) {
          final Map<String, dynamic> appData = Map<String, dynamic>.from(data);
          final now = DateTime.now();
          return AppUsageInfo(
            packageName: appData['packageName'] ?? '',
            appName: appData['appName'] ?? 'Unknown App',
            usage: Duration(milliseconds: (appData['usageTimeMillis'] ?? 0).toInt()),
            startTime: DateTime(now.year, now.month, now.day),
            endTime: now,
          );
        }).toList();

        usageList = usageList.where((app) => app.usage.inSeconds >= 10).toList();
        usageList.sort((a, b) => b.usage.compareTo(a.usage));

        for (var app in usageList.take(5)) {
          ('   ${app.appName}: ${app.formattedUsage}');
        }
        return usageList;
      } else {
        return _getFallbackData();
      }

    } catch (e) {
      return _getFallbackData();
    }
  }

  Future<List<AppUsageInfo>> getUsageInRange(DateTime startTime, DateTime endTime) async {
    return await getTodayUsage();
  }

  List<AppUsageInfo> _getFallbackData() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return [
      AppUsageInfo(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        usage: const Duration(hours: 1, minutes: 30),
        startTime: startOfDay,
        endTime: now,
      ),
      AppUsageInfo(
        packageName: 'com.tiktok.musically',
        appName: 'TikTok',
        usage: const Duration(hours: 1, minutes: 15),
        startTime: startOfDay,
        endTime: now,
      ),
      AppUsageInfo(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        usage: const Duration(minutes: 45),
        startTime: startOfDay,
        endTime: now,
      ),
      AppUsageInfo(
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        usage: const Duration(minutes: 30),
        startTime: startOfDay,
        endTime: now,
      ),
      AppUsageInfo(
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        usage: const Duration(minutes: 25),
        startTime: startOfDay,
        endTime: now,
      ),
    ];
  }

  List<AppUsageInfo> getTopUsedApps(List<AppUsageInfo> apps, {int limit = 5}) {
    final sortedApps = List<AppUsageInfo>.from(apps);
    sortedApps.sort((a, b) => b.usage.compareTo(a.usage));
    return sortedApps.take(limit).toList();
  }

  Map<String, dynamic> getUsageStats(List<AppUsageInfo> apps) {
    if (apps.isEmpty) {
      return {
        'totalApps': 0,
        'totalUsage': Duration.zero,
        'averageUsage': Duration.zero,
        'mostUsedApp': null,
      };
    }

    final totalUsage = apps.fold<Duration>(
      Duration.zero,
          (sum, app) => sum + app.usage,
    );

    final averageUsage = Duration(
      milliseconds: totalUsage.inMilliseconds ~/ apps.length,
    );

    final mostUsedApp = apps.reduce(
          (current, next) => current.usage > next.usage ? current : next,
    );

    return {
      'totalApps': apps.length,
      'totalUsage': totalUsage,
      'averageUsage': averageUsage,
      'mostUsedApp': mostUsedApp,
    };
  }
}
