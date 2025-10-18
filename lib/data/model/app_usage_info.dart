import 'dart:typed_data';

class AppUsageInfo {
  final String packageName;
  final String appName;
  final Duration usage;
  final DateTime startTime;
  final DateTime endTime;
  final Uint8List? iconBytes; // Thêm field icon

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.usage,
    required this.startTime,
    required this.endTime,
    this.iconBytes, // Optional icon bytes
  });

  // Format duration to readable string
  String get formattedUsage {
    final hours = usage.inHours;
    final minutes = usage.inMinutes.remainder(60);
    final seconds = usage.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get usage percentage relative to total usage
  double getUsagePercentage(Duration totalUsage) {
    if (totalUsage.inMilliseconds == 0) return 0.0;
    return (usage.inMilliseconds / totalUsage.inMilliseconds) * 100;
  }

  @override
  String toString() {
    return 'AppUsageInfo(packageName: $packageName, appName: $appName, usage: $formattedUsage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUsageInfo &&
        other.packageName == packageName &&
        other.appName == appName &&
        other.usage == usage;
  }

  @override
  int get hashCode {
    return packageName.hashCode ^ appName.hashCode ^ usage.hashCode;
  }

  /// Copy method để update icon hoặc other fields
  AppUsageInfo copyWith({
    String? packageName,
    String? appName,
    Duration? usage,
    DateTime? startTime,
    DateTime? endTime,
    Uint8List? iconBytes,
  }) {
    return AppUsageInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      usage: usage ?? this.usage,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      iconBytes: iconBytes ?? this.iconBytes,
    );
  }

  /// Check if app has icon
  bool get hasIcon => iconBytes != null;
}
