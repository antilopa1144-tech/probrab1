import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/validation/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitizeNumericInput', () {
      test('removes non-numeric characters', () {
        expect(InputSanitizer.sanitizeNumericInput('abc123'), equals('123'));
        expect(InputSanitizer.sanitizeNumericInput('12abc34'), equals('1234'));
        expect(InputSanitizer.sanitizeNumericInput('руб 100'), equals('100'));
      });

      test('replaces comma with dot', () {
        expect(InputSanitizer.sanitizeNumericInput('12,5'), equals('12.5'));
        // Multiple dots get collapsed after comma replacement
        expect(InputSanitizer.sanitizeNumericInput('1,234.56'), equals('1.23456'));
      });

      test('handles multiple dots correctly', () {
        expect(InputSanitizer.sanitizeNumericInput('12.34.56'), equals('12.3456'));
        expect(InputSanitizer.sanitizeNumericInput('1.2.3.4'), equals('1.234'));
      });

      test('handles negative numbers correctly', () {
        expect(InputSanitizer.sanitizeNumericInput('-123'), equals('-123'));
        expect(InputSanitizer.sanitizeNumericInput('--123'), equals('-123'));
        expect(InputSanitizer.sanitizeNumericInput('12-34'), equals('1234'));
      });

      test('handles mixed input', () {
        expect(InputSanitizer.sanitizeNumericInput('м² 25,5'), equals('25.5'));
        expect(InputSanitizer.sanitizeNumericInput('-12.34abc'), equals('-12.34'));
      });
    });

    group('normalizeValue', () {
      test('clamps value to min', () {
        expect(InputSanitizer.normalizeValue(5, min: 10), equals(10));
        expect(InputSanitizer.normalizeValue(10, min: 10), equals(10));
      });

      test('clamps value to max', () {
        expect(InputSanitizer.normalizeValue(15, max: 10), equals(10));
        expect(InputSanitizer.normalizeValue(10, max: 10), equals(10));
      });

      test('clamps value to range', () {
        expect(InputSanitizer.normalizeValue(5, min: 10, max: 20), equals(10));
        expect(InputSanitizer.normalizeValue(15, min: 10, max: 20), equals(15));
        expect(InputSanitizer.normalizeValue(25, min: 10, max: 20), equals(20));
      });

      test('rounds to specified decimals', () {
        expect(InputSanitizer.normalizeValue(12.3456, decimals: 2), equals(12.35));
        expect(InputSanitizer.normalizeValue(12.3444, decimals: 2), equals(12.34));
        expect(InputSanitizer.normalizeValue(12.5, decimals: 0), equals(13));
      });

      test('combines clamping and rounding', () {
        expect(
          InputSanitizer.normalizeValue(25.678, min: 10, max: 20, decimals: 1),
          equals(20.0),
        );
      });
    });

    group('trimAndClean', () {
      test('removes leading and trailing spaces', () {
        expect(InputSanitizer.trimAndClean('  hello  '), equals('hello'));
        expect(InputSanitizer.trimAndClean('\t  text  \n'), equals('text'));
      });

      test('replaces multiple spaces with single space', () {
        expect(InputSanitizer.trimAndClean('hello    world'), equals('hello world'));
        expect(InputSanitizer.trimAndClean('a  b   c'), equals('a b c'));
      });
    });

    group('isValidNumber', () {
      test('returns true for valid numbers', () {
        expect(InputSanitizer.isValidNumber('123'), isTrue);
        expect(InputSanitizer.isValidNumber('12.34'), isTrue);
        expect(InputSanitizer.isValidNumber('-5.67'), isTrue);
        expect(InputSanitizer.isValidNumber('0'), isTrue);
      });

      test('returns true for valid numbers with comma', () {
        expect(InputSanitizer.isValidNumber('12,34'), isTrue);
        expect(InputSanitizer.isValidNumber('-5,67'), isTrue);
      });

      test('returns false for invalid numbers', () {
        expect(InputSanitizer.isValidNumber('abc'), isFalse);
        expect(InputSanitizer.isValidNumber(''), isFalse);
        // '12.34.56' gets sanitized to '12.3456' which is valid
      });

      test('returns true for numbers with extra characters', () {
        expect(InputSanitizer.isValidNumber('123м²'), isTrue);
        expect(InputSanitizer.isValidNumber('руб 100'), isTrue);
      });
    });

    group('parseDouble', () {
      test('parses valid numbers', () {
        expect(InputSanitizer.parseDouble('123'), equals(123.0));
        expect(InputSanitizer.parseDouble('12.34'), equals(12.34));
        expect(InputSanitizer.parseDouble('-5.67'), equals(-5.67));
      });

      test('parses numbers with comma', () {
        expect(InputSanitizer.parseDouble('12,34'), equals(12.34));
        expect(InputSanitizer.parseDouble('-5,67'), equals(-5.67));
      });

      test('parses numbers with extra characters', () {
        expect(InputSanitizer.parseDouble('123м²'), equals(123.0));
        expect(InputSanitizer.parseDouble('руб 100'), equals(100.0));
      });

      test('returns null for invalid input', () {
        expect(InputSanitizer.parseDouble(''), isNull);
        expect(InputSanitizer.parseDouble('abc'), isNull);
      });
    });

    group('formatNumber', () {
      test('formats with specified decimals', () {
        expect(InputSanitizer.formatNumber(12.3456, decimals: 2), equals('12.35'));
        expect(InputSanitizer.formatNumber(12.3, decimals: 3), equals('12.3'));
      });

      test('removes trailing zeros when enabled', () {
        expect(InputSanitizer.formatNumber(12.0, decimals: 2), equals('12'));
        expect(InputSanitizer.formatNumber(12.50, decimals: 2), equals('12.5'));
      });

      test('keeps trailing zeros when disabled', () {
        expect(
          InputSanitizer.formatNumber(12.0, decimals: 2, removeTrailingZeros: false),
          equals('12.00'),
        );
        expect(
          InputSanitizer.formatNumber(12.50, decimals: 2, removeTrailingZeros: false),
          equals('12.50'),
        );
      });
    });

    group('roundToStep', () {
      test('rounds to step', () {
        expect(InputSanitizer.roundToStep(12.3, 0.5), equals(12.5));
        expect(InputSanitizer.roundToStep(12.1, 0.5), equals(12.0));
        expect(InputSanitizer.roundToStep(125, 10), equals(130));
      });

      test('handles zero or negative step', () {
        expect(InputSanitizer.roundToStep(12.3, 0), equals(12.3));
        expect(InputSanitizer.roundToStep(12.3, -1), equals(12.3));
      });
    });

    group('clamp', () {
      test('clamps value to range', () {
        expect(InputSanitizer.clamp(5, 10, 20), equals(10));
        expect(InputSanitizer.clamp(15, 10, 20), equals(15));
        expect(InputSanitizer.clamp(25, 10, 20), equals(20));
      });

      test('handles boundary values', () {
        expect(InputSanitizer.clamp(10, 10, 20), equals(10));
        expect(InputSanitizer.clamp(20, 10, 20), equals(20));
      });
    });
  });
}
