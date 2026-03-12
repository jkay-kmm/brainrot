import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../view_model/blocking_view_model.dart';
import '../../data/services/permission_service.dart';
import '../../data/model/blocking_rule.dart';
import 'rule_creation_screen.dart';
import 'permission_setup_screen.dart';

class BlockingScreen extends StatefulWidget {
  const BlockingScreen({super.key});

  @override
  State<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen> {
  final PermissionService _permissionService = PermissionService();

  bool _isLoading = true;
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isLoading = false);
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await _permissionService.checkAllPermissions();
      setState(() => _permissionStatus = status);
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Consumer<BlockingViewModel>(
      builder: (context, blockingVM, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFE4B5),
          appBar: AppBar(
            title: Text(
              "Blocking",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFFFE4B5),
            elevation: 0,
            actions: [
              // Permission setup button
              if (_permissionStatus?.allPermissionsGranted != true)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.red),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermissionSetupScreen(),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => _showHelpDialog(context, t),
              ),
            ],
          ),
          body: _buildRulesTab(blockingVM, t),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddRuleDialog(),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }


  Widget _buildRulesTab(BlockingViewModel blockingVM, S t) {
    final rules = blockingVM.rules;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active rules warning
          if (rules.where((r) => r.isActive).isEmpty) _buildWarningCard(t),

          const SizedBox(height: 20),

          // Rules by type
          ...BlockingType.values.map((type) {
            final typeRules = rules.where((r) => r.type == type).toList();
            if (typeRules.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                _buildRuleSection(type, typeRules, blockingVM, t),
                const SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWarningCard(S t) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.warning, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "no rules active right now - you should set some",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(BlockingType type, List<BlockingRule> rules, BlockingViewModel blockingVM, S t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getRuleTypeIcon(type),
              color: _getRuleTypeColor(type),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              type.name.replaceAll('_', ' '),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 5),
            Text(
              '(${rules.length})',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(),
            const Icon(Icons.expand_more, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 15),
        ...rules.map((rule) => _buildRuleItem(rule, blockingVM, t)),
      ],
    );
  }

  Widget _buildRuleItem(BlockingRule rule, BlockingViewModel blockingVM, S t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: rule.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (rule.targetPackages.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${rule.targetPackages.length} ${"hihi"}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: rule.isActive,
            onChanged: (value) => blockingVM.toggleRule(rule.id),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }











  IconData _getRuleTypeIcon(BlockingType type) {
    switch (type) {
      case BlockingType.timeLimit:
        return Icons.access_time;
      case BlockingType.schedule:
        return Icons.schedule;
      case BlockingType.allDayBlock:
        return Icons.block;
      case BlockingType.focusMode:
        return Icons.center_focus_strong;
    }
  }

  Color _getRuleTypeColor(BlockingType type) {
    switch (type) {
      case BlockingType.timeLimit:
        return Colors.orange;
      case BlockingType.schedule:
        return Colors.blue;
      case BlockingType.allDayBlock:
        return Colors.purple;
      case BlockingType.focusMode:
        return Colors.green;
    }
  }

  Widget _buildDailyResetCard(BlockingViewModel blockingVM, S t) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Usage Reset',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resets in ${blockingVM.formattedTimeUntilReset}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Usage counters reset automatically at midnight',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDailyResetInfo(t),
            icon: const Icon(Icons.info_outline, color: Colors.blue),
          ),
        ],
      ),
    );
  }


  void _showAddRuleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFFFE4B5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const RuleCreationScreen(),
      ),
    );
  }



  void _showHelpDialog(BuildContext context, S t) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text("hihi"),
        content: Text("hihi".replaceAll('\\n', '\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("haha"),
          ),
        ],
      ),
    );
  }

  void _showDailyResetInfo(S t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.blue),
            SizedBox(width: 10),
            Text('Daily Usage Reset'),
          ],
        ),
        content: const Text(
          'Daily usage counters automatically reset to zero every day at midnight (00:00).\n\n'
              'This ensures that:\n'
              '• Time limits restart fresh each day\n'
              '• Usage statistics are accurate\n'
              '• App blocking rules work correctly\n\n'
              'Just like Digital Wellbeing, your daily usage will reset automatically without any action needed from you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("haha"),
          ),
        ],
      ),
    );
  }
}
