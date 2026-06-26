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

  final AppIconCache _cache = AppIconCache();

  Future<Uint8List?> getAppIcon(String packageName) async {
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

  Future<Map<String, Uint8List?>> getMultipleAppIcons(
    List<String> packageNames,
  ) async {
    final Map<String, Uint8List?> result = {};
    final List<String> uncachedPackages = [];
    for (String packageName in packageNames) {
      final cachedIcon = await _cache.getIcon(packageName);
      if (cachedIcon != null) {
        result[packageName] = cachedIcon;
      } else {
        uncachedPackages.add(packageName);
      }
    }
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
        for (String packageName in uncachedPackages) {
          result[packageName] = null;
        }
      }
    }

    return result;
  }

  Future<void> clearCache() async {
    await _cache.clearAll();
  }

  Future<void> preloadIcons(List<String> packageNames) async {
    await getMultipleAppIcons(packageNames);
  }
  Future<bool> isIconCached(String packageName) async {
    final cachedIcon = await _cache.getIcon(packageName);
    return cachedIcon != null;
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    return await _cache.getStats();
  }
}
