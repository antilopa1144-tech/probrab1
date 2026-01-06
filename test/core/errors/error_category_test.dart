import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/errors/error_category.dart';

void main() {
  group('ErrorCategory', () {
    test('has all expected values', () {
      expect(ErrorCategory.values, contains(ErrorCategory.validation));
      expect(ErrorCategory.values, contains(ErrorCategory.calculation));
      expect(ErrorCategory.values, contains(ErrorCategory.storage));
      expect(ErrorCategory.values, contains(ErrorCategory.network));
      expect(ErrorCategory.values, contains(ErrorCategory.export));
      expect(ErrorCategory.values, contains(ErrorCategory.ui));
      expect(ErrorCategory.values, contains(ErrorCategory.unknown));
    });

    test('has exactly 7 values', () {
      expect(ErrorCategory.values.length, 7);
    });

    test('values are ordered correctly', () {
      expect(ErrorCategory.validation.index, 0);
      expect(ErrorCategory.calculation.index, 1);
      expect(ErrorCategory.storage.index, 2);
      expect(ErrorCategory.network.index, 3);
      expect(ErrorCategory.export.index, 4);
      expect(ErrorCategory.ui.index, 5);
      expect(ErrorCategory.unknown.index, 6);
    });

    test('each value has correct name', () {
      expect(ErrorCategory.validation.name, 'validation');
      expect(ErrorCategory.calculation.name, 'calculation');
      expect(ErrorCategory.storage.name, 'storage');
      expect(ErrorCategory.network.name, 'network');
      expect(ErrorCategory.export.name, 'export');
      expect(ErrorCategory.ui.name, 'ui');
      expect(ErrorCategory.unknown.name, 'unknown');
    });

    test('can be used in switch statement', () {
      String getCategoryDescription(ErrorCategory category) {
        switch (category) {
          case ErrorCategory.validation:
            return 'Input validation error';
          case ErrorCategory.calculation:
            return 'Calculation error';
          case ErrorCategory.storage:
            return 'Storage error';
          case ErrorCategory.network:
            return 'Network error';
          case ErrorCategory.export:
            return 'Export error';
          case ErrorCategory.ui:
            return 'UI error';
          case ErrorCategory.unknown:
            return 'Unknown error';
        }
      }

      expect(getCategoryDescription(ErrorCategory.validation), 'Input validation error');
      expect(getCategoryDescription(ErrorCategory.unknown), 'Unknown error');
    });

    test('can be compared', () {
      expect(ErrorCategory.validation == ErrorCategory.validation, isTrue);
      expect(ErrorCategory.validation == ErrorCategory.calculation, isFalse);
    });

    test('can be stored in collection', () {
      final categories = {ErrorCategory.network, ErrorCategory.storage};

      expect(categories.contains(ErrorCategory.network), isTrue);
      expect(categories.contains(ErrorCategory.ui), isFalse);
    });
  });
}
