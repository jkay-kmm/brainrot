// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/app_view_model.dart';
import 'package:brainrot/generated/l10n.dart';

import '../../view_model/locale_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _screenTimeGoal = 2.0; // hours

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: Text(
          t.settings, // 'settings'
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------- Screen time goal --------
            Text(
              t.screenTimeGoal,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.timer, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_screenTimeGoal.toStringAsFixed(1)} ${t.hours ?? "hours"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _screenTimeGoal,
                    min: 0.5,
                    max: 8.0,
                    divisions: 15,
                    label: '${_screenTimeGoal.toStringAsFixed(1)}h',
                    onChanged: (value) {
                      setState(() {
                        _screenTimeGoal = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Consumer<AppViewModel>(
              builder: (context, appVM, _) {
                final isVI = appVM.locale.languageCode == 'vi';
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language, color: Colors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.language, // 'Language'
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              t.changeLanguage, // 'Change app language'
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: appVM.toggleLocale,
                        child: Text(
                          // Nút ghi "Switch to English/Tiếng Việt"
                          isVI ? t.english : t.vietnamese,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // ------- Support & feedback (giữ nguyên, có thể đổi text sang t.*) -------
            Text(
              t.supportFeedback,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildSettingsItem(Icons.help_outline, t.helpSupport, Colors.blue,
                    () => _showComingSoon(context, t.helpSupport)),
            const SizedBox(height: 10),
            _buildSettingsItem(Icons.lightbulb_outline, t.featureRequests, Colors.orange,
                    () => _showComingSoon(context, t.featureRequests)),
            const SizedBox(height: 10),
            _buildSettingsItem(Icons.star_outline, t.leaveReview, Colors.amber,
                    () => _showComingSoon(context, t.leaveReview)),
            const SizedBox(height: 10),
            _buildSettingsItem(Icons.email_outlined, t.contactUs, Colors.green,
                    () => _showComingSoon(context, t.contactUs)),

            const SizedBox(height: 30),

            // ------- Legal -------
            Text(
              t.legal,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildSettingsItem(Icons.privacy_tip_outlined, t.privacyPolicy, Colors.purple,
                    () => _showComingSoon(context, t.privacyPolicy)),

            const SizedBox(height: 30),

            // ------- Theme toggle (giữ nguyên, chỉ đổi text sang t.* nếu muốn) -------
            Consumer<AppViewModel>(
              builder: (context, appViewModel, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          appViewModel.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.indigo,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.darkMode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              t.switchTheme,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: appViewModel.themeMode == ThemeMode.dark,
                        onChanged: (value) => appViewModel.toggleTheme(),
                        activeColor: Colors.indigo,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                t.appVersion,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
      IconData icon,
      String title,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
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
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature is coming soon! Stay tuned for updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
