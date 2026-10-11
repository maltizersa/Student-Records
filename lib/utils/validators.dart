// Client-side validation, run before anything is sent to the API.

// Letters (including ñ, é, ...), spaces, periods, apostrophes and hyphens,
// e.g. "Ma. Clara", "O'Neil", "Dela Cruz", "Santos-Reyes".
final _namePattern = RegExp(r"^\p{L}[\p{L} .'-]*$", unicode: true);

const minAge = 1;
const maxAge = 120;

String? validateName(String? value, String label) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return '$label is required';
  if (name.length < 2) return '$label must be at least 2 characters';
  if (name.length > 50) return '$label must be 50 characters or less';
  if (!_namePattern.hasMatch(name)) {
    return '$label can only contain letters, spaces, periods, apostrophes and hyphens';
  }
  return null;
}

String? validateAge(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Age is required';
  final age = int.tryParse(text);
  if (age == null) return 'Age must be a whole number';
  if (age < minAge || age > maxAge) {
    return 'Age must be between $minAge and $maxAge';
  }
  return null;
}
