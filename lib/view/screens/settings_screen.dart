// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/app_view_model.dart';
import 'package:brainrot/generated/l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            Text(
              t.supportFeedback,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildSettingsItem(
              t.helpSupport,
              Colors.blue,
              () => _showComingSoon(context, t.helpSupport),
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              t.featureRequests,
              Colors.orange,
              () => _showComingSoon(context, t.featureRequests),
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              t.leaveReview,
              Colors.amber,
              () => _showComingSoon(context, t.leaveReview),
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              t.contactUs,
              Colors.green,
              () => _showComingSoon(context, t.contactUs),
            ),
            const SizedBox(height: 15),
            _buildSettingsItem(
              t.privacyPolicy,
              Colors.purple,
              () => _showComingSoon(context, t.privacyPolicy),
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

  Widget _buildSettingsItem(String title, Color color, VoidCallback onTap) {
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
      builder:
          (context) => AlertDialog(
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
