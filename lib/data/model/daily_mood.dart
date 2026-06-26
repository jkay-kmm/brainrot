import 'package:hive/hive.dart';

part 'daily_mood.g.dart';

@HiveType(typeId: 2)
class DailyMood extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double score;

  @HiveField(2)
  String moodImage;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  int? totalUsageMinutes;

  DailyMood({
    required this.date,
    required this.score,
    required this.moodImage,
    required this.timestamp,
    this.notes,
    this.totalUsageMinutes,
  });

  String get moodCategory {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 30) return 'Fair';
    return 'Poor';
  }

  int get moodColorValue {
    if (score >= 80) return 0xFF4CAF50;
    if (score >= 60) return 0xFF2196F3;
    if (score >= 30) return 0xFFFF9800;
    return 0xFFF44336;
  }

  bool get isProductiveDay => score >= 70;

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  factory DailyMood.fromScore({
    required DateTime date,
    required double score,
    String? notes,
  }) {
    return DailyMood(
      date: DateTime(date.year, date.month, date.day),
      score: score.clamp(0.0, 100.0),
      moodImage: _getMoodImageFromScore(score),
      timestamp: DateTime.now(),
      notes: notes,
    );
  }

  static String _getMoodImageFromScore(double score) {
    if (score >= 80) return 'assets/images/vui.png';
    if (score >= 60) return 'assets/images/suynghi.png';
    if (score >= 30) return 'assets/images/cangthang.png';
    return 'assets/images/buonngu.png';
  }

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