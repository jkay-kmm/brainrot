import 'package:flutter/material.dart';

import '../../../../data/model/blocking_rule.dart';
import '../../../../l10n/l10n.dart';
import '../../../../view_model/blocking_view_model.dart';

Widget buildRuleItem(BlockingRule rule, BlockingViewModel blockingVM, S t) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
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