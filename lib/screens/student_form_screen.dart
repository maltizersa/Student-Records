import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/student.dart';
import '../services/api_exception.dart';
import '../services/student_api.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/feedback.dart';
import '../widgets/loading_overlay.dart';

/// Add a student (POST) or, when [student] is given, edit one (PUT).
/// Pops with the saved [Student] from the server on success.
class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key, required this.api, this.student});

  final StudentApi api;
  final Student? student;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(
    text: widget.student?.firstName,
  );
  late final _lastName = TextEditingController(text: widget.student?.lastName);
  late final _age = TextEditingController(text: widget.student?.age.toString());

  bool _saving = false;
  String? _error;
  // Only start showing errors while typing after the first submit attempt.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  bool get _isEditing => widget.student != null;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }

    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final age = int.parse(_age.text.trim());
    final existing = widget.student;

    if (existing != null &&
        firstName == existing.firstName &&
        lastName == existing.lastName &&
        age == existing.age) {
      showAppSnackBar(context, 'No changes to save.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await withMinDuration(
        existing == null
            ? widget.api.createStudent(
                firstName: firstName,
                lastName: lastName,
                age: age,
              )
            // Partial update: only send the fields that actually changed.
            : widget.api.updateStudent(
                existing.id,
                firstName: firstName != existing.firstName ? firstName : null,
                lastName: lastName != existing.lastName ? lastName : null,
                age: age != existing.age ? age : null,
              ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _saving,
      message: _isEditing ? 'Saving changes...' : 'Adding student...',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Student' : 'Add Student'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FormHeader(
                          icon: _isEditing
                              ? Icons.edit_note_rounded
                              : Icons.person_add_alt_1_rounded,
                          title: 'Student Information',
                          subtitle: _isEditing
                              ? 'Editing Student ID #${widget.student!.displayId}'
                              : 'All fields are required.',
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _firstName,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              validateName(value, 'First name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lastName,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              validateName(value, 'Last name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _age,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: validateAge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _submit,
                          child: Text(
                            _isEditing ? 'Save Changes' : 'Add Student',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
