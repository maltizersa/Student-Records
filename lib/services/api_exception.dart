/// A failed API call, carrying a message that is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Turns any caught error into a message for the UI.
String friendlyError(Object error) => error is ApiException
    ? error.message
    : 'Something went wrong. Please try again.';
