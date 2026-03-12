import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppIconCache {
  static final AppIconCache _instance = AppIconCache._internal();
  factory AppIconCache() => _instance;
  AppIconCache._internal();

  static const String _cacheKeyPrefix = 'app_icon_cache_';
  static const String _cacheInfoKey = 'app_icon_cache_info';
  static const int _maxCacheSize = 50;
  static const int _cacheExpiryDays = 7;

  final Map<String, Uint8List?> _memoryCache = {};
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadCacheInfo();
    await _cleanExpiredCache();
  }

  Future<Uint8List?> getIcon(String packageName) async {
    if (_memoryCache.containsKey(packageName)) {
      return _memoryCache[packageName];
    }
    await initialize();
    final cacheKey = _cacheKeyPrefix + packageName;
    final cachedData = _prefs!.getString(cacheKey);

    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(cachedData);
        final timestamp = DateTime.parse(data['timestamp']);

        if (DateTime.now().difference(timestamp).inDays < _cacheExpiryDays) {
          final iconBytes = base64Decode(data['iconData']);
          _memoryCache[packageName] = iconBytes;
          return iconBytes;
        } else {
          await _removeFromDisk(packageName);
        }
      } catch (e) {
        await _removeFromDisk(packageName);
      }
    }
    return null;
  }

  Future<void> storeIcon(String packageName, Uint8List iconBytes) async {
    await initialize();
    _memoryCache[packageName] = iconBytes;
    await _storeToDisk(packageName, iconBytes);
    await _cleanCache();


  }

  Future<void> _storeToDisk(String packageName, Uint8List iconBytes) async {
    try {
      final cacheKey = _cacheKeyPrefix + packageName;
      final data = {
        'iconData': base64Encode(iconBytes),
        'timestamp': DateTime.now().toIso8601String(),
        'size': iconBytes.length,
      };

      await _prefs!.setString(cacheKey, jsonEncode(data));
      await _updateCacheInfo(packageName, iconBytes.length);
    } catch (e) {
      debugPrint('❌ [CACHE] Error storing to disk: $e');
    }
  }

  /// Remove icon from disk
  Future<void> _removeFromDisk(String packageName) async {
    final cacheKey = _cacheKeyPrefix + packageName;
    await _prefs!.remove(cacheKey);
    await _removeCacheInfo(packageName);
  }

  /// Clean cache if it exceeds maximum size
  Future<void> _cleanCache() async {
    final cacheInfo = await _getCacheInfo();

    if (cacheInfo.length > _maxCacheSize) {
      // Sort by timestamp (oldest first)
      final sortedEntries =
          cacheInfo.entries.toList()..sort(
            (a, b) => a.value['timestamp'].compareTo(b.value['timestamp']),
          );

      // Remove oldest entries
      final toRemove = sortedEntries.take(cacheInfo.length - _maxCacheSize);
      for (var entry in toRemove) {
        await _removeFromDisk(entry.key);
        _memoryCache.remove(entry.key);
      }
    }
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    final cacheInfo = await _getCacheInfo();
    final now = DateTime.now();

    for (var entry in cacheInfo.entries) {
      final timestamp = DateTime.parse(entry.value['timestamp']);
      if (now.difference(timestamp).inDays >= _cacheExpiryDays) {
        await _removeFromDisk(entry.key);
        _memoryCache.remove(entry.key);
        debugPrint('⏰ [CACHE] Removed expired cache for: ${entry.key}');
      }
    }
  }

  /// Load cache info from SharedPreferences
  Future<void> _loadCacheInfo() async {
  }

  /// Get cache info
  Future<Map<String, Map<String, dynamic>>> _getCacheInfo() async {
    final infoString = _prefs!.getString(_cacheInfoKey);
    if (infoString != null) {
      try {
        final Map<String, dynamic> rawInfo = jsonDecode(infoString);
        return rawInfo.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
      } catch (e) {
        debugPrint('❌ [CACHE] Error reading cache info: $e');
        await _prefs!.remove(_cacheInfoKey);
      }
    }
    return {};
  }

  /// Update cache info
  Future<void> _updateCacheInfo(String packageName, int size) async {
    final cacheInfo = await _getCacheInfo();
    cacheInfo[packageName] = {
      'timestamp': DateTime.now().toIso8601String(),
      'size': size,
    };
    await _prefs!.setString(_cacheInfoKey, jsonEncode(cacheInfo));
  }

  /// Remove from cache info
  Future<void> _removeCacheInfo(String packageName) async {
    final cacheInfo = await _getCacheInfo();
    cacheInfo.remove(packageName);
    await _prefs!.setString(_cacheInfoKey, jsonEncode(cacheInfo));
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await initialize();

    // Clear memory cache
    _memoryCache.clear();

    // Clear disk cache
    final cacheInfo = await _getCacheInfo();
    for (var packageName in cacheInfo.keys) {
      await _removeFromDisk(packageName);
    }

    await _prefs!.remove(_cacheInfoKey);
    debugPrint('🗑️ [CACHE] All cache cleared');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    await initialize();
    final cacheInfo = await _getCacheInfo();

    int totalSize = 0;
    for (var info in cacheInfo.values) {
      totalSize += (info['size'] as int? ?? 0);
    }

    return {
      'totalApps': cacheInfo.length,
      'memoryApps': _memoryCache.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}

