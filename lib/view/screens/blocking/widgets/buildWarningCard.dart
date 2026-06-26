import 'package:brainrot/l10n/l10n.dart';
import 'package:flutter/material.dart';

Widget buildWarningCard(S t) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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