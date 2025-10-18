import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailyMoodService {
  static const String _dailyMoodKey = 'daily_mood_states';

  // Singleton pattern
  static final DailyMoodService _instance = DailyMoodService._internal();
  factory DailyMoodService() => _instance;
  DailyMoodService._internal();

  // Save mood state for a specific date
  Future<void> saveDailyMood(DateTime date, double score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _formatDateKey(date);

      // Get existing mood data
      final moodData = await getAllMoodData();

      // Update with new mood
      moodData[dateKey] = {
        'score': score,
        'moodImage': _getMoodImageFromScore(score),
        'timestamp': date.millisecondsSinceEpoch,
      };

      // Save back to preferences
      final jsonString = json.encode(moodData);
      await prefs.setString(_dailyMoodKey, jsonString);

   
    } catch (e) {
    
    }
  }

  // Get mood state for a specific date
  Future<Map<String, dynamic>?> getDailyMood(DateTime date) async {
    try {
      final dateKey = _formatDateKey(date);
      final moodData = await getAllMoodData();
      return moodData[dateKey];
    } catch (e) {

      return null;
    }
  }

  // Get all mood data
  Future<Map<String, dynamic>> getAllMoodData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_dailyMoodKey);

      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return {};
    } catch (e) {
    
      return {};
    }
  }

  // Check if a date has mood data
  Future<bool> hasMoodData(DateTime date) async {
    final mood = await getDailyMood(date);
    return mood != null;
  }

  // Get mood image for a specific date
  Future<String?> getMoodImage(DateTime date) async {
    final mood = await getDailyMood(date);
    return mood?['moodImage'];
  }

  // Get mood score for a specific date
  Future<double?> getMoodScore(DateTime date) async {
    final mood = await getDailyMood(date);
    return mood?['score']?.toDouble();
  }

  // Get monthly statistics
  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    try {
      final moodData = await getAllMoodData();
      final monthKey = '$year-${month.toString().padLeft(2, '0')}';

      double totalScore = 0;
      int daysWithData = 0;
      double minScore = 100;
      double maxScore = 0;

      for (final entry in moodData.entries) {
        if (entry.key.startsWith(monthKey)) {
          final score = entry.value['score']?.toDouble() ?? 0;
          totalScore += score;
          daysWithData++;

          if (score < minScore) minScore = score;
          if (score > maxScore) maxScore = score;
        }
      }

      return {
        'averageScore': daysWithData > 0 ? totalScore / daysWithData : 0,
        'totalDays': daysWithData,
        'minScore': daysWithData > 0 ? minScore : 0,
        'maxScore': daysWithData > 0 ? maxScore : 0,
        'totalScore': totalScore,
      };
    } catch (e) {
      print('Error getting monthly stats: $e');
      return {
        'averageScore': 0,
        'totalDays': 0,
        'minScore': 0,
        'maxScore': 0,
        'totalScore': 0,
      };
    }
  }

  // Clear all mood data (for testing purposes)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyMoodKey);
      print('Cleared all mood data');
    } catch (e) {
      print('Error clearing mood data: $e');
    }
  }

  // Private helper methods
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getMoodImageFromScore(double score) {
    if (score >= 80) return 'assets/images/vui.png'; // 100-80: Vui
    if (score >= 60) return 'assets/images/suynghi.png'; // 79-60: Suy nghĩ
    if (score >= 30) return 'assets/images/cangthang.png'; // 59-30: Căng thẳng
    return 'assets/images/buonngu.png'; // 29-0: Buồn ngủ
  }
}
