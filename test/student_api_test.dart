import 'dart:convert';

import 'package:api_sample/services/api_exception.dart';
import 'package:api_sample/services/student_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _base = 'http://test/php_api_sample/api/student';

StudentApi _apiReturning(
  Future<http.Response> Function(http.Request) handler,
) => StudentApi(baseUrl: _base, client: MockClient(handler));

void main() {
  test('fetchStudents parses the string numbers that GET / returns', () async {
    final api = _apiReturning((req) async {
      expect(req.method, 'GET');
      expect(req.url.toString(), _base);
      return http.Response(
        '[{"id":"4","first_name":"Michael","last_name":"Engson","age":"22"}]',
        200,
      );
    });

    final students = await api.fetchStudents();

    expect(students, hasLength(1));
    expect(students.first.id, 4);
    expect(students.first.age, 22);
    expect(students.first.fullName, 'Michael Engson');
    expect(students.first.initials, 'ME');
  });

  test('fetchStudent parses the int numbers that GET /:id returns', () async {
    final api = _apiReturning((req) async {
      expect(req.url.toString(), '$_base/4');
      return http.Response(
        '{"id":4,"first_name":"Michael","last_name":"Engson","age":22}',
        200,
      );
    });

    final student = await api.fetchStudent(4);

    expect(student.id, 4);
    expect(student.age, 22);
  });

  test('fetchStudent throws a not-found ApiException on 404', () async {
    final api = _apiReturning(
      (_) async =>
          http.Response('{"status":"fail","message":"Student not found"}', 404),
    );

    await expectLater(
      api.fetchStudent(999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isNotFound, 'isNotFound', isTrue)
            .having((e) => e.message, 'message', contains('not found')),
      ),
    );
  });

  test('createStudent POSTs JSON and unwraps data.student', () async {
    final api = _apiReturning((req) async {
      expect(req.method, 'POST');
      expect(req.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(req.body), {
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'age': 18,
      });
      return http.Response(
        '{"status":"success","data":{"student":'
        '{"id":18,"first_name":"Juan","last_name":"Dela Cruz","age":18}}}',
        201,
      );
    });

    final student = await api.createStudent(
      firstName: 'Juan',
      lastName: 'Dela Cruz',
      age: 18,
    );

    expect(student.id, 18);
  });

  test('updateStudent only sends the fields that are given', () async {
    final api = _apiReturning((req) async {
      expect(req.method, 'PUT');
      expect(req.url.toString(), '$_base/4');
      expect(jsonDecode(req.body), {'age': 23});
      return http.Response(
        '{"status":"success","data":{"student":'
        '{"id":4,"first_name":"Michael","last_name":"Engson","age":23}}}',
        200,
      );
    });

    final student = await api.updateStudent(4, age: 23);

    expect(student.age, 23);
  });

  test('deleteStudent sends DELETE /:id', () async {
    final api = _apiReturning((req) async {
      expect(req.method, 'DELETE');
      expect(req.url.toString(), '$_base/4');
      return http.Response('{"status":"success","data":null}', 200);
    });

    await api.deleteStudent(4);
  });

  test('a server that is down gives a friendly message', () async {
    final api = _apiReturning(
      (_) async => throw http.ClientException('Connection refused'),
    );

    await expectLater(
      api.fetchStudents(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('XAMPP'),
        ),
      ),
    );
  });

  test('a PHP error page instead of JSON gives a friendly message', () async {
    final api = _apiReturning(
      (_) async => http.Response('<br /><b>Fatal error</b>: ...', 200),
    );

    await expectLater(
      api.fetchStudents(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('unexpected'),
        ),
      ),
    );
  });
}
