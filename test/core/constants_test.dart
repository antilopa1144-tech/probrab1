import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('has correct default colors', () {
      expect(AppConstants.primaryColor, equals(0xFF121212));
      expect(AppConstants.accentColor, equals(0xFFFFC107));
    });

    test('has correct app name', () {
      expect(AppConstants.appName, equals('Прораб AI'));
    });

    test('has all required regions', () {
      expect(AppConstants.regions.length, greaterThan(0));
      expect(AppConstants.regions, contains('Москва'));
      expect(AppConstants.regions, contains('Санкт-Петербург'));
      expect(AppConstants.regions, contains('Екатеринбург'));
      expect(AppConstants.regions, contains('Краснодар'));
      expect(AppConstants.regions, contains('Регионы РФ'));
    });

    test('regions list is not empty', () {
      expect(AppConstants.regions, isNotEmpty);
    });

    test('regions list contains unique values', () {
      final uniqueRegions = AppConstants.regions.toSet();
      expect(uniqueRegions.length, equals(AppConstants.regions.length));
    });
  });
}
