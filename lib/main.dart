import 'package:flutter/material.dart';

import 'screens/student_list_screen.dart';
import 'services/student_api.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key, this.api});

  /// Injected in tests; the real app creates one that talks to the PHP API.
  final StudentApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Records',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: StudentListScreen(api: api),
    );
  }
}
