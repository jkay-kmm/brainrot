import 'package:flutter/material.dart';

enum AppBlockStatus {
  allowed,      // Được phép sử dụng
  blocked,      // Bị chặn hoàn toàn
  limited,      // Bị giới hạn thời gian
  warning,      // Đang trong trạng thái cảnh báo
}

class AppBlockInfo {
  final String packageName;
  final String appName;
  final AppBlockStatus status;
  final Duration? dailyUsage;
  final Duration? dailyLimit;
  final Duration? sessionUsage;
  final Duration? sessionLimit;
  final List<String> activeRuleIds;
  final DateTime? lastUsed;
  final DateTime? blockedUntil;
  final String? blockReason;
  final bool canBypass;

  const AppBlockInfo({
    required this.packageName,
    required this.appName,
    required this.status,
    this.dailyUsage,
    this.dailyLimit,
    this.sessionUsage,
    this.sessionLimit,
    this.activeRuleIds = const [],
    this.lastUsed,
    this.blockedUntil,
    this.blockReason,
    this.canBypass = false,
  });

  // Copy with method
  AppBlockInfo copyWith({
    String? packageName,
    String? appName,
    AppBlockStatus? status,
    Duration? dailyUsage,
    Duration? dailyLimit,
    Duration? sessionUsage,
    Duration? sessionLimit,
    List<String>? activeRuleIds,
    DateTime? lastUsed,
    DateTime? blockedUntil,
    String? blockReason,
    bool? canBypass,
  }) {
    return AppBlockInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      status: status ?? this.status,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      sessionUsage: sessionUsage ?? this.sessionUsage,
      sessionLimit: sessionLimit ?? this.sessionLimit,
      activeRuleIds: activeRuleIds ?? this.activeRuleIds,
      lastUsed: lastUsed ?? this.lastUsed,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      blockReason: blockReason ?? this.blockReason,
      canBypass: canBypass ?? this.canBypass,
    );
  }

  // Helper methods
  bool get isBlocked => status == AppBlockStatus.blocked;
  bool get isLimited => status == AppBlockStatus.limited;
  bool get isWarning => status == AppBlockStatus.warning;
  bool get isAllowed => status == AppBlockStatus.allowed;

  Duration? get remainingDailyTime {
    if (dailyLimit == null || dailyUsage == null) return null;
    final remaining = dailyLimit! - dailyUsage!;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration? get remainingSessionTime {
    if (sessionLimit == null || sessionUsage == null) return null;
    final remaining = sessionLimit! - sessionUsage!;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double? get dailyUsagePercentage {
    if (dailyLimit == null || dailyUsage == null) return null;
    return (dailyUsage!.inMilliseconds / dailyLimit!.inMilliseconds).clamp(0.0, 1.0);
  }

  double? get sessionUsagePercentage {
    if (sessionLimit == null || sessionUsage == null) return null;
    return (sessionUsage!.inMilliseconds / sessionLimit!.inMilliseconds).clamp(0.0, 1.0);
  }

  Color get statusColor {
    switch (status) {
      case AppBlockStatus.allowed:
        return Colors.green;
      case AppBlockStatus.blocked:
        return Colors.red;
      case AppBlockStatus.limited:
        return Colors.orange;
      case AppBlockStatus.warning:
        return Colors.yellow;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AppBlockStatus.allowed:
        return Icons.check_circle;
      case AppBlockStatus.blocked:
        return Icons.block;
      case AppBlockStatus.limited:
        return Icons.access_time;
      case AppBlockStatus.warning:
        return Icons.warning;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case AppBlockStatus.allowed:
        return 'Allowed';
      case AppBlockStatus.blocked:
        return 'Blocked';
      case AppBlockStatus.limited:
        return 'Limited';
      case AppBlockStatus.warning:
        return 'Warning';
    }
  }

  String get formattedDailyUsage {
    if (dailyUsage == null) return '0m';
    final hours = dailyUsage!.inHours;
    final minutes = dailyUsage!.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedDailyLimit {
    if (dailyLimit == null) return 'No limit';
    final hours = dailyLimit!.inHours;
    final minutes = dailyLimit!.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedRemainingTime {
    final remaining = remainingDailyTime;
    if (remaining == null) return 'No limit';
    if (remaining == Duration.zero) return 'Time up';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    }
    return '${minutes}m left';
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'status': status.name,
      'dailyUsage': dailyUsage?.inMilliseconds,
      'dailyLimit': dailyLimit?.inMilliseconds,
      'sessionUsage': sessionUsage?.inMilliseconds,
      'sessionLimit': sessionLimit?.inMilliseconds,
      'activeRuleIds': activeRuleIds,
      'lastUsed': lastUsed?.toIso8601String(),
      'blockedUntil': blockedUntil?.toIso8601String(),
      'blockReason': blockReason,
      'canBypass': canBypass,
    };
  }

  factory AppBlockInfo.fromJson(Map<String, dynamic> json) {
    return AppBlockInfo(
      packageName: json['packageName'],
      appName: json['appName'],
      status: AppBlockStatus.values.firstWhere((e) => e.name == json['status']),
      dailyUsage: json['dailyUsage'] != null ? Duration(milliseconds: json['dailyUsage']) : null,
      dailyLimit: json['dailyLimit'] != null ? Duration(milliseconds: json['dailyLimit']) : null,
      sessionUsage: json['sessionUsage'] != null ? Duration(milliseconds: json['sessionUsage']) : null,
      sessionLimit: json['sessionLimit'] != null ? Duration(milliseconds: json['sessionLimit']) : null,
      activeRuleIds: List<String>.from(json['activeRuleIds'] ?? []),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      blockedUntil: json['blockedUntil'] != null ? DateTime.parse(json['blockedUntil']) : null,
      blockReason: json['blockReason'],
      canBypass: json['canBypass'] ?? false,
    );
  }
}

