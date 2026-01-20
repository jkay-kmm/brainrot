import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../generated/l10n.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'blocking_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const BlockingScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        height: 85,
        decoration: BoxDecoration(
          color: Color(0xFFFFE4B5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 8,
          ), // Thêm padding để cân bằng
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.black,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/home.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/images/home.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                ),
                label: t.home,
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/calendar.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/images/calendar.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                ),
                label: t.stats,
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/block.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/images/block.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                ),
                label: t.blocking,
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/setting.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                activeIcon: SvgPicture.asset(
                  'assets/images/setting.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn),
                ),
                label: t.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
