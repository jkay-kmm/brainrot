import 'package:flutter/material.dart';
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
          "Settings",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildSettingsItem(
              "Language",
              () => _showComingSoon(context,"Language"),
              icon: Icons.language,
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              "Contact Us",
              () => _showComingSoon(context, "Contact Us"),
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 15),
            _buildSettingsItem(
              "privacyPolicy",
              () => _showComingSoon(context, "privacyPolicy"),
              icon: Icons.privacy_tip_outlined,
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              "Quan sát xung quanh",
                  () => _showComingSoon(context, "privacyPolicy"),
              icon: Icons.privacy_tip_outlined,
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              "Chế độ đi ngủ ",
                  () => _showComingSoon(context, "privacyPolicy"),
              icon: Icons.privacy_tip_outlined,
            ),
            const SizedBox(height: 30),

            // Center(
            //   child: Text(
            //     t.appVersion,
            //     style: TextStyle(color: Colors.grey[600], fontSize: 14),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
