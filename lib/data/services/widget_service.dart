import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();
  // update data
  Future<void> updateWidget({
    required Duration todayUsage,
    required Duration goal,
    required double score,
  }) async {
    try {
      final todayFormatted = _formatDuration(todayUsage);
      final goalFormatted = _formatDuration(goal);
      final moodImage = _getMoodImage(score);

      await HomeWidget.saveWidgetData<String>(
        'widget_today_usage',
        todayFormatted,
      );

      await HomeWidget.saveWidgetData<String>(
        'widget_goal',
        goalFormatted,
      );

      await HomeWidget.saveWidgetData<int>(
        'widget_score',
        score.toInt(),
      );

      await HomeWidget.saveWidgetData<String>(
        'widget_mood_image',
        moodImage,
      );

      await HomeWidget.updateWidget(
        androidName: 'UsageWidgetProvider',
        iOSName: 'UsageWidget',
        qualifiedAndroidName: 'com.example.brainrot.UsageWidgetProvider',
      );


    } catch (e) {
      debugPrint('Error');
    }
  }
  // cac icon trang thai
  String _getMoodImage(double score) {
    if (score >= 80) return 'vui';
    if (score >= 60) return 'suynghi';
    if (score >= 30) return 'cangthang';
    return 'buonngu';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }


  Future<void> registerBackgroundCallback() async {
    try {
      await HomeWidget.setAppGroupId('com.example.brainrot.widget');

    } catch (e) {
      debugPrint(' Error: $e');
    }
  }

  // Check if widget
  Future<bool> isWidgetAvailable() async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}
