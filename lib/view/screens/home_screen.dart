import 'package:brainrot/widgets/calendar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../view_model/app_view_model.dart';
import '../../view_model/home_view_model.dart';
import '../../data/model/app_usage_info.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/loading_page.dart';

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
              return  Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SpinKitFadingCircle(
                      color: Colors.orange,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text('Đang tải dữ liệu sử dụng ứng dụng...'),
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
                    Divider(
                      thickness: 1,
                      color: Colors.black12,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildUsageOverview(context, homeViewModel),
                    Divider(
                      thickness: 1,
                      color: Colors.black12,
                      indent: 16,
                      endIndent: 16,
                    ),

                    _buildTopAppsSection(context, homeViewModel),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
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
  final finalScore = homeViewModel.currentScore;
  final totalMinutes = homeViewModel.totalUsage.inMinutes;
  final goalMinutes = 120;

  return Column(
    children: [
      SizedBox(
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
                fontSize: 48,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final percent = (finalScore.clamp(0, 100)) / 100;
            final barHeight = 4.0;
            final fillWidth = constraints.maxWidth * percent;
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
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Điểm số sẽ đặt lại về 100 vào lúc nửa đêm.',
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
      const SizedBox(height: 16),
    ],
  );
}

void _showHealthCalculationDetails(
  BuildContext context,
  HomeViewModel homeViewModel,
  int totalMinutes,
  int goalMinutes,
  double finalScore,
) {
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
                              'assets/images/vui.png',
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
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Cách tính sức khỏe não',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Điểm sức khỏe não bộ của bạn bắt đầu từ 100 điểm mỗi ngày vào lúc nửa đêm và giảm dần dựa trên thời gian sử dụng thiết bị điện tử.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 12),
                              // decoration: BoxDecoration(
                              //   borderRadius: BorderRadius.circular(40),
                              //   boxShadow: [
                              //     BoxShadow(
                              //       color: _getScoreColor(
                              //         finalScore,
                              //       ).withOpacity(0.3),
                              //       blurRadius: 10,
                              //     ),
                              //   ],
                              // ),
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
                                        'assets/images/vui.png',
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
                              'Điểm hiện tại',
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
                      _buildCalculationRow(
                        'thời gian ước tính',
                        '${totalMinutes} phút (${(totalMinutes / 60).toStringAsFixed(1)} giờ)',
                      ),
                      _buildCalculationRow(
                        'mục tiêu',
                        '$goalMinutes phút (${(goalMinutes / 60).toStringAsFixed(1)} giờ)',
                      ),

                      const SizedBox(height: 16),

                      if (totalMinutes <= goalMinutes) ...[
                        _buildCalculationRow(
                          'điểm tiêu hao',
                          '${(totalMinutes / 60).toStringAsFixed(1)} giờ * ${(preGoalImpact / (totalMinutes / 60)).toStringAsFixed(1)}/hr',
                          impact: '-${preGoalImpact.toStringAsFixed(1)} điểm',
                          impactColor: Colors.red,
                        ),
                      ] else ...[
                        _buildCalculationRow(
                          'pre-goal impact',
                          '${(goalMinutes / 60).toStringAsFixed(1)} giờ * 5.0/giờ',
                          impact: '-${preGoalImpact.toStringAsFixed(1)} điểm',
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
                        'điểm còn lại',
                        '100 - điểm tiêu hao',
                        impact: '= ${finalScore.toStringAsFixed(1)} điểm',
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
                  'Tổng thời gian dùng',
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
              'App ',
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Các ứng dụng',
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
          return Icon(
            _getAppIcon(app.packageName),
            color: fallbackColor,
            size: 24,
          );
        },
      ),
    );
  } else {
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

String _getMoodImage(double score) {
  if (score >= 80) return 'assets/images/vui.png';
  if (score >= 60) return 'assets/images/suynghi.png';
  if (score >= 30) return 'assets/images/cangthang.png';
  return 'assets/images/buonngu.png';
}
