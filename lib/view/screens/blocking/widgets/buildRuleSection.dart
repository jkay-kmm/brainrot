import 'package:flutter/material.dart';

import '../../../../data/model/blocking_rule.dart';
import '../../../../l10n/l10n.dart';
import '../../../../view_model/blocking_view_model.dart';
import 'buildRuleItem.dart';

Widget buildRuleSection(BlockingType type, List<BlockingRule> rules, BlockingViewModel blockingVM, S t) {
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
      ...rules.map((rule) => buildRuleItem(rule, blockingVM, t)),
    ],
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
