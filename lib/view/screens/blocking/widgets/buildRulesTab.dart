import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/blocking_rule.dart';
import '../../../../data/services/permission_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../../view_model/blocking_view_model.dart';
import 'buildRuleSection.dart';
import 'buildWarningCard.dart';

Widget buildRulesTab(BlockingViewModel blockingVM, S t) {
  final rules = blockingVM.rules;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Test blocking functionality card
        _buildTestCard(blockingVM, t),
        
        const SizedBox(height: 20),
        
        if (rules.where((r) => r.isActive).isEmpty) buildWarningCard(t),

        const SizedBox(height: 20),

        ...BlockingType.values.map((type) {
          final typeRules = rules.where((r) => r.type == type).toList();
          if (typeRules.isEmpty) return const SizedBox.shrink();

          return Column(
            children: [
              buildRuleSection(type, typeRules, blockingVM, t),
              const SizedBox(height: 20),
            ],
          );
        }),
      ],
    ),
  );
}

Widget _buildTestCard(BlockingViewModel blockingVM, S t) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.bug_report, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Test Blocking Functionality',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Test if app blocking is working properly. Make sure you have granted all permissions first.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        // Permission status
        FutureBuilder<PermissionStatus>(
          future: _getPermissionStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final status = snapshot.data!;
              return Column(
                children: [
                  _buildPermissionRow('Accessibility Service', status.hasAccessibilityPermission),
                  _buildPermissionRow('Display over other apps', status.hasOverlayPermission),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _testZaloBlock(blockingVM),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Test Zalo Block'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _testFocusMode(blockingVM),
                icon: const Icon(Icons.center_focus_strong, size: 16),
                label: const Text('Test Focus Mode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _testZaloBlock(BlockingViewModel blockingVM) async {
  // Create a test rule to block Zalo
  final testRule = BlockingRule(
    id: 'test_zalo_block',
    name: 'Test Zalo Block',
    description: 'Testing Zalo blocking',
    type: BlockingType.allDayBlock,
    targetPackages: ['com.zing.zalo'],
    createdAt: DateTime.now(),
    status: RuleStatus.active,
  );
  
  try {
    await blockingVM.addRule(testRule);
    debugPrint('✅ Test rule added for Zalo blocking');
    
    // Show success message
    // You could add a snackbar here
  } catch (e) {
    debugPrint('❌ Error adding test rule: $e');
  }
}

void _testFocusMode(BlockingViewModel blockingVM) async {
  try {
    // Start work focus mode for 5 minutes
    await blockingVM.startFocusMode('work', duration: const Duration(minutes: 5));
    debugPrint('✅ Test focus mode started');
    
    // Show success message
    // You could add a snackbar here
  } catch (e) {
    debugPrint('❌ Error starting test focus mode: $e');
  }
}

Future<PermissionStatus> _getPermissionStatus() async {
  final permissionService = PermissionService();
  return await permissionService.checkAllPermissions();
}

Widget _buildPermissionRow(String name, bool granted) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: granted ? Colors.green : Colors.red,
          ),
        ),
      ],
    ),
  );
}



