import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/student.dart';
import 'api_exception.dart';

/// Client for the PHP students REST API.
///
/// Every request goes through [_send], which uses async/await with try/catch
/// and converts any failure into an [ApiException] with a friendly message.
class StudentApi {
  StudentApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.studentsUrl;

  final http.Client _client;
  final String _baseUrl;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const _badResponse =
      'The server sent an unexpected response. Check the PHP API and database setup.';

  Uri _uri([int? id]) => Uri.parse(id == null ? _baseUrl : '$_baseUrl/$id');

  /// `GET /` - list all students.
  Future<List<Student>> fetchStudents() async {
    final body = await _send(() => _client.get(_uri(), headers: _headers));
    if (body is! List) throw const ApiException(_badResponse);
    return body
        .whereType<Map<String, dynamic>>()
        .map(Student.fromJson)
        .toList();
  }

  /// `GET /:id` - a single student. Throws a 404 [ApiException] if missing.
  Future<Student> fetchStudent(int id) async {
    final body = await _send(
      () => _client.get(_uri(id), headers: _headers),
      forStudent: true,
    );
    if (body is! Map<String, dynamic>) throw const ApiException(_badResponse);
    return Student.fromJson(body);
  }

  /// `POST /` - create a student. Returns the saved record from the server.
  Future<Student> createStudent({
    required String firstName,
    required String lastName,
    required int age,
  }) async {
    final body = await _send(
      () => _client.post(
        _uri(),
        headers: _headers,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'age': age,
        }),
      ),
    );
    return _unwrapStudent(body);
  }

  /// `PUT /:id` - partial update. Only the fields that are passed get sent.
  Future<Student> updateStudent(
    int id, {
    String? firstName,
    String? lastName,
    int? age,
  }) async {
    // `?value` leaves the key out entirely when the value is null.
    final changes = <String, Object>{
      'first_name': ?firstName,
      'last_name': ?lastName,
      'age': ?age,
    };
    final body = await _send(
      () => _client.put(_uri(id), headers: _headers, body: jsonEncode(changes)),
      forStudent: true,
    );
    return _unwrapStudent(body);
  }

  /// `DELETE /:id`
  Future<void> deleteStudent(int id) async {
    await _send(
      () => _client.delete(_uri(id), headers: _headers),
      forStudent: true,
    );
  }

  void close() => _client.close();

  Future<Object?> _send(
    Future<http.Response> Function() request, {
    bool forStudent = false,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        "Can't reach the server. Make sure Apache and MySQL are running in XAMPP.",
      );
    }

    Object? body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      // PHP warnings/errors come back as HTML instead of JSON.
      throw ApiException(_badResponse, statusCode: response.statusCode);
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) return body;

    final serverMessage = body is Map ? body['message']?.toString() : null;
    final message = switch (status) {
      404 when forStudent =>
        'Student not found. It may have already been deleted.',
      404 => 'API not found. Check the URL in lib/config/api_config.dart.',
      >= 500 =>
        'Server error${serverMessage != null ? ': $serverMessage' : ''}. '
            'Make sure MySQL is running in XAMPP.',
      _ => serverMessage ?? 'Request failed (HTTP $status). Please try again.',
    };
    throw ApiException(message, statusCode: status);
  }

  /// POST and PUT respond with `{"status": ..., "data": {"student": {...}}}`.
  Student _unwrapStudent(Object? body) {
    final data = body is Map ? body['data'] : null;
    final student = data is Map ? data['student'] : null;
    if (student is Map<String, dynamic>) return Student.fromJson(student);
    throw const ApiException(_badResponse);
  }
}
