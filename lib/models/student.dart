class Student {
  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
  });

  final int id;
  final String firstName;
  final String lastName;
  final int age;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }

  /// Zero-padded ID for display, e.g. 4 -> "0004".
  String get displayId => id.toString().padLeft(4, '0');

  /// Search: true if the name or ID contains [query] (case-insensitive).
  bool matches(String query) {
    final q = query.trim().toLowerCase().replaceFirst('#', '');
    if (q.isEmpty) return true;
    return fullName.toLowerCase().contains(q) || displayId.contains(q);
  }

  /// The API returns numbers as strings from `GET /` but as ints from
  /// `GET /:id`, so both are accepted here.
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _toInt(json['id']),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      age: _toInt(json['age']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
