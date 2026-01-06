import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/validation_exception.dart';
import 'package:probrab_ai/core/exceptions/app_exception.dart';

void main() {
  group('ValidationException', () {
    test('extends AppException', () {
      const exception = ValidationException('test');
      expect(exception, isA<AppException>());
    });

    test('stores message correctly', () {
      const exception = ValidationException('Test validation error');
      expect(exception.message, 'Test validation error');
    });

    test('stores optional parameters', () {
      const exception = ValidationException(
        'Test error',
        code: 'TEST_CODE',
        fieldName: 'area',
        invalidValue: -5.0,
        details: {'reason': 'negative'},
      );

      expect(exception.code, 'TEST_CODE');
      expect(exception.fieldName, 'area');
      expect(exception.invalidValue, -5.0);
      expect(exception.details, {'reason': 'negative'});
    });

    group('factory constructors', () {
      test('required creates correct exception', () {
        final exception = ValidationException.required('area');

        expect(exception.code, 'REQUIRED_FIELD');
        expect(exception.fieldName, 'area');
        expect(exception.message, contains('area'));
        expect(exception.message, contains('обязательно'));
      });

      test('minValue creates correct exception', () {
        final exception = ValidationException.minValue('width', 1.0, 0.5);

        expect(exception.code, 'MIN_VALUE');
        expect(exception.fieldName, 'width');
        expect(exception.invalidValue, 0.5);
        expect(exception.message, contains('width'));
        expect(exception.message, contains('1.0'));
        expect(exception.message, contains('0.5'));
        expect(exception.details, {'min': 1.0, 'actual': 0.5});
      });

      test('maxValue creates correct exception', () {
        final exception = ValidationException.maxValue('height', 10.0, 15.0);

        expect(exception.code, 'MAX_VALUE');
        expect(exception.fieldName, 'height');
        expect(exception.invalidValue, 15.0);
        expect(exception.message, contains('height'));
        expect(exception.message, contains('10.0'));
        expect(exception.message, contains('15.0'));
        expect(exception.details, {'max': 10.0, 'actual': 15.0});
      });

      test('invalidFormat creates correct exception', () {
        final exception = ValidationException.invalidFormat('phone', '+7 (XXX) XXX-XX-XX');

        expect(exception.code, 'INVALID_FORMAT');
        expect(exception.fieldName, 'phone');
        expect(exception.message, contains('phone'));
        expect(exception.message, contains('+7 (XXX) XXX-XX-XX'));
      });

      test('negative creates correct exception', () {
        final exception = ValidationException.negative('area', -10.0);

        expect(exception.code, 'NEGATIVE_VALUE');
        expect(exception.fieldName, 'area');
        expect(exception.invalidValue, -10.0);
        expect(exception.message, contains('area'));
        expect(exception.message, contains('-10.0'));
        expect(exception.message, contains('отрицательным'));
      });

      test('custom creates correct exception', () {
        final exception = ValidationException.custom(
          'Custom validation error',
          fieldName: 'customField',
        );

        expect(exception.code, 'CUSTOM');
        expect(exception.message, 'Custom validation error');
        expect(exception.fieldName, 'customField');
      });

      test('custom works without fieldName', () {
        final exception = ValidationException.custom('General validation error');

        expect(exception.code, 'CUSTOM');
        expect(exception.message, 'General validation error');
        expect(exception.fieldName, isNull);
      });
    });

    group('getUserMessage', () {
      test('returns message directly', () {
        const exception = ValidationException('Поле обязательно');
        expect(exception.getUserMessage(), 'Поле обязательно');
      });
    });
  });
}
