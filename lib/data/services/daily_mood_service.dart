import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/daily_mood.dart';

class DailyMoodService {
  static const String _moodBoxName = 'daily_moods';
  
  static final DailyMoodService _instance = DailyMoodService._internal();
  factory DailyMoodService() => _instance;
  DailyMoodService._internal();

  Box<DailyMood>? _moodBox;

  Future<void> initialize() async {
    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DailyMoodAdapter());
      }
      _moodBox = await Hive.openBox<DailyMood>(_moodBoxName);
      await _cleanupOldData();
      
    } catch (e) {
      rethrow;
    }
  }
  Future<void> saveDailyMood(DateTime date, double score, {String? notes, int? totalUsageMinutes}) async {
    try {
      final mood = DailyMood.fromScore(
        date: date,
        score: score,
        notes: notes,
      );
      
      // Add usage time if provided
      if (totalUsageMinutes != null) {
        mood.totalUsageMinutes = totalUsageMinutes;
      }

      await _moodBox!.put(mood.dateKey, mood);
    } catch (e) {
    }
  }

  Future<DailyMood?> getDailyMood(DateTime date) async {
    try {
      final dateKey = _formatDateKey(date);
      return _moodBox!.get(dateKey);
    } catch (e) {
      return null;
    }
  }

  /// Get all mood data
  Future<List<DailyMood>> getAllMoodData() async {
    try {
      return _moodBox!.values.toList();
    } catch (e) {
      debugPrint('❌ [MOOD] Error getting all mood data: $e');
      return [];
    }
  }

  /// Check if a date has mood data
  Future<bool> hasMoodData(DateTime date) async {
    final mood = await getDailyMood(date);
    return mood != null;
  }

  /// Get mood image for a specific date
  Future<String?> getMoodImage(DateTime date) async {
    final mood = await getDailyMood(date);
    return mood?.moodImage;
  }

  /// Get mood score for a specific date
  Future<double?> getMoodScore(DateTime date) async {
    final mood = await getDailyMood(date);
    return mood?.score;
  }

  /// Get moods for a specific date range
  Future<List<DailyMood>> getMoodsInRange(DateTime startDate, DateTime endDate) async {
    try {
      final allMoods = await getAllMoodData();
      
      return allMoods.where((mood) {
        return mood.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
               mood.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('❌ [MOOD] Error getting moods in range: $e');
      return [];
    }
  }

  /// Get monthly statistics
  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      
      final monthMoods = await getMoodsInRange(startDate, endDate);

      if (monthMoods.isEmpty) {
        return {
          'averageScore': 0.0,
          'totalDays': 0,
          'minScore': 0.0,
          'maxScore': 0.0,
          'totalScore': 0.0,
          'productiveDays': 0,
          'moodDistribution': <String, int>{},
        };
      }

      double totalScore = 0;
      double minScore = 100;
      double maxScore = 0;
      int productiveDays = 0;
      Map<String, int> moodDistribution = {
        'Excellent': 0,
        'Good': 0,
        'Fair': 0,
        'Poor': 0,
      };

      for (final mood in monthMoods) {
        totalScore += mood.score;
        if (mood.score < minScore) minScore = mood.score;
        if (mood.score > maxScore) maxScore = mood.score;
        if (mood.isProductiveDay) productiveDays++;
        
        moodDistribution[mood.moodCategory] = 
            (moodDistribution[mood.moodCategory] ?? 0) + 1;
      }

      return {
        'averageScore': totalScore / monthMoods.length,
        'totalDays': monthMoods.length,
        'minScore': minScore,
        'maxScore': maxScore,
        'totalScore': totalScore,
        'productiveDays': productiveDays,
        'moodDistribution': moodDistribution,
      };
    } catch (e) {
      debugPrint('❌ [MOOD] Error getting monthly stats: $e');
      return {
        'averageScore': 0.0,
        'totalDays': 0,
        'minScore': 0.0,
        'maxScore': 0.0,
        'totalScore': 0.0,
        'productiveDays': 0,
        'moodDistribution': <String, int>{},
      };
    }
  }

  /// Get yearly statistics
  Future<Map<String, dynamic>> getYearlyStats(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);
      
      final yearMoods = await getMoodsInRange(startDate, endDate);

      if (yearMoods.isEmpty) {
        return {
          'averageScore': 0.0,
          'totalDays': 0,
          'bestMonth': 'None',
          'worstMonth': 'None',
          'totalProductiveDays': 0,
          'monthlyAverages': <int, double>{},
        };
      }

      // Calculate monthly averages
      Map<int, List<double>> monthlyScores = {};
      int totalProductiveDays = 0;

      for (final mood in yearMoods) {
        final month = mood.date.month;
        monthlyScores[month] = (monthlyScores[month] ?? [])..add(mood.score);
        if (mood.isProductiveDay) totalProductiveDays++;
      }

      Map<int, double> monthlyAverages = {};
      double bestAverage = 0;
      double worstAverage = 100;
      int bestMonth = 1;
      int worstMonth = 1;

      for (final entry in monthlyScores.entries) {
        final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
        monthlyAverages[entry.key] = average;
        
        if (average > bestAverage) {
          bestAverage = average;
          bestMonth = entry.key;
        }
        if (average < worstAverage) {
          worstAverage = average;
          worstMonth = entry.key;
        }
      }

      const monthNames = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      final totalScore = yearMoods.fold(0.0, (sum, mood) => sum + mood.score);

      return {
        'averageScore': totalScore / yearMoods.length,
        'totalDays': yearMoods.length,
        'bestMonth': monthNames[bestMonth],
        'worstMonth': monthNames[worstMonth],
        'totalProductiveDays': totalProductiveDays,
        'monthlyAverages': monthlyAverages,
      };
    } catch (e) {
      debugPrint('❌ [MOOD] Error getting yearly stats: $e');
      return {
        'averageScore': 0.0,
        'totalDays': 0,
        'bestMonth': 'None',
        'worstMonth': 'None',
        'totalProductiveDays': 0,
        'monthlyAverages': <int, double>{},
      };
    }
  }

  /// Get recent moods (last N days)
  Future<List<DailyMood>> getRecentMoods(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      return await getMoodsInRange(startDate, endDate);
    } catch (e) {
      debugPrint('❌ [MOOD] Error getting recent moods: $e');
      return [];
    }
  }

  /// Update existing mood
  Future<void> updateDailyMood(DateTime date, double newScore, {String? notes}) async {
    try {
      final dateKey = _formatDateKey(date);
      final existingMood = _moodBox!.get(dateKey);
      
      if (existingMood != null) {
        existingMood.updateScore(newScore);
        if (notes != null) existingMood.notes = notes;
        await existingMood.save();
      } else {
        await saveDailyMood(date, newScore, notes: notes);
      }
    } catch (e) {
      debugPrint('❌ [MOOD] Error updating mood: $e');
    }
  }

  Future<void> deleteDailyMood(DateTime date) async {
    try {
      final dateKey = _formatDateKey(date);
      await _moodBox!.delete(dateKey);

    } catch (e) {
      debugPrint('❌ [MOOD] Error deleting mood: $e');
    }
  }

  /// Clear all mood data (for testing purposes)
  Future<void> clearAllData() async {
    try {
      await _moodBox!.clear();
    } catch (e) {
      debugPrint('❌ [MOOD] Error clearing mood data: $e');
    }
  }

  /// Clean up old data (keep last 365 days)
  Future<void> _cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 365));
      final keysToDelete = <String>[];
      
      for (final mood in _moodBox!.values) {
        if (mood.date.isBefore(cutoffDate)) {
          keysToDelete.add(mood.dateKey);
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        await _moodBox!.deleteAll(keysToDelete);
      }
    } catch (e) {
      debugPrint('❌ [MOOD] Error cleaning up old data: $e');
    }
  }

  /// Export mood data as JSON
  Future<Map<String, dynamic>> exportData() async {
    try {
      final allMoods = await getAllMoodData();
      
      final exportData = allMoods.map((mood) => {
        'date': mood.date.toIso8601String(),
        'score': mood.score,
        'moodImage': mood.moodImage,
        'moodCategory': mood.moodCategory,
        'timestamp': mood.timestamp.toIso8601String(),
        'notes': mood.notes,
      }).toList();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'totalRecords': exportData.length,
        'moods': exportData,
      };
    } catch (e) {
      debugPrint('❌ [MOOD] Error exporting data: $e');
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'totalRecords': 0,
        'moods': [],
      };
    }
  }
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
  }
}
