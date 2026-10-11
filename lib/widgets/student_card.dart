import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../models/student.dart';
import '../theme/app_theme.dart';
import 'student_avatar.dart';

/// One student row.
///
/// - Tap -> view
/// - Swipe right-to-left -> edit
/// - Long press (hold) -> delete
class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final VoidCallback onView;
  final Future<void> Function() onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Semantics(
      // Screen reader users can't swipe/hold easily, so expose the actions.
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Edit student'): onEdit,
        const CustomSemanticsAction(label: 'Delete student'): onDelete,
      },
      child: Dismissible(
        key: ValueKey('student-${student.id}'),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.3},
        // Opens the edit form, then returns false so the card slides back
        // instead of being removed.
        confirmDismiss: (_) async {
          await onEdit();
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: radius,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onView,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onDelete();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  StudentAvatar(student: student),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Student ID #${student.displayId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pill(label: '${student.age} yrs'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
