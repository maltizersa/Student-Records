import 'package:flutter/material.dart';

import '../models/student.dart';
import '../theme/app_theme.dart';

/// Asks "Delete student?". Resolves to `true` only if the user tapped Delete.
Future<bool> confirmDeleteStudent(
  BuildContext context, {
  required Student student,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: AppColors.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 30,
        ),
      ),
      title: const Text('Delete student?'),
      content: Text.rich(
        TextSpan(
          text: 'This will permanently remove ',
          children: [
            TextSpan(
              text: student.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const TextSpan(text: '. This can\'t be undone.'),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, height: 1.4),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
