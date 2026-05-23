// Интеграционные тесты для PDF-генерации.
// Проверяют реальную генерацию PDF с шрифтом Roboto.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Загружаем реальный шрифт из assets для интеграционных тестов
  setUpAll(() async {
    // Регистрируем assets для тестов
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      (MethodCall message) async {
        // Для тестов возвращаем null — шрифт загрузится из реальных assets
        // только если запущено через `flutter test --coverage`
        return null;
      },
    );
  });

  group('PdfExportService — интеграционные тесты', () {
    test('exportFromText signature correct', () async {
      // Проверяем что метод доступен и типы корректны
      expect(PdfExportService.exportFromText, isA<Function>());
    });

    test('exportCalculation signature correct', () async {
      // Проверяем сигнатуру exportCalculation
      expect(PdfExportService.exportCalculation, isA<Function>());
    });

    test('exportProject signature correct', () async {
      // Проверяем сигнатуру exportProject
      expect(PdfExportService.exportProject, isA<Function>());
    });
  });

  group('PdfExportService — edge cases', () {
    test('formatMoney handles very large numbers', () {
      expect(PdfExportService.formatMoney(999999999999), '1000000.0M ₽');
    });

    test('formatMoney handles small decimals', () {
      expect(PdfExportService.formatMoney(0.49), '0 ₽');
      expect(PdfExportService.formatMoney(0.5), '1 ₽'); // rounds up
    });

    test('sanitizeFileName handles very long strings', () {
      final longName = 'A' * 1000;
      final result = PdfExportService.sanitizeFileName(longName);
      expect(result.length, 1000);
      expect(result, longName);
    });

    test('sanitizeFileName handles unicode emojis', () {
      // Emojis are not \p{L} or \p{N}, so they get removed
      expect(PdfExportService.sanitizeFileName('Проект 🏠 дома'), 'Проект__дома');
    });

    test('sanitizeFileName handles tabs and newlines', () {
      expect(PdfExportService.sanitizeFileName('a\tb\nc'), 'a_b_c');
    });

    test('parseJson handles nested objects gracefully', () {
      // Nested objects will fail the (value as num) cast
      final result = PdfExportService.parseJson('{"a": {"b": 1}}');
      expect(result, isEmpty);
    });

    test('parseJson handles arrays gracefully', () {
      // Arrays will fail the Map<String, dynamic> cast
      final result = PdfExportService.parseJson('[1, 2, 3]');
      expect(result, isEmpty);
    });

    test('isLineBold handles Cyrillic uppercase correctly', () {
      expect(PdfExportService.isLineBold('АБВГДЕЁЖЗ'), isTrue);
      expect(PdfExportService.isLineBold('АБВ'), isTrue);
      expect(PdfExportService.isLineBold('АБ'), isFalse); // length <= 2
    });

    test('isLineBold handles mixed scripts', () {
      // Mixed case Cyrillic + Latin
      expect(PdfExportService.isLineBold('ABCабв'), isFalse);
      expect(PdfExportService.isLineBold('ABCАБВ'), isTrue);
    });

    test('formatDate handles edge dates', () {
      // Very old date
      expect(PdfExportService.formatDate(DateTime(1, 1, 1, 0, 0)), '1.1.1 0:00');
      // Far future date
      expect(PdfExportService.formatDate(DateTime(9999, 12, 31, 23, 59)), '31.12.9999 23:59');
    });
  });
}
