import 'package:flutter/material.dart';

enum BlockingType {
  timeLimit,     // Giới hạn thời gian
  schedule,      // Chặn theo lịch trình
  allDayBlock,   // Chặn cả ngày
  focusMode,     // Chế độ tập trung
}

enum RuleStatus {
  active,
  inactive,
  paused,
}

class BlockingRule {
  final String id;
  final String name;
  final String description;
  final BlockingType type;
  final List<String> targetPackages; // Danh sách package names
  final RuleStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Time limit specific
  final Duration? dailyLimit;
  final Duration? sessionLimit;
  
  // Schedule specific
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<int>? daysOfWeek; // 1-7 (Monday-Sunday)
  
  // Focus mode specific
  final String? focusModeId;
  
  // Settings
  final bool allowEmergencyBypass;
  final String? customBlockMessage;
  final bool showUsageWarning;
  final Duration? warningThreshold;

  const BlockingRule({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetPackages,
    this.status = RuleStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.dailyLimit,
    this.sessionLimit,
    this.startTime,
    this.endTime,
    this.daysOfWeek,
    this.focusModeId,
    this.allowEmergencyBypass = false,
    this.customBlockMessage,
    this.showUsageWarning = true,
    this.warningThreshold,
  });

  // Copy with method
  BlockingRule copyWith({
    String? id,
    String? name,
    String? description,
    BlockingType? type,
    List<String>? targetPackages,
    RuleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? dailyLimit,
    Duration? sessionLimit,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    String? focusModeId,
    bool? allowEmergencyBypass,
    String? customBlockMessage,
    bool? showUsageWarning,
    Duration? warningThreshold,
  }) {
    return BlockingRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetPackages: targetPackages ?? this.targetPackages,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      sessionLimit: sessionLimit ?? this.sessionLimit,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      focusModeId: focusModeId ?? this.focusModeId,
      allowEmergencyBypass: allowEmergencyBypass ?? this.allowEmergencyBypass,
      customBlockMessage: customBlockMessage ?? this.customBlockMessage,
      showUsageWarning: showUsageWarning ?? this.showUsageWarning,
      warningThreshold: warningThreshold ?? this.warningThreshold,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'targetPackages': targetPackages,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'dailyLimit': dailyLimit?.inMilliseconds,
      'sessionLimit': sessionLimit?.inMilliseconds,
      'startTime': startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'daysOfWeek': daysOfWeek,
      'focusModeId': focusModeId,
      'allowEmergencyBypass': allowEmergencyBypass,
      'customBlockMessage': customBlockMessage,
      'showUsageWarning': showUsageWarning,
      'warningThreshold': warningThreshold?.inMilliseconds,
    };
  }

  factory BlockingRule.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return BlockingRule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: BlockingType.values.firstWhere((e) => e.name == json['type']),
      targetPackages: List<String>.from(json['targetPackages']),
      status: RuleStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      dailyLimit: json['dailyLimit'] != null ? Duration(milliseconds: json['dailyLimit']) : null,
      sessionLimit: json['sessionLimit'] != null ? Duration(milliseconds: json['sessionLimit']) : null,
      startTime: parseTimeOfDay(json['startTime']),
      endTime: parseTimeOfDay(json['endTime']),
      daysOfWeek: json['daysOfWeek'] != null ? List<int>.from(json['daysOfWeek']) : null,
      focusModeId: json['focusModeId'],
      allowEmergencyBypass: json['allowEmergencyBypass'] ?? false,
      customBlockMessage: json['customBlockMessage'],
      showUsageWarning: json['showUsageWarning'] ?? true,
      warningThreshold: json['warningThreshold'] != null ? Duration(milliseconds: json['warningThreshold']) : null,
    );
  }

  // Helper methods
  bool get isActive => status == RuleStatus.active;
  
  bool isApplicableToday() {
    if (daysOfWeek == null || daysOfWeek!.isEmpty) return true;
    final today = DateTime.now().weekday;
    return daysOfWeek!.contains(today);
  }

  bool isInScheduledTime() {
    if (startTime == null || endTime == null) return true;
    
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    
    if (startMinutes <= endMinutes) {
      // Same day schedule (e.g., 9:00 - 17:00)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Overnight schedule (e.g., 22:00 - 06:00)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  bool shouldBlockPackage(String packageName) {
    if (!isActive) return false;
    if (!targetPackages.contains(packageName)) return false;
    if (!isApplicableToday()) return false;
    
    switch (type) {
      case BlockingType.schedule:
        return isInScheduledTime();
      case BlockingType.allDayBlock:
        return true;
      case BlockingType.timeLimit:
      case BlockingType.focusMode:
        // These need additional logic in the service
        return true;
    }
  }

  String get displayIcon {
    switch (type) {
      case BlockingType.timeLimit:
        return '⏰';
      case BlockingType.schedule:
        return '📅';
      case BlockingType.allDayBlock:
        return '🌙';
      case BlockingType.focusMode:
        return '🎯';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case BlockingType.timeLimit:
        return 'Time Limits';
      case BlockingType.schedule:
        return 'Schedules';
      case BlockingType.allDayBlock:
        return 'All Day Blocks';
      case BlockingType.focusMode:
        return 'Focus Mode';
    }
  }
}
