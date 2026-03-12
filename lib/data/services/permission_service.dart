import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.brainrot/usage',
  );
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if overlay permission is granted
  Future<bool> hasOverlayPermission() async {
    try {
      final bool? hasPermission = await _channel.invokeMethod(
        'hasOverlayPermission',
      );
      return hasPermission ?? false;
    } catch (e) {
      debugPrint('❌ [PERMISSION] Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request overlay permission
  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('❌ [PERMISSION] Error requesting overlay permission: $e');
    }
  }

  /// Check if accessibility permission is granted
  Future<bool> hasAccessibilityPermission() async {
    try {
      final bool? hasPermission = await _channel.invokeMethod(
        'hasAccessibilityPermission',
      );
      return hasPermission ?? false;
    } catch (e) {
      debugPrint('❌ [PERMISSION] Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Request accessibility permission
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      debugPrint(
        '❌ [PERMISSION] Error requesting accessibility permission: $e',
      );
    }
  }

  /// Start the blocking service
  Future<bool> startBlockingService() async {
    try {
      final bool? success = await _channel.invokeMethod('startBlockingService');
      if (success == true) {
      }
      return success ?? false;
    } catch (e) {
      debugPrint('❌ [PERMISSION] Error starting blocking service: $e');
      return false;
    }
  }

  /// Stop the blocking service
  Future<bool> stopBlockingService() async {
    try {
      final bool? success = await _channel.invokeMethod('stopBlockingService');
      if (success == true) {
      }
      return success ?? false;
    } catch (e) {
      debugPrint('❌ [PERMISSION] Error stopping blocking service: $e');
      return false;
    }
  }

  /// Check all required permissions for app blocking
  Future<PermissionStatus> checkAllPermissions() async {
    final hasOverlay = await hasOverlayPermission();
    final hasAccessibility = await hasAccessibilityPermission();

    return PermissionStatus(
      hasOverlayPermission: hasOverlay,
      hasAccessibilityPermission: hasAccessibility,
    );
  }

  /// Request all required permissions
  Future<void> requestAllPermissions() async {
    if (!await hasOverlayPermission()) {
      await requestOverlayPermission();
    }

    // Request accessibility permission
    await requestAccessibilityPermission();
  }

  /// Show permission setup guide
  String getPermissionSetupGuide() {
    return '''
To enable app blocking, you need to grant these permissions:

1. 📱 Display over other apps
   - Allows showing block screens over blocked apps
   - Will open Settings automatically

2. ♿ Accessibility Service  
   - Allows detecting when apps are opened
   - Go to Settings > Accessibility > Brainrot
   - Turn on the service

3. 🔋 Battery Optimization (Optional)
   - Prevents Android from stopping the blocking service
   - Go to Settings > Battery > Battery Optimization
   - Find Brainrot and select "Don't optimize"

After granting permissions, the app blocking will work automatically!
''';
  }
}

class PermissionStatus {
  final bool hasOverlayPermission;
  final bool hasAccessibilityPermission;

  const PermissionStatus({
    required this.hasOverlayPermission,
    required this.hasAccessibilityPermission,
  });

  bool get allPermissionsGranted =>
      hasOverlayPermission && hasAccessibilityPermission;

  List<String> get missingPermissions {
    final missing = <String>[];
    if (!hasOverlayPermission) missing.add('Display over other apps');
    if (!hasAccessibilityPermission) missing.add('Accessibility Service');
    return missing;
  }
}
