import 'dart:async';

import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/api_exception.dart';
import '../services/student_api.dart';
import '../theme/app_theme.dart';
import '../widgets/delete_student_dialog.dart';
import '../widgets/feedback.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/student_avatar.dart';
import '../widgets/student_card.dart';
import 'student_detail_screen.dart';
import 'student_form_screen.dart';

/// Home screen: lists every student.
///
/// - Floating button -> add
/// - Tap a card -> view
/// - Swipe a card right-to-left -> edit
/// - Hold a card -> delete
/// - Pull down or tap the refresh button -> reload
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key, this.api});

  /// Injected in tests. When null the screen creates (and closes) its own.
  final StudentApi? api;

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late final StudentApi _api = widget.api ?? StudentApi();
  final _search = TextEditingController();

  List<Student> _students = const [];
  String _query = '';
  String? _error;

  /// True until the first load finishes.
  bool _loading = true;

  /// Text for the loading overlay while refreshing/deleting. Null = hidden.
  String? _busyMessage;

  /// The students that match the search box (all of them when it's empty).
  List<Student> get _visibleStudents =>
      _students.where((s) => s.matches(_query)).toList();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  Future<void> _loadStudents() async {
    try {
      final students = await withMinDuration(_api.fetchStudents());
      if (!mounted) return;
      setState(() {
        _students = students;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = friendlyError(e);
      if (_students.isEmpty) {
        setState(() => _error = message);
      } else {
        // Keep showing the old list and just report the failure.
        showAppSnackBar(context, message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _busyMessage = null;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_loading || _busyMessage != null) return;
    setState(() => _busyMessage = 'Refreshing...');
    await _loadStudents();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadStudents();
  }

  Future<void> _addStudent() async {
    final created = await Navigator.of(context).push<Student>(
      MaterialPageRoute(builder: (_) => StudentFormScreen(api: _api)),
    );
    if (created == null || !mounted) return;
    setState(() {
      _students = [..._students, created];
      _error = null;
    });
    showAppSnackBar(context, '${created.fullName} was added.');
  }

  Future<void> _viewStudent(Student student) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(api: _api, studentId: student.id),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  Future<void> _editStudent(Student student) async {
    final updated = await Navigator.of(context).push<Student>(
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(api: _api, student: student),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _students = [for (final s in _students) s.id == updated.id ? updated : s];
    });
    showAppSnackBar(context, '${updated.fullName} was updated.');
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await confirmDeleteStudent(context, student: student);
    if (!confirmed || !mounted) return;

    setState(() => _busyMessage = 'Deleting student...');
    var deleted = false;
    try {
      await withMinDuration(_api.deleteStudent(student.id));
      deleted = true;
    } catch (e) {
      // A 404 means someone already deleted it - the end result is the same.
      deleted = e is ApiException && e.isNotFound;
      if (!deleted && mounted) {
        showAppSnackBar(context, friendlyError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyMessage = null);
    }

    if (!deleted || !mounted) return;
    setState(() {
      _students = _students.where((s) => s.id != student.id).toList();
    });
    showAppSnackBar(context, '${student.fullName} was deleted.');
  }

  @override
  Widget build(BuildContext context) {
    // The count is unknown while loading or if the first load failed.
    final countUnknown = _loading || (_error != null && _students.isEmpty);
    final visible = _visibleStudents;
    final searching = _query.trim().isNotEmpty;

    return LoadingOverlay(
      loading: _loading || _busyMessage != null,
      message: _busyMessage ?? 'Loading students...',
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            // Return right away so the overlay shows progress instead of the
            // pull-down spinner.
            onRefresh: () async => unawaited(_refresh()),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep content readable on wide screens by capping its width.
                const maxContentWidth = 1000.0;
                final width = constraints.maxWidth;
                final side = width > maxContentWidth + 32
                    ? (width - maxContentWidth) / 2
                    : 16.0;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(side, 16, side, 0),
                      sliver: SliverList.list(
                        children: [
                          _Header(onRefresh: _refresh),
                          const SizedBox(height: 20),
                          _SummaryCard(
                            total: countUnknown ? null : _students.length,
                            search: _SearchField(
                              controller: _search,
                              enabled: _students.isNotEmpty,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            title: searching
                                ? 'Search Results'
                                : 'All Students',
                            count: countUnknown ? null : visible.length,
                            showHints: !_loading && _students.isNotEmpty,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    _buildContent(visible, width, side),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addStudent,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Student'),
        ),
      ),
    );
  }

  Widget _buildContent(List<Student> visible, double width, double side) {
    // The loading overlay covers the screen during the first load.
    if (_loading) return const SliverToBoxAdapter();
    if (_error != null && _students.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: StatusView(
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.danger,
          title: "Couldn't load students",
          message: _error,
          actionLabel: 'Try again',
          onAction: _retry,
        ),
      );
    }
    if (_students.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: StatusView(
          icon: Icons.school_outlined,
          title: 'No students yet',
          message: 'Tap "Add Student" to create the first record.',
        ),
      );
    }
    if (visible.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: StatusView(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'No student matches "${_query.trim()}".',
          actionLabel: 'Clear search',
          actionIcon: Icons.close_rounded,
          onAction: _clearSearch,
        ),
      );
    }

    Widget card(Student student) => StudentCard(
      student: student,
      onView: () => _viewStudent(student),
      onEdit: () => _editStudent(student),
      onDelete: () => _deleteStudent(student),
    );
    // Extra bottom space so the floating button never covers the last card.
    final padding = EdgeInsets.fromLTRB(side, 0, side, 100);

    // Phones: one column. Tablets/desktop: a card grid.
    if (width < 640) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: visible.length,
          itemBuilder: (_, i) => card(visible[i]),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
        ),
      );
    }
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisExtent: 78 * textScale,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: visible.length,
        itemBuilder: (_, i) => card(visible[i]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Student Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
          child: IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.search});

  /// Null shows "--" (still loading, or the first load failed).
  final int? total;
  final Widget search;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Students',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      total == null ? '--' : '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          search,
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      // Hide the keyboard when tapping anywhere else (e.g. a result).
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: 'Search by name or ID',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    required this.showHints,
  });

  final String title;

  /// Null hides the count badge.
  final int? count;
  final bool showHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Pill(
                label: '$count',
                color: AppColors.primary,
                background: AppColors.primary.withValues(alpha: 0.1),
              ),
            ],
          ],
        ),
        // if (showHints) ...[
        //   const SizedBox(height: 8),
        //   const Wrap(
        //     spacing: 14,
        //     runSpacing: 6,
        //     children: [
        //       _Hint(icon: Icons.touch_app_outlined, label: 'Tap to view'),
        //       _Hint(
        //         icon: Icons.swipe_left_outlined,
        //         label: 'Swipe left to edit',
        //       ),
        //       _Hint(icon: Icons.pan_tool_outlined, label: 'Hold to delete'),
        //     ],
        //   ),
        // ],
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
