import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../view_model/blocking_view_model.dart';
import '../../data/services/permission_service.dart';
import '../../data/model/blocking_rule.dart';
import '../../data/model/focus_mode.dart';
import '../../data/model/app_block_info.dart';
import 'rule_creation_screen.dart';
import 'permission_setup_screen.dart';

class BlockingScreen extends StatefulWidget {
  const BlockingScreen({super.key});

  @override
  State<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen>
    with TickerProviderStateMixin {
  final PermissionService _permissionService = PermissionService();
  late TabController _tabController;

  bool _isLoading = true;
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
    // BlockingViewModel is already initialized in app.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              t.appLocking,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFFFE4B5),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: t.rules, icon: const Icon(Icons.rule)),
                Tab(text: t.focus, icon: const Icon(Icons.center_focus_strong)),
                Tab(text: t.apps, icon: const Icon(Icons.apps)),
              ],
            ),
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
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRulesTab(blockingVM, t),
              _buildFocusTab(blockingVM, t),
              _buildAppsTab(blockingVM, t),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddRuleDialog(),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // ============================================================================
  // RULES TAB
  // ============================================================================

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
              t.noActiveRulesWarning,
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
                    '${rule.targetPackages.length} ${t.appsTargeted}',
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

  // ============================================================================
  // FOCUS TAB
  // ============================================================================

  Widget _buildFocusTab(BlockingViewModel blockingVM, S t) {
    final focusModes = blockingVM.focusModes;
    final activeFocus = blockingVM.activeFocusMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active focus mode card
          if (activeFocus != null)
            _buildActiveFocusCard(activeFocus, blockingVM, t)
          else
            _buildNoActiveFocusCard(t),

          const SizedBox(height: 30),

          // Available focus modes
          Text(
            t.availableFocusModes,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          ...focusModes.map((mode) => _buildFocusModeItem(mode, blockingVM, t)),
        ],
      ),
    );
  }

  Widget _buildActiveFocusCard(FocusMode focusMode, BlockingViewModel blockingVM, S t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: focusMode.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: focusMode.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: focusMode.color,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(focusMode.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focusMode.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      focusMode.statusText,
                      style: TextStyle(fontSize: 14, color: focusMode.color),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => blockingVM.stopFocusMode(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(t.stop),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveFocusCard(S t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              t.noFocusModeActive,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeItem(FocusMode focusMode, BlockingViewModel blockingVM, S t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: focusMode.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(focusMode.icon, color: focusMode.color, size: 20),
        ),
        title: Text(
          focusMode.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(focusMode.description),
        trailing:
            focusMode.isActive
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.play_arrow, color: Colors.grey),
        onTap:
            focusMode.isActive ? null : () => _showFocusModeDialog(focusMode, blockingVM, t),
        tileColor: Colors.white.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================================
  // APPS TAB
  // ============================================================================

  Widget _buildAppsTab(BlockingViewModel blockingVM, S t) {
    if (blockingVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final apps = blockingVM.appBlockStatus.values.toList();
    apps.sort((a, b) => a.appName.compareTo(b.appName));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  t.blocked,
                  apps.where((a) => a.isBlocked).length.toString(),
                  Colors.red,
                  Icons.block,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  t.limited,
                  apps.where((a) => a.isLimited).length.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  t.allowed,
                  apps.where((a) => a.isAllowed).length.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Daily reset info card
          _buildDailyResetCard(blockingVM, t),

          const SizedBox(height: 20),

          // Apps list
          Text(
            t.appStatus,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          ...apps.map((app) => _buildAppStatusItem(app, t)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAppStatusItem(AppBlockInfo app, S t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // App icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: app.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(app.statusIcon, color: app.statusColor, size: 20),
          ),
          const SizedBox(width: 15),

          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.blockReason ?? app.statusDisplayName,
                  style: TextStyle(fontSize: 14, color: app.statusColor),
                ),
                if (app.dailyUsage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t.today}: ${app.formattedDailyUsage}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: app.statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

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

  void _showFocusModeDialog(FocusMode focusMode, BlockingViewModel blockingVM, S t) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(t.startFocusMode(focusMode.name)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(focusMode.description),
                const SizedBox(height: 15),
                Text('${t.duration}:'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          blockingVM.startFocusMode(
                            focusMode.id,
                            duration: const Duration(minutes: 30),
                          );
                        },
                        child: Text('30 ${t.minutes}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          blockingVM.startFocusMode(
                            focusMode.id,
                            duration: const Duration(hours: 1),
                          );
                        },
                        child: Text('1 ${t.hour}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          blockingVM.startFocusMode(
                            focusMode.id,
                            duration: const Duration(hours: 2),
                          );
                        },
                        child: Text('2 ${t.hours}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  blockingVM.startFocusMode(focusMode.id);
                },
                child: Text(t.startIndefinitely),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog(BuildContext context, S t) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(t.appBlockingHelp),
            content: Text(t.appBlockingHelpContent.replaceAll('\\n', '\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.gotIt),
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
            child: Text(t.gotIt),
          ),
        ],
      ),
    );
  }
}
