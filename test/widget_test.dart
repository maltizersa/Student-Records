import 'dart:async';
import 'dart:convert';

import 'package:api_sample/main.dart';
import 'package:api_sample/services/student_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory stand-in for the PHP API so the UI can be tested without XAMPP.
class FakeBackend {
  final students = <int, Map<String, Object>>{
    4: {'id': 4, 'first_name': 'Michael', 'last_name': 'Engson', 'age': 22},
    17: {'id': 17, 'first_name': 'Juan', 'last_name': 'Dela Cruz', 'age': 18},
  };
  final requests = <String>[];

  /// When set, requests wait for it to complete, simulating a slow server.
  Completer<void>? gate;

  StudentApi api() => StudentApi(
    baseUrl: 'http://test/php_api_sample/api/student',
    client: MockClient(_handle),
  );

  Future<http.Response> _handle(http.Request req) async {
    requests.add(req.method);
    await gate?.future;
    final segments = req.url.pathSegments;
    final id = segments.last == 'student' ? null : int.parse(segments.last);
    final notFound = http.Response(
      '{"status":"fail","message":"Student not found"}',
      404,
    );

    switch (req.method) {
      case 'GET' when id == null:
        return http.Response(jsonEncode(students.values.toList()), 200);
      case 'GET':
        final student = students[id];
        return student == null
            ? notFound
            : http.Response(jsonEncode(student), 200);
      case 'DELETE':
        if (students.remove(id) == null) return notFound;
        return http.Response('{"status":"success","data":null}', 200);
      default:
        return http.Response(
          '{"status":"fail","message":"Not supported"}',
          405,
        );
    }
  }
}

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  Future<void> pumpApp(WidgetTester tester) async {
    // Phone-sized screen.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(StudentApp(api: backend.api()));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the students from the API', (tester) async {
    await pumpApp(tester);

    expect(find.text('Michael Engson'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
  });

  testWidgets('add form validates before calling the API', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add Student'));
    await tester.pumpAndSettle();

    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
    expect(find.text('Age is required'), findsOneWidget);
    expect(backend.requests, isNot(contains('POST')));
  });

  testWidgets('swiping a card left opens the pre-filled edit form', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.drag(find.text('Michael Engson'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Edit Student'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Michael'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Engson'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '22'), findsOneWidget);
  });

  testWidgets('holding a card confirms, then deletes it', (tester) async {
    await pumpApp(tester);

    await tester.longPress(find.text('Juan Dela Cruz'));
    await tester.pumpAndSettle();
    expect(find.text('Delete student?'), findsOneWidget);
    expect(backend.requests, isNot(contains('DELETE')));

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(backend.requests, contains('DELETE'));
    expect(find.text('Juan Dela Cruz'), findsNothing);
    expect(find.text('Juan Dela Cruz was deleted.'), findsOneWidget);
  });

  testWidgets('tapping a card shows its details', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Michael Engson'));
    await tester.pumpAndSettle();

    expect(find.text('Student Details'), findsOneWidget);
    expect(find.text('22 years old'), findsOneWidget);
  });

  testWidgets('viewing a student that was deleted shows "not found"', (
    tester,
  ) async {
    await pumpApp(tester);
    backend.students.remove(4); // Deleted by someone else.

    await tester.tap(find.text('Michael Engson'));
    await tester.pumpAndSettle();

    expect(find.text('Student not found'), findsOneWidget);
  });

  testWidgets('a loading overlay blocks the screen while deleting', (
    tester,
  ) async {
    await pumpApp(tester);
    final gate = backend.gate = Completer<void>();

    await tester.longPress(find.text('Juan Dela Cruz'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Deleting student...'), findsOneWidget);

    // Taps underneath the overlay do nothing.
    await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Student Information'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Deleting student...'), findsNothing);
    expect(find.text('Juan Dela Cruz'), findsNothing);
  });

  testWidgets('refresh shows the overlay even when the server is instant', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump(); // The fake server has already answered here.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Refreshing...'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Refreshing...'), findsNothing);
  });

  testWidgets('search filters by name and can be cleared', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'juan');
    await tester.pumpAndSettle();
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Michael Engson'), findsNothing);
    expect(find.text('Search Results'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Michael Engson'), findsOneWidget);
    expect(find.text('All Students'), findsOneWidget);
  });
}
