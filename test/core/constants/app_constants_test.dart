import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    group('App Info', () {
      test('appName is correct', () {
        expect(AppConstants.appName, 'Мастерок');
      });

      test('appVersion is correct', () {
        expect(AppConstants.appVersion, '1.0.0');
      });
    });

    group('Colors', () {
      test('primaryColor is valid hex color', () {
        expect(AppConstants.primaryColor, 0xFF121212);
      });

      test('accentColor is valid hex color', () {
        expect(AppConstants.accentColor, 0xFFFFC107);
      });
    });

    group('Languages', () {
      test('supportedLanguages contains ru and en', () {
        expect(AppConstants.supportedLanguages, contains('ru'));
        expect(AppConstants.supportedLanguages, contains('en'));
        expect(AppConstants.supportedLanguages.length, 2);
      });

      test('defaultLanguage is ru', () {
        expect(AppConstants.defaultLanguage, 'ru');
      });

      test('defaultLanguage is in supportedLanguages', () {
        expect(
          AppConstants.supportedLanguages,
          contains(AppConstants.defaultLanguage),
        );
      });
    });

    group('Default Settings', () {
      test('defaultDarkMode is true', () {
        expect(AppConstants.defaultDarkMode, true);
      });

      test('defaultRegion is Москва', () {
        expect(AppConstants.defaultRegion, 'Москва');
      });
    });

    group('Regions', () {
      test('regions list is not empty', () {
        expect(AppConstants.regions, isNotEmpty);
      });

      test('regions contains major cities', () {
        expect(AppConstants.regions, contains('Москва'));
        expect(AppConstants.regions, contains('Санкт-Петербург'));
        expect(AppConstants.regions, contains('Екатеринбург'));
        expect(AppConstants.regions, contains('Краснодар'));
      });

      test('regions contains generic option', () {
        expect(AppConstants.regions, contains('Регионы РФ'));
      });

      test('defaultRegion is in regions list', () {
        expect(AppConstants.regions, contains(AppConstants.defaultRegion));
      });
    });

    group('Limits', () {
      test('maxProjectNameLength is reasonable', () {
        expect(AppConstants.maxProjectNameLength, 100);
        expect(AppConstants.maxProjectNameLength, greaterThan(0));
      });

      test('maxCalculationsPerProject is reasonable', () {
        expect(AppConstants.maxCalculationsPerProject, 50);
        expect(AppConstants.maxCalculationsPerProject, greaterThan(0));
      });

      test('maxCalculationArea is reasonable', () {
        expect(AppConstants.maxCalculationArea, 10000.0);
        expect(AppConstants.maxCalculationArea, greaterThan(0));
      });

      test('maxCalculationVolume is reasonable', () {
        expect(AppConstants.maxCalculationVolume, 1000.0);
        expect(AppConstants.maxCalculationVolume, greaterThan(0));
      });
    });

    group('Formatting', () {
      test('decimalPlaces is 2', () {
        expect(AppConstants.decimalPlaces, 2);
      });

      test('currencySymbol is ruble', () {
        expect(AppConstants.currencySymbol, '₽');
      });
    });

    group('Caching', () {
      test('cacheDuration is 24 hours', () {
        expect(AppConstants.cacheDuration, const Duration(hours: 24));
      });

      test('maxCacheSize is positive', () {
        expect(AppConstants.maxCacheSize, 100);
        expect(AppConstants.maxCacheSize, greaterThan(0));
      });
    });

    group('Export', () {
      test('exportFilePrefix is correct', () {
        expect(AppConstants.exportFilePrefix, 'probrab_ai');
      });

      test('pdfAuthor is correct', () {
        expect(AppConstants.pdfAuthor, 'Мастерок');
      });
    });
  });
}
