import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/api_exception.dart';
import '../services/student_api.dart';
import '../theme/app_theme.dart';
import '../widgets/delete_student_dialog.dart';
import '../widgets/feedback.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/student_avatar.dart';
import 'student_form_screen.dart';

/// Shows one student, loaded fresh from `GET /:id`.
///
/// Pops with `true` if the student was edited, deleted or turned out to be
/// missing, so the list knows to refresh.
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({
    super.key,
    required this.api,
    required this.studentId,
  });

  final StudentApi api;
  final int studentId;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Student? _student;
  bool _loading = true;
  bool _deleting = false;
  bool _notFound = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final student = await withMinDuration(
        widget.api.fetchStudent(widget.studentId),
      );
      if (!mounted) return;
      setState(() => _student = student);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notFound = e.isNotFound;
        _error = e.message;
        // The list is showing a student that no longer exists.
        if (e.isNotFound) _changed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
    });
    _load();
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<Student>(
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(api: widget.api, student: _student),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _student = updated;
      _changed = true;
    });
    showAppSnackBar(context, '${updated.fullName} was updated.');
  }

  Future<void> _delete() async {
    final student = _student!;
    final confirmed = await confirmDeleteStudent(context, student: student);
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    var deleted = false;
    try {
      await withMinDuration(widget.api.deleteStudent(student.id));
      deleted = true;
    } catch (e) {
      // A 404 means someone already deleted it - the end result is the same.
      deleted = e is ApiException && e.isNotFound;
      if (!deleted && mounted) {
        showAppSnackBar(context, friendlyError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }

    if (!deleted || !mounted) return;
    showAppSnackBar(context, '${student.fullName} was deleted.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _deleting;

    return LoadingOverlay(
      loading: busy,
      message: _deleting ? 'Deleting student...' : 'Loading student...',
      child: PopScope<Object?>(
        // Always hand `_changed` back to the list, even on the back button.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !busy) Navigator.of(context).pop(_changed);
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Student Details')),
          body: SafeArea(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // The loading overlay covers the screen while loading.
    if (_loading) return const SizedBox.shrink();
    if (_notFound) {
      return StatusView(
        icon: Icons.person_off_outlined,
        iconColor: AppColors.danger,
        title: 'Student not found',
        message:
            'Student ID #${widget.studentId} no longer exists. '
            'It may have been deleted.',
        actionLabel: 'Back to list',
        actionIcon: Icons.arrow_back_rounded,
        onAction: () => Navigator.of(context).pop(true),
      );
    }
    if (_error != null) {
      return StatusView(
        icon: Icons.cloud_off_rounded,
        iconColor: AppColors.danger,
        title: "Couldn't load student",
        message: _error,
        actionLabel: 'Try again',
        onAction: _retry,
      );
    }

    final student = _student!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Panel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    StudentAvatar(student: student, size: 84),
                    const SizedBox(height: 14),
                    Text(
                      student.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student ID #${student.displayId}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Pill(label: '${student.age} years old'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Panel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Student ID',
                      value: '${student.id}',
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'First name',
                      value: student.firstName,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Last name',
                      value: student.lastName,
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: '${student.age}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _edit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Student'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
