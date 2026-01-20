import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/services/usage_history_service.dart';
import 'data/services/daily_mood_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize services
  final historyService = UsageHistoryService();
  await historyService.initialize();
  
  final moodService = DailyMoodService();
  await moodService.initialize();
  
  runApp(const BrainrotApp());
}
