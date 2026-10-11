import 'package:flutter/foundation.dart';

/// Where the PHP REST API lives.
///
/// To point the app somewhere else without editing code (e.g. a real phone on
/// the same Wi-Fi as your PC), pass the URL when running:
///
///   flutter run --dart-define=API_URL=http://192.168.1.5/php_api_sample/api/student
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_URL');

  static String get studentsUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches the PC's localhost through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.0.69/php_api_sample/api/student';
    }
    return 'http://localhost/php_api_sample/api/student';
  }

  static const Duration timeout = Duration(seconds: 10);
}
