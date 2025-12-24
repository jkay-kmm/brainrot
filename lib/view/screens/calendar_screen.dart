import 'package:flutter/material.dart';
import '../../data/services/daily_mood_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: const Text(
          'brainrot calendar',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.help_outline),
        //     onPressed: () => _showHelpDialog(context),
        //   ),
        // ],
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
              // Month navigation
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

              // Calendar grid - Thay Expanded bằng Container với height cố định
              Container(
                height: 400, // Đặt chiều cao cố định cho calendar grid
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Day headers
                    Row(
                      children:
                          ['s', 'm', 't', 'w', 'r', 'f', 's']
                              .map(
                                (day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
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

              // Monthly summary
              Padding(
                padding: const EdgeInsets.all(20),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.6, // Làm ô dài hơn theo chiều dọc
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Container(); // Empty cell
        }

        final isToday =
            dayNumber == DateTime.now().day &&
            selectedDate.month == DateTime.now().month &&
            selectedDate.year == DateTime.now().year;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Số ngày
                    Flexible(
                      flex: 1,
                      child: FittedBox(
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.orange : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    // Icon mood bên trong ô
                    if (hasActivity)
                      Flexible(
                        flex: 2,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.7,
                            maxHeight: constraints.maxHeight * 0.6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.asset(
                                moodImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const FittedBox(
                                    child: Icon(
                                      Icons.sentiment_neutral,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!hasActivity)
                      Flexible(
                        flex: 2,
                        child: Container(), // Empty placeholder
                      ),
                  ],
                ),
              );
            },
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

      setState(() {
        dailyMoods = monthMoods;
      });
    } catch (e) {
      print('Error loading month data: $e');
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(double score) {
    // Convert score back to approximate usage time for display
    // This is a rough estimate for display purposes
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Calendar Help'),
            content: const Text(
              'This calendar shows your daily brain rot activity. '
              'Days with activity are marked with mood indicators. '
              'The monthly summary shows your total and average usage.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }
}
