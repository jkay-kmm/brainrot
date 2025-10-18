import 'package:flutter/material.dart';
import '../../data/services/app_blocking_service.dart';
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
  final AppBlockingService _blockingService = AppBlockingService();
  final PermissionService _permissionService = PermissionService();
  late TabController _tabController;

  Map<String, AppBlockInfo> _appBlockStatus = {};
  bool _isLoading = true;
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _blockingService.initialize();
    _loadBlockStatus();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await _permissionService.checkAllPermissions();
      setState(() => _permissionStatus = status);
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _loadBlockStatus() async {
    setState(() => _isLoading = true);

    try {
      final blockStatus = await _blockingService.getAllAppBlockStatus();
      setState(() {
        _appBlockStatus = blockStatus;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading block status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      appBar: AppBar(
        title: const Text(
          'app locking',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFE4B5),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Rules', icon: Icon(Icons.rule)),
            Tab(text: 'Focus', icon: Icon(Icons.center_focus_strong)),
            Tab(text: 'Apps', icon: Icon(Icons.apps)),
          ],
        ),
        actions: [
          // Permission setup button
          if (_permissionStatus?.allPermissionsGranted != true)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.red),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermissionSetupScreen(),
                    ),
                  ),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRulesTab(), _buildFocusTab(), _buildAppsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================================================
  // RULES TAB
  // ============================================================================

  Widget _buildRulesTab() {
    return StreamBuilder<List<BlockingRule>>(
      stream: _blockingService.rulesStream,
      initialData: _blockingService.rules,
      builder: (context, snapshot) {
        final rules = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active rules warning
              if (rules.where((r) => r.isActive).isEmpty) _buildWarningCard(),

              const SizedBox(height: 20),

              // Rules by type
              ...BlockingType.values.map((type) {
                final typeRules = rules.where((r) => r.type == type).toList();
                if (typeRules.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _buildRuleSection(type, typeRules),
                    const SizedBox(height: 20),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarningCard() {
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
          const Expanded(
            child: Text(
              'No rules active right now - you should set some!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(BlockingType type, List<BlockingRule> rules) {
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
        ...rules.map((rule) => _buildRuleItem(rule)),
      ],
    );
  }

  Widget _buildRuleItem(BlockingRule rule) {
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
                    '${rule.targetPackages.length} apps targeted',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: rule.isActive,
            onChanged: (value) => _blockingService.toggleRule(rule.id),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FOCUS TAB
  // ============================================================================

  Widget _buildFocusTab() {
    return StreamBuilder<List<FocusMode>>(
      stream: _blockingService.focusModesStream,
      initialData: _blockingService.focusModes,
      builder: (context, snapshot) {
        final focusModes = snapshot.data ?? [];
        final activeFocus = _blockingService.activeFocusMode;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active focus mode card
              if (activeFocus != null)
                _buildActiveFocusCard(activeFocus)
              else
                _buildNoActiveFocusCard(),

              const SizedBox(height: 30),

              // Available focus modes
              const Text(
                'Available Focus Modes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              ...focusModes.map((mode) => _buildFocusModeItem(mode)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFocusCard(FocusMode focusMode) {
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
                onPressed: () => _blockingService.stopFocusMode(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveFocusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              'No focus mode is currently active. Select one below to start focusing.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeItem(FocusMode focusMode) {
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
            focusMode.isActive ? null : () => _showFocusModeDialog(focusMode),
        tileColor: Colors.white.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================================
  // APPS TAB
  // ============================================================================

  Widget _buildAppsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final apps = _appBlockStatus.values.toList();
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
                  'Blocked',
                  apps.where((a) => a.isBlocked).length.toString(),
                  Colors.red,
                  Icons.block,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Limited',
                  apps.where((a) => a.isLimited).length.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Allowed',
                  apps.where((a) => a.isAllowed).length.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Apps list
          const Text(
            'App Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          ...apps.map((app) => _buildAppStatusItem(app)),
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

  Widget _buildAppStatusItem(AppBlockInfo app) {
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
                    'Today: ${app.formattedDailyUsage}',
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

  // ============================================================================
  // DIALOGS
  // ============================================================================

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

  void _showFocusModeDialog(FocusMode focusMode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Start ${focusMode.name}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(focusMode.description),
                const SizedBox(height: 15),
                const Text('Duration:'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _blockingService.startFocusMode(
                            focusMode.id,
                            duration: const Duration(minutes: 30),
                          );
                        },
                        child: const Text('30 min'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _blockingService.startFocusMode(
                            focusMode.id,
                            duration: const Duration(hours: 1),
                          );
                        },
                        child: const Text('1 hour'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _blockingService.startFocusMode(
                            focusMode.id,
                            duration: const Duration(hours: 2),
                          );
                        },
                        child: const Text('2 hours'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _blockingService.startFocusMode(focusMode.id);
                },
                child: const Text('Start Indefinitely'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('App Blocking Help'),
            content: const Text(
              'This screen helps you manage app blocking rules and focus modes.\n\n'
              '• Rules: Set time limits, schedules, and blocks for specific apps\n'
              '• Focus: Use predefined focus modes for different activities\n'
              '• Apps: View the current blocking status of all your apps\n\n'
              'Toggle rules on/off using the switches, or start focus modes for immediate blocking.',
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
