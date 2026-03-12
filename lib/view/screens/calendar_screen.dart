import 'package:flutter/material.dart';
import '../../data/services/daily_mood_service.dart';
import '../../generated/l10n.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  late PageController _pageController;
  final DailyMoodService _moodService = DailyMoodService();
  Map<String, dynamic> monthlyStats = {};
  Map<String, String> dailyMoods = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: DateTime.now().month - 1);
    _loadMonthData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: Text(
          "Calendar",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month - 1,
                          );
                        });
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _loadMonthData();
                      },
                      icon: const Icon(Icons.chevron_left, size: 30),
                    ),
                    Text(
                      _getMonthYear(selectedDate),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month + 1,
                          );
                        });
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _loadMonthData();
                      },
                      icon: const Icon(Icons.chevron_right, size: 30),
                    ),
                  ],
                ),
              ),
              Container(
                height: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Day headers
                    Row(
                      children: [
                        "Sun",
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
                      ]
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),

                    // Calendar days
                    Expanded(child: _buildCalendarGrid()),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'monthly rot summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              Icons.bar_chart,
                              'total rot',
                              _formatDuration(
                                monthlyStats['totalScore']?.toDouble() ?? 0,
                              ),
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              Icons.access_time,
                              'average daily r...',
                              _formatDuration(
                                monthlyStats['averageScore']?.toDouble() ?? 0,
                              ),
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink(); // Empty cell - use const
        }

        return RepaintBoundary(
          child: _CalendarDayCell(
            dayNumber: dayNumber,
            selectedDate: selectedDate,
            dailyMoods: dailyMoods,
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Load mood data for the current month
  Future<void> _loadMonthData() async {
    try {
      // Load monthly statistics
      monthlyStats = await _moodService.getMonthlyStats(
        selectedDate.year,
        selectedDate.month,
      );

      // Load daily moods for the month
      final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      Map<String, String> monthMoods = {};

      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final moodImage = await _moodService.getMoodImage(date);

        if (moodImage != null) {
          monthMoods[_formatDateKey(date)] = moodImage;
        }
      }

      if (mounted) {
        setState(() {
          dailyMoods = monthMoods;
        });
      }
    } catch (e) {
      print('Error loading month data: $e');
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(double score) {

    if (score == 0) return '0m';

    final hours = ((100 - score) / 10).floor();
    final minutes = (((100 - score) / 10) % 1 * 60).round();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return months[date.month - 1];
  }
}

// Separate widget for calendar day cell - optimize rebuilds
class _CalendarDayCell extends StatelessWidget {
  final int dayNumber;
  final DateTime selectedDate;
  final Map<String, String> dailyMoods;

  const _CalendarDayCell({
    required this.dayNumber,
    required this.selectedDate,
    required this.dailyMoods,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = dayNumber == now.day &&
        selectedDate.month == now.month &&
        selectedDate.year == now.year;

    final dayDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      dayNumber,
    );
    final moodImage = dailyMoods[_formatDateKey(dayDate)];
    final hasActivity = moodImage != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number
          Text(
            dayNumber.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.orange : Colors.black,
              fontSize: 13,
            ),
          ),
          // Mood icon
          if (hasActivity) ...[
            const SizedBox(height: 2),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  moodImage,
                  fit: BoxFit.cover,
                  cacheWidth: 60, // Cache smaller size for performance
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.sentiment_neutral,
                      color: Colors.grey,
                      size: 20,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
