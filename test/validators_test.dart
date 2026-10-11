import 'package:api_sample/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateName', () {
    test('accepts real-world names', () {
      for (final name in [
        'Juan',
        'Dela Cruz',
        'Ma. Clara',
        "O'Neil",
        'Santos-Reyes',
        'Niño',
      ]) {
        expect(validateName(name, 'Name'), isNull, reason: name);
      }
    });

    test('rejects empty, too short, too long and invalid names', () {
      expect(validateName('', 'First name'), 'First name is required');
      expect(validateName('   ', 'First name'), 'First name is required');
      expect(validateName('J', 'First name'), contains('at least 2'));
      expect(validateName('A' * 51, 'First name'), contains('50 characters'));
      expect(validateName('Juan123', 'First name'), contains('only contain'));
      expect(validateName('-Juan', 'First name'), contains('only contain'));
    });
  });

  group('validateAge', () {
    test('accepts ages in range', () {
      expect(validateAge('1'), isNull);
      expect(validateAge('18'), isNull);
      expect(validateAge('120'), isNull);
    });

    test('rejects empty, non-numeric and out-of-range ages', () {
      expect(validateAge(''), 'Age is required');
      expect(validateAge('abc'), 'Age must be a whole number');
      expect(validateAge('0'), contains('between'));
      expect(validateAge('121'), contains('between'));
    });
  });
}
