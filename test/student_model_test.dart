import 'package:api_sample/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const juan = Student(
    id: 17,
    firstName: 'Juan',
    lastName: 'Dela Cruz',
    age: 18,
  );

  test('matches searches the full name, ignoring case', () {
    expect(juan.matches(''), isTrue);
    expect(juan.matches('juan'), isTrue);
    expect(juan.matches('DELA'), isTrue);
    expect(juan.matches('juan dela'), isTrue);
    expect(juan.matches('  cruz  '), isTrue);
    expect(juan.matches('maria'), isFalse);
  });

  test('matches searches the student ID, with or without #', () {
    expect(juan.matches('17'), isTrue);
    expect(juan.matches('0017'), isTrue);
    expect(juan.matches('#0017'), isTrue);
    expect(juan.matches('99'), isFalse);
  });
}
