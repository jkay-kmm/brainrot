import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_icon_cache.dart';

class AppIconService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.brainrot/usage',
  );
  static final AppIconService _instance = AppIconService._internal();
  factory AppIconService() => _instance;
  AppIconService._internal();

  // Advanced cache system with persistent storage
  final AppIconCache _cache = AppIconCache();

  /// Lấy icon của một app
  Future<Uint8List?> getAppIcon(String packageName) async {
    // Kiểm tra cache trước
    final cachedIcon = await _cache.getIcon(packageName);
    if (cachedIcon != null) {
      return cachedIcon;
    }

    try {


      final List<dynamic>? iconBytes = await _channel.invokeMethod(
        'getAppIcon',
        {'packageName': packageName},
      );

  

      if (iconBytes != null) {
        final iconData = Uint8List.fromList(iconBytes.cast<int>());
        await _cache.storeIcon(packageName, iconData);
        return iconData;
      } else {
    
        return null;
      }
    } catch (e) {
  
      if (e is PlatformException) {
      
      }
      return null;
    }
  }

  /// Lấy icon của nhiều apps cùng lúc (hiệu quả hơn)
  Future<Map<String, Uint8List?>> getMultipleAppIcons(
    List<String> packageNames,
  ) async {
    final Map<String, Uint8List?> result = {};
    final List<String> uncachedPackages = [];

    // Kiểm tra cache trước
    for (String packageName in packageNames) {
      final cachedIcon = await _cache.getIcon(packageName);
      if (cachedIcon != null) {
        result[packageName] = cachedIcon;
      } else {
        uncachedPackages.add(packageName);
      }
    }

    // Lấy các icon chưa có trong cache
    if (uncachedPackages.isNotEmpty) {
      try {
      

        final Map<dynamic, dynamic>? iconsMap = await _channel.invokeMethod(
          'getMultipleAppIcons',
          {'packageNames': uncachedPackages},
        );

        if (iconsMap != null) {
          for (String packageName in uncachedPackages) {
            final List<dynamic>? iconBytes = iconsMap[packageName];

            if (iconBytes != null) {
              final iconData = Uint8List.fromList(iconBytes.cast<int>());
              await _cache.storeIcon(packageName, iconData);
              result[packageName] = iconData;
            
            } else {
              result[packageName] = null;
            
            }
          }
        }
      } catch (e) {
    

        // Set null cho các packages không lấy được
        for (String packageName in uncachedPackages) {
          result[packageName] = null;
        }
      }
    }

    return result;
  }

  /// Clear cache (dùng khi cần refresh)
  Future<void> clearCache() async {
    await _cache.clearAll();
  
  }

  /// Preload icons cho performance tốt hơn
  Future<void> preloadIcons(List<String> packageNames) async {
  
    await getMultipleAppIcons(packageNames);
  
  }

  /// Check if icon is cached
  Future<bool> isIconCached(String packageName) async {
    final cachedIcon = await _cache.getIcon(packageName);
    return cachedIcon != null;
  }

  /// Get cache size info
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await _cache.getStats();
  }
}
