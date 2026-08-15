import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator accepts valid emails and rejects invalid formats', () {
      expect(Validators.email('test@eventease.com'), isNull);
      expect(Validators.email('user.name+tag@sub.domain.org'), isNull);

      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
    });

    test('Password validator requires minimum 6 characters', () {
      expect(Validators.password('password123'), isNull);
      expect(Validators.password('123456'), isNull);

      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('Required validator tests', () {
      expect(Validators.required('Event Title', 'Title'), isNull);
      expect(Validators.required('', 'Title'), isNotNull);
      expect(Validators.required('   ', 'Title'), isNotNull);
    });

    test('Positive number validator tests', () {
      expect(Validators.positiveNumber('50'), isNull);
      expect(Validators.positiveNumber('1'), isNull);

      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-10'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
    });

    test('Confirm password match tests', () {
      expect(Validators.confirmPassword('secret', 'secret'), isNull);
      expect(Validators.confirmPassword('secret1', 'secret2'), isNotNull);
    });
  });
}
