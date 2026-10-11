import 'package:flutter/material.dart';

import '../models/student.dart';
import '../theme/app_theme.dart';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({super.key, required this.student, this.size = 46});

  final Student student;
  final double size;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Text(
        student.initials.isEmpty ? '?' : student.initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Small rounded label, like the "Present" badges in the design.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color = AppColors.success,
    this.background = AppColors.successSoft,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
