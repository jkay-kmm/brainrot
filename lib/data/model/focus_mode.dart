import 'package:flutter/material.dart';

enum FocusModeType {
  work,
  study,
  sleep,
  family,
  exercise,
  custom,
}

class FocusMode {
  final String id;
  final String name;
  final String description;
  final FocusModeType type;
  final Color color;
  final IconData icon;
  final List<String> allowedPackages;
  final List<String> blockedPackages;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;
  final bool allowNotifications;
  final bool allowCalls;
  final bool allowEmergency;
  final String? customMessage;

  const FocusMode({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.color,
    required this.icon,
    this.allowedPackages = const [],
    this.blockedPackages = const [],
    this.isActive = false,
    this.startTime,
    this.endTime,
    this.duration,
    this.allowNotifications = false,
    this.allowCalls = true,
    this.allowEmergency = true,
    this.customMessage,
  });

  // Predefined focus modes
  static const List<FocusMode> predefinedModes = [
    FocusMode(
      id: 'work',
      name: 'Work Focus',
      description: 'Block distracting apps during work hours',
      type: FocusModeType.work,
      color: Colors.blue,
      icon: Icons.work,
      blockedPackages: [
        'com.instagram.android',
        'com.facebook.katana',
        'com.twitter.android',
        'com.tiktok',
        'com.snapchat.android',
      ],
    ),
    FocusMode(
      id: 'study',
      name: 'Study Mode',
      description: 'Focus on learning without distractions',
      type: FocusModeType.study,
      color: Colors.green,
      icon: Icons.school,
      allowedPackages: [
        'com.google.android.apps.docs.editors.docs',
        'com.microsoft.office.word',
        'com.adobe.reader',
      ],
    ),
    FocusMode(
      id: 'sleep',
      name: 'Sleep Time',
      description: 'Wind down for better sleep',
      type: FocusModeType.sleep,
      color: Colors.indigo,
      icon: Icons.bedtime,
      allowedPackages: [
        'com.android.phone',
        'com.android.contacts',
      ],
      allowNotifications: false,
    ),
    FocusMode(
      id: 'family',
      name: 'Family Time',
      description: 'Spend quality time with family',
      type: FocusModeType.family,
      color: Colors.pink,
      icon: Icons.family_restroom,
      allowedPackages: [
        'com.android.camera2',
        'com.google.android.apps.photos',
      ],
    ),
    FocusMode(
      id: 'exercise',
      name: 'Workout',
      description: 'Stay focused during exercise',
      type: FocusModeType.exercise,
      color: Colors.orange,
      icon: Icons.fitness_center,
      allowedPackages: [
        'com.spotify.music',
        'com.google.android.music',
        'com.strava',
        'com.nike.plusone',
      ],
    ),
  ];

  // Copy with method
  FocusMode copyWith({
    String? id,
    String? name,
    String? description,
    FocusModeType? type,
    Color? color,
    IconData? icon,
    List<String>? allowedPackages,
    List<String>? blockedPackages,
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    bool? allowNotifications,
    bool? allowCalls,
    bool? allowEmergency,
    String? customMessage,
  }) {
    return FocusMode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      allowedPackages: allowedPackages ?? this.allowedPackages,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      allowNotifications: allowNotifications ?? this.allowNotifications,
      allowCalls: allowCalls ?? this.allowCalls,
      allowEmergency: allowEmergency ?? this.allowEmergency,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  // Helper methods
  bool shouldBlockPackage(String packageName) {
    if (!isActive) return false;
    
    // If there are allowed packages, only allow those
    if (allowedPackages.isNotEmpty) {
      return !allowedPackages.contains(packageName);
    }
    
    // Otherwise, block packages in the blocked list
    return blockedPackages.contains(packageName);
  }

  Duration? get remainingTime {
    if (endTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endTime!)) return null;
    return endTime!.difference(now);
  }

  String get formattedRemainingTime {
    final remaining = remainingTime;
    if (remaining == null) return 'No time limit';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    }
    return '${minutes}m remaining';
  }

  String get statusText {
    if (!isActive) return 'Inactive';
    if (remainingTime == null) return 'Active';
    return formattedRemainingTime;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'color': color.value,
      'icon': icon.codePoint,
      'allowedPackages': allowedPackages,
      'blockedPackages': blockedPackages,
      'isActive': isActive,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'allowNotifications': allowNotifications,
      'allowCalls': allowCalls,
      'allowEmergency': allowEmergency,
      'customMessage': customMessage,
    };
  }

  factory FocusMode.fromJson(Map<String, dynamic> json) {
    return FocusMode(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: FocusModeType.values.firstWhere((e) => e.name == json['type']),
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      allowedPackages: List<String>.from(json['allowedPackages'] ?? []),
      blockedPackages: List<String>.from(json['blockedPackages'] ?? []),
      isActive: json['isActive'] ?? false,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'] != null ? Duration(milliseconds: json['duration']) : null,
      allowNotifications: json['allowNotifications'] ?? false,
      allowCalls: json['allowCalls'] ?? true,
      allowEmergency: json['allowEmergency'] ?? true,
      customMessage: json['customMessage'],
    );
  }
}

