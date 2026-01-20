import 'package:hive/hive.dart';

part 'daily_mood.g.dart';

@HiveType(typeId: 2)
class DailyMood extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double score; // 0-100 productivity/mood score

  @HiveField(2)
  String moodImage; // Path to mood image asset

  @HiveField(3)
  DateTime timestamp; // When this mood was recorded

  @HiveField(4)
  String? notes; // Optional notes for the day

  DailyMood({
    required this.date,
    required this.score,
    required this.moodImage,
    required this.timestamp,
    this.notes,
  });

  /// Get mood category based on score
  String get moodCategory {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 30) return 'Fair';
    return 'Poor';
  }

  /// Get mood color based on score
  int get moodColorValue {
    if (score >= 80) return 0xFF4CAF50; // Green
    if (score >= 60) return 0xFF2196F3; // Blue
    if (score >= 30) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Check if this is a productive day (score >= 70)
  bool get isProductiveDay => score >= 70;

  /// Get formatted date string
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get date key for storage/lookup
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Create DailyMood from score (auto-assigns mood image)
  factory DailyMood.fromScore({
    required DateTime date,
    required double score,
    String? notes,
  }) {
    return DailyMood(
      date: DateTime(date.year, date.month, date.day), // Normalize to day only
      score: score.clamp(0.0, 100.0),
      moodImage: _getMoodImageFromScore(score),
      timestamp: DateTime.now(),
      notes: notes,
    );
  }

  /// Get mood image path based on score
  static String _getMoodImageFromScore(double score) {
    if (score >= 80) return 'assets/images/vui.png'; // 100-80: Happy
    if (score >= 60) return 'assets/images/suynghi.png'; // 79-60: Thoughtful
    if (score >= 30) return 'assets/images/cangthang.png'; // 59-30: Stressed
    return 'assets/images/buonngu.png'; // 29-0: Tired/Sad
  }

  /// Update mood score and image
  void updateScore(double newScore) {
    score = newScore.clamp(0.0, 100.0);
    moodImage = _getMoodImageFromScore(score);
    timestamp = DateTime.now();
  }

  @override
  String toString() {
    return 'DailyMood(date: $formattedDate, score: $score, category: $moodCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyMood && other.dateKey == dateKey;
  }

  @override
  int get hashCode => dateKey.hashCode;
}