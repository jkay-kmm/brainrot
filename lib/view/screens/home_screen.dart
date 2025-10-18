import 'package:brainrot/widgets/calendar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../view_model/app_view_model.dart';
import '../../view_model/home_view_model.dart';
import '../../data/model/app_usage_info.dart';
import '../../core/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeViewModel homeViewModel;

  @override
  void initState() {
    super.initState();
    homeViewModel = HomeViewModel();
    // Load today's usage data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeViewModel.loadTodayUsage();
    });
  }

  @override
  void dispose() {
    homeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: homeViewModel,
      child: Scaffold(
        backgroundColor: Color(0xFFFFE4B5),
        appBar: AppBar(
          toolbarHeight: 0,
          title: const Text(
            'brainrot',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Today Calendar Button
            TextButton.icon(
              onPressed: () => _showTodayCalendar(context),
              icon: const Icon(
                Icons.calendar_today,
                color: Colors.black,
                size: 20,
              ),
              label: const Text(
                'today',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                backgroundColor: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Consumer<HomeViewModel>(
          builder: (context, homeViewModel, child) {
            if (homeViewModel.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading app usage data...'),
                  ],
                ),
              );
            }

            if (homeViewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      homeViewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => homeViewModel.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => homeViewModel.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(context, homeViewModel),
                    // const SizedBox(height: 24),
                    Divider(
                      thickness: 1,
                      color: Colors.black12,
                      indent: 16, // lề trái
                      endIndent: 16, // lề phải
                    ),

                    _buildUsageOverview(context, homeViewModel),
                    // const SizedBox(height: 12),
                    Divider(
                      thickness: 1,
                      color: Colors.black12,
                      indent: 16, // lề trái
                      endIndent: 16, // lề phải
                    ),

                    _buildTopAppsSection(context, homeViewModel),
                    const SizedBox(height: 24),
                    // _buildAllAppsSection(context, homeViewModel),
                  ],
                ),
              ),
            );
          },
        ),
        // floatingActionButton: Consumer<HomeViewModel>(
        //   builder: (context, homeViewModel, child) {
        //     return FloatingActionButton.extended(
        //       onPressed: homeViewModel.isLoading
        //           ? null
        //           : () => _showUsageActions(context, homeViewModel),
        //       icon: const Icon(Icons.analytics),
        //       label: const Text('Actions'),
        //     );
        //   },
        // ),
      ),
    );
  }

  void _showTodayCalendar(BuildContext context) {
    TodayCalendarDialog.show(context, onDateSelected: _onDateSelected);
  }

  void _onDateSelected(DateTime date) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected date: ${_formatSelectedDate(date)}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    return '$dayName, $monthName ${date.day}, ${date.year}';
  }
}

Widget _buildWelcomeSection(BuildContext context, HomeViewModel homeViewModel) {
  return _buildBrainHealthCalculation(context, homeViewModel);
}

Widget _buildBrainHealthCalculation(
  BuildContext context,
  HomeViewModel homeViewModel,
) {
  // Use the calculated score from ViewModel instead of calculating here
  final finalScore = homeViewModel.currentScore;
  final totalMinutes = homeViewModel.totalUsage.inMinutes;
  final goalMinutes = 120; // 2 hours goal

  return Column(
    children: [
      // Mood image instead of brain icon
      Container(
        width: 100,
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.asset(
            _getMoodImage(finalScore),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default brain image if mood image not found
              return ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/vui.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error2, stackTrace2) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 60,
                        color: Colors.brown,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${finalScore.toInt()}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                // color: _getScoreColor(finalScore),
                fontSize: 48,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Progress bar with percentage
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30), // thu hẹp hai bên
        child: LayoutBuilder(
          builder: (context, constraints) {
            final percent = (finalScore.clamp(0, 100)) / 100;
            final barHeight = 4.0;
            final fillWidth =
                constraints.maxWidth * percent; // thay MediaQuery ở đây

            return Container(
              width: double.infinity,
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: fillWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: _getScoreColor(finalScore),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // (tuỳ chọn) % ở giữa
                  // Center(child: Text('${finalScore.toInt()}%', ...)),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      // Health status indicator
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Score resets to 100 every day at midnight',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap:
                () => _showHealthCalculationDetails(
                  context,
                  homeViewModel,
                  totalMinutes,
                  goalMinutes,
                  finalScore,
                ),
            child: const Icon(Icons.help_outline, size: 20, color: Colors.grey),
          ),
        ],
      ),

      // Show reset info
      const SizedBox(height: 16),
    ],
  );
}

// Updated method signature to match the new calculation
void _showHealthCalculationDetails(
  BuildContext context,
  HomeViewModel homeViewModel,
  int totalMinutes,
  int goalMinutes,
  double finalScore,
) {
  // Calculate impacts for display
  double preGoalImpact = 0.0;
  double postGoalImpact = 0.0;

  if (totalMinutes <= goalMinutes) {
    preGoalImpact = (totalMinutes / goalMinutes) * 10.0;
  } else {
    preGoalImpact = 10.0;
    final excessMinutes = totalMinutes - goalMinutes;
    postGoalImpact = (excessMinutes / 60.0) * 20.0;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title with mood image
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _getScoreColor(finalScore).withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        _getMoodImage(finalScore),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/vui.png', // Default fallback image
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error2, stackTrace2) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[200],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.psychology,
                                    size: 30,
                                    color: Colors.brown,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brain Health Calculation',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your brain health score starts at 100 points each day at midnight and decreases based on screen time.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Current status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getScoreColor(finalScore).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getScoreColor(finalScore),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Mood image in the score display
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getScoreColor(
                                      finalScore,
                                    ).withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.asset(
                                  _getMoodImage(finalScore),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.asset(
                                        'assets/images/vui.png', // Default fallback image
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error2,
                                          stackTrace2,
                                        ) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.orange[200],
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                            ),
                                            child: const Icon(
                                              Icons.psychology,
                                              size: 40,
                                              color: Colors.brown,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              'Current Score',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${finalScore.toInt()} / 100',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(finalScore),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Screen time details
                      _buildCalculationRow(
                        'estimated screen time',
                        '${totalMinutes} min (${(totalMinutes / 60).toStringAsFixed(1)} hrs)',
                      ),
                      _buildCalculationRow(
                        'your goal',
                        '$goalMinutes min (${(goalMinutes / 60).toStringAsFixed(1)} hrs)',
                      ),

                      const SizedBox(height: 16),

                      if (totalMinutes <= goalMinutes) ...[
                        _buildCalculationRow(
                          'impact',
                          '${(totalMinutes / 60).toStringAsFixed(1)} hrs * ${(preGoalImpact / (totalMinutes / 60)).toStringAsFixed(1)}/hr',
                          impact: '-${preGoalImpact.toStringAsFixed(1)} points',
                          impactColor: Colors.red,
                        ),
                      ] else ...[
                        _buildCalculationRow(
                          'pre-goal impact',
                          '${(goalMinutes / 60).toStringAsFixed(1)} hrs * 5.0/hr',
                          impact: '-${preGoalImpact.toStringAsFixed(1)} points',
                          impactColor: Colors.red,
                        ),
                        _buildCalculationRow(
                          'post-goal impact',
                          '${((totalMinutes - goalMinutes) / 60).toStringAsFixed(1)} hrs * 20.0/hr',
                          impact:
                              '-${postGoalImpact.toStringAsFixed(1)} points',
                          impactColor: Colors.red,
                        ),
                      ],

                      const Divider(height: 32),
                      _buildCalculationRow(
                        'final score',
                        '100 - total impact',
                        impact: '= ${finalScore.toStringAsFixed(1)} points',
                        impactColor: Colors.green,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildCalculationRow(
  String label,
  String value, {
  String? impact,
  Color? impactColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(color: Colors.grey[600])),
            if (impact != null)
              Text(
                impact,
                style: TextStyle(
                  color: impactColor ?? Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

Color _getScoreColor(double score) {
  if (score >= 80) return Colors.green;
  if (score >= 60) return Colors.orange;
  return Colors.red;
}

Widget _buildUsageOverview(BuildContext context, HomeViewModel homeViewModel) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'Total Screen Time',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                // const SizedBox(height: 4),
                Text(
                  homeViewModel.formattedTotalUsage,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 100),
            _buildStatItem(
              context,
              'Apps Used',
              '${homeViewModel.appUsageList.length}',
              Icons.apps,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatItem(
  BuildContext context,
  String label,
  String value,
  IconData icon,
) {
  return Column(
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ],
  );
}

Widget _buildTopAppsSection(BuildContext context, HomeViewModel homeViewModel) {
  if (homeViewModel.topApps.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'top apps',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: homeViewModel.topApps.length,
          itemBuilder:
              (context, index) => _buildAppUsageTile(
                context,
                homeViewModel.topApps[index],
                homeViewModel,
              ),
          separatorBuilder:
              (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(thickness: 1, color: Colors.black12),
              ),
        ),
      ],
    ),
  );
}

Widget _buildAppUsageTile(
  BuildContext context,
  AppUsageInfo app,
  HomeViewModel homeViewModel,
) {
  final color = homeViewModel.getUsageColor(app);

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildAppIcon(app, color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.appName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          app.formattedUsage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

/// Build app icon widget - real icon or fallback to material icon
Widget _buildAppIcon(AppUsageInfo app, Color fallbackColor) {
  if (app.hasIcon && app.iconBytes != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        app.iconBytes!,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if image fails
          return Icon(
            _getAppIcon(app.packageName),
            color: fallbackColor,
            size: 24,
          );
        },
      ),
    );
  } else {
    // Fallback to material icon
    return Icon(_getAppIcon(app.packageName), color: fallbackColor, size: 24);
  }
}

IconData _getAppIcon(String packageName) {
  final iconMap = {
    'com.instagram.android': Icons.camera_alt,
    'com.tiktok.musically': Icons.video_library,
    'com.whatsapp': Icons.chat,
    'com.spotify.music': Icons.music_note,
    'com.android.chrome': Icons.language,
    'com.youtube.android': Icons.play_circle_filled,
    'com.facebook.katana': Icons.thumb_up,
    'com.discord': Icons.chat_bubble,
    'com.twitter.android': Icons.flutter_dash,
    'com.snapchat.android': Icons.camera,
    'com.linkedin.android': Icons.work,
    'com.reddit.frontpage': Icons.forum,
  };

  return iconMap[packageName] ?? Icons.apps;
}

// Get mood image based on score
String _getMoodImage(double score) {
  if (score >= 80) return 'assets/images/vui.png'; // 100-80: Vui
  if (score >= 60) return 'assets/images/suynghi.png'; // 79-60: Suy nghĩ
  if (score >= 30) return 'assets/images/cangthang.png'; // 59-30: Căng thẳng
  return 'assets/images/buonngu.png'; // 29-0: Buồn ngủ
}
