import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/services/pdf_export_service.dart';

void main() {
  // ─────────────────────────────────────────────────
  // formatMoney
  // ─────────────────────────────────────────────────
  group('PdfExportService.formatMoney', () {
    test('менее 1000 — возвращает целое число с ₽', () {
      expect(PdfExportService.formatMoney(0), '0 ₽');
      expect(PdfExportService.formatMoney(1), '1 ₽');
      expect(PdfExportService.formatMoney(999), '999 ₽');
      expect(PdfExportService.formatMoney(500.7), '501 ₽');
    });

    test('от 1000 до 999_999 — формат Nk ₽', () {
      expect(PdfExportService.formatMoney(1000), '1k ₽');
      expect(PdfExportService.formatMoney(1500), '2k ₽'); // ceil via toStringAsFixed(0)
      expect(PdfExportService.formatMoney(10000), '10k ₽');
      expect(PdfExportService.formatMoney(999999), '1000k ₽');
    });

    test('от 1_000_000 — формат N.NM ₽', () {
      expect(PdfExportService.formatMoney(1000000), '1.0M ₽');
      expect(PdfExportService.formatMoney(1500000), '1.5M ₽');
      expect(PdfExportService.formatMoney(10000000), '10.0M ₽');
      expect(PdfExportService.formatMoney(12345678), '12.3M ₽');
    });

    test('отрицательные значения обрабатываются корректно', () {
      // Отрицательные числа не попадают в >= 1000 / >= 1_000_000,
      // поэтому всегда уходят в else-ветку (целое число с ₽).
      expect(PdfExportService.formatMoney(-500), '-500 ₽');
      expect(PdfExportService.formatMoney(-1500), '-1500 ₽');
    });

    test('ноль', () {
      expect(PdfExportService.formatMoney(0.0), '0 ₽');
    });
  });

  // ─────────────────────────────────────────────────
  // formatDate
  // ─────────────────────────────────────────────────
  group('PdfExportService.formatDate', () {
    test('корректный формат day.month.year hour:MM', () {
      final dt = DateTime(2024, 3, 5, 14, 7);
      expect(PdfExportService.formatDate(dt), '5.3.2024 14:07');
    });

    test('однозначные минуты дополняются нулём', () {
      final dt = DateTime(2024, 12, 31, 23, 0);
      expect(PdfExportService.formatDate(dt), '31.12.2024 23:00');
    });

    test('начало эпохи', () {
      final dt = DateTime(1970, 1, 1, 0, 0);
      expect(PdfExportService.formatDate(dt), '1.1.1970 0:00');
    });

    test('двузначные минуты не дублируют ноль', () {
      final dt = DateTime(2025, 6, 15, 9, 45);
      expect(PdfExportService.formatDate(dt), '15.6.2025 9:45');
    });
  });

  // ─────────────────────────────────────────────────
  // parseJson
  // ─────────────────────────────────────────────────
  group('PdfExportService.parseJson', () {
    test('корректный JSON с числами', () {
      final result = PdfExportService.parseJson('{"area": 20.5, "layers": 2}');
      expect(result, {'area': 20.5, 'layers': 2.0});
    });

    test('пустой объект JSON', () {
      expect(PdfExportService.parseJson('{}'), {});
    });

    test('невалидный JSON возвращает пустую карту', () {
      expect(PdfExportService.parseJson('not json at all'), {});
    });

    test('пустая строка возвращает пустую карту', () {
      expect(PdfExportService.parseJson(''), {});
    });

    test('JSON с нецисловыми значениями возвращает пустую карту', () {
      // num cast на String бросит, catch вернет {}
      expect(PdfExportService.parseJson('{"key": "value"}'), {});
    });

    test('JSON с целыми числами преобразуются в double', () {
      final result = PdfExportService.parseJson('{"count": 5}');
      expect(result['count'], isA<double>());
      expect(result['count'], 5.0);
    });

    test('JSON с отрицательными числами', () {
      final result = PdfExportService.parseJson('{"temp": -10.5}');
      expect(result, {'temp': -10.5});
    });

    test('JSON с нулевым значением', () {
      final result = PdfExportService.parseJson('{"zero": 0}');
      expect(result, {'zero': 0.0});
    });
  });

  // ─────────────────────────────────────────────────
  // sanitizeFileName
  // ─────────────────────────────────────────────────
  group('PdfExportService.sanitizeFileName', () {
    test('простое ASCII имя — пробелы заменяются на подчёркивания', () {
      expect(PdfExportService.sanitizeFileName('My Project'), 'My_Project');
    });

    test('кириллица сохраняется полностью', () {
      expect(PdfExportService.sanitizeFileName('Проект дома'), 'Проект_дома');
    });

    test('кириллица + цифры', () {
      expect(PdfExportService.sanitizeFileName('Проект 2024'), 'Проект_2024');
    });

    test('специальные символы удаляются', () {
      // № (U+2116) — категория So (Symbol, Other), не \p{N}, удаляется
      expect(PdfExportService.sanitizeFileName('Проект: №1!'), 'Проект_1');
    });

    test('пунктуация и слеши удаляются', () {
      expect(PdfExportService.sanitizeFileName('a/b\\c.d'), 'abcd');
    });

    test('дефисы сохраняются', () {
      expect(PdfExportService.sanitizeFileName('my-project-v2'), 'my-project-v2');
    });

    test('пустая строка', () {
      expect(PdfExportService.sanitizeFileName(''), '');
    });

    test('только специальные символы → пустая строка', () {
      expect(PdfExportService.sanitizeFileName('!@#\$%^&*()'), '');
    });

    test('смешанный регистр и языки', () {
      expect(
        PdfExportService.sanitizeFileName('Test Тест 123'),
        'Test_Тест_123',
      );
    });

    test('множественные пробелы каждый превращается в подчёркивание', () {
      expect(PdfExportService.sanitizeFileName('a  b'), 'a__b');
    });
  });

  // ─────────────────────────────────────────────────
  // isLineBold
  // ─────────────────────────────────────────────────
  group('PdfExportService.isLineBold', () {
    test('строка полностью верхний регистр и длина > 2 → жирная', () {
      expect(PdfExportService.isLineBold('РЕЗУЛЬТАТЫ'), true);
      expect(PdfExportService.isLineBold('ABC'), true);
    });

    test('строка верхний регистр но длина ≤ 2 → не жирная', () {
      expect(PdfExportService.isLineBold('AB'), false);
      expect(PdfExportService.isLineBold('A'), false);
    });

    test('строка со смешанным регистром → не жирная', () {
      expect(PdfExportService.isLineBold('Результаты'), false);
      expect(PdfExportService.isLineBold('результаты расчёта'), false);
    });

    test('кириллица верхний регистр → жирная', () {
      expect(PdfExportService.isLineBold('ВХОДНЫЕ ДАННЫЕ'), true);
    });

    test('кириллица со смешанным регистром → не жирная', () {
      expect(PdfExportService.isLineBold('Входные данные'), false);
    });

    test('начинается с ▸ → жирная', () {
      expect(PdfExportService.isLineBold('▸ Совет по работе'), true);
    });

    test('начинается с ► → жирная', () {
      expect(PdfExportService.isLineBold('► Пункт списка'), true);
    });

    test('начинается с • → жирная', () {
      expect(PdfExportService.isLineBold('• Маячки 6 мм'), true);
    });

    test('пустая строка → не жирная', () {
      expect(PdfExportService.isLineBold(''), false);
    });

    test('строка только пробелы → не жирная', () {
      expect(PdfExportService.isLineBold('   '), false);
    });

    test('числа и спецсимволы верхний регистр (нет букв) → зависит от длины', () {
      // "12 ₽" — toUpperCase == itself, trim length = 4 > 2 → true
      expect(PdfExportService.isLineBold('12 ₽'), true);
    });
  });
}
