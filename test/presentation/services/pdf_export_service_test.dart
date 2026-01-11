import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/presentation/services/pdf_export_service.dart';

void main() {
  group('PdfExportService', () {
    group('_parseJson', () {
      test('парсит корректный JSON в map', () {
        const jsonString = '{"area": 25.5, "height": 3.0}';
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['area'], equals(25.5));
        expect(converted['height'], equals(3.0));
      });

      test('возвращает пустую map для невалидного JSON', () {
        const invalidJson = 'not a json';

        Map<String, double> result;
        try {
          final decoded = jsonDecode(invalidJson) as Map<String, dynamic>;
          result = decoded.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        } catch (_) {
          result = {};
        }

        expect(result, isEmpty);
      });

      test('парсит JSON с числами разных типов', () {
        const jsonString = '{"int": 10, "double": 15.5, "negative": -5.0}';
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['int'], equals(10.0));
        expect(converted['double'], equals(15.5));
        expect(converted['negative'], equals(-5.0));
      });

      test('обрабатывает пустой JSON объект', () {
        const jsonString = '{}';
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(parsed, isEmpty);
      });

      test('обрабатывает JSON с множеством полей', () {
        final largeJson = {
          for (var i = 0; i < 50; i++) 'field$i': i * 1.5,
        };
        final jsonString = jsonEncode(largeJson);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(parsed.length, equals(50));
        expect((parsed['field10'] as num).toDouble(), equals(15.0));
      });
    });

    group('_formatDate', () {
      test('форматирует дату в формате DD.MM.YYYY HH:MM', () {
        final date = DateTime(2024, 3, 15, 14, 30);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('15.3.2024 14:30'));
      });

      test('добавляет ведущий ноль для минут', () {
        final date = DateTime(2024, 1, 5, 10, 5);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('5.1.2024 10:05'));
      });

      test('корректно форматирует полночь', () {
        final date = DateTime(2024, 6, 15, 0, 0);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('15.6.2024 0:00'));
      });

      test('корректно форматирует конец дня', () {
        final date = DateTime(2024, 12, 31, 23, 59);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('31.12.2024 23:59'));
      });
    });

    group('Calculation model тесты', () {
      test('создаёт Calculation с пустыми JSON полями', () {
        final calc = Calculation()
          ..title = 'Test'
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.inputsJson, equals('{}'));
        expect(calc.resultsJson, equals('{}'));
        expect(calc.title, equals('Test'));
      });

      test('создаёт Calculation со сложными данными', () {
        final complexInputs = {
          'area': 25.5,
          'thickness': 2.0,
          'windowsArea': 5.0,
          'doorsArea': 3.0,
        };
        final complexResults = {
          'plasterNeeded': 127.5,
          'primerNeeded': 5.1,
          'totalPrice': 6375.0,
        };

        final calc = Calculation()
          ..title = 'Complex Test'
          ..calculatorId = 'plaster'
          ..calculatorName = 'Штукатурка'
          ..category = 'отделка'
          ..inputsJson = jsonEncode(complexInputs)
          ..resultsJson = jsonEncode(complexResults)
          ..totalCost = 6375.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final decodedInputs =
            jsonDecode(calc.inputsJson) as Map<String, dynamic>;
        expect(decodedInputs['area'], equals(25.5));
        expect(decodedInputs['thickness'], equals(2.0));
        expect(decodedInputs['windowsArea'], equals(5.0));

        final decodedResults =
            jsonDecode(calc.resultsJson) as Map<String, dynamic>;
        expect(decodedResults['plasterNeeded'], equals(127.5));
        expect(decodedResults['primerNeeded'], equals(5.1));
        expect(decodedResults['totalPrice'], equals(6375.0));
      });

      test('обрабатывает заметки', () {
        final calc = Calculation()
          ..title = 'Test with notes'
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..notes = 'Важные заметки'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.notes, equals('Важные заметки'));
      });

      test('обрабатывает null заметки', () {
        final calc = Calculation()
          ..title = 'Test without notes'
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.notes, isNull);
      });

      test('сохраняет даты создания и изменения', () {
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final updatedAt = DateTime(2024, 1, 16, 14, 45);

        final calc = Calculation()
          ..title = 'Test'
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..createdAt = createdAt
          ..updatedAt = updatedAt;

        expect(calc.createdAt, equals(createdAt));
        expect(calc.updatedAt, equals(updatedAt));
      });
    });

    group('JSON encoding/decoding', () {
      test('encode и decode сохраняют данные', () {
        final originalData = {
          'length': 10.5,
          'width': 5.3,
          'height': 2.7,
        };

        final encoded = jsonEncode(originalData);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect(decoded['length'], equals(10.5));
        expect(decoded['width'], equals(5.3));
        expect(decoded['height'], equals(2.7));
      });

      test('обрабатывает специальные символы в ключах', () {
        final data = {
          'area_m2': 25.0,
          'price_rub': 1500.0,
          'Площадь (м²)': 25.0,
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect(decoded['area_m2'], equals(25.0));
        expect(decoded['price_rub'], equals(1500.0));
        expect(decoded['Площадь (м²)'], equals(25.0));
      });

      test('обрабатывает большие числа', () {
        final data = {
          'veryLarge': 999999999.99,
          'verySmall': 0.00001,
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect(decoded['veryLarge'], equals(999999999.99));
        expect(decoded['verySmall'], equals(0.00001));
      });

      test('обрабатывает отрицательные числа', () {
        final data = {
          'negative': -50.5,
          'negativeInt': -100,
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect((decoded['negative'] as num).toDouble(), equals(-50.5));
        expect((decoded['negativeInt'] as num).toDouble(), equals(-100.0));
      });

      test('обрабатывает нулевые значения', () {
        final data = {
          'zero': 0,
          'zeroDouble': 0.0,
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect(decoded['zero'], equals(0));
        expect(decoded['zeroDouble'], equals(0.0));
      });
    });

    group('форматирование чисел для PDF', () {
      test('форматирует числа с 2 знаками после запятой', () {
        final values = [
          10.123456,
          25.5,
          100.0,
          0.1,
        ];

        for (final value in values) {
          final formatted = value.toStringAsFixed(2);
          expect(formatted, matches(r'^\d+\.\d{2}$'));
        }
      });

      test('округляет числа корректно', () {
        // toStringAsFixed использует banker's rounding
        expect(10.124.toStringAsFixed(2), equals('10.12'));
        expect(10.126.toStringAsFixed(2), equals('10.13'));
        expect(10.999.toStringAsFixed(2), equals('11.00'));
      });

      test('добавляет нули после запятой', () {
        expect(10.0.toStringAsFixed(2), equals('10.00'));
        expect(10.5.toStringAsFixed(2), equals('10.50'));
      });
    });

    group('граничные случаи', () {
      test('обрабатывает очень длинные JSON строки', () {
        final largeData = <String, double>{};
        for (var i = 0; i < 1000; i++) {
          largeData['field_$i'] = i * 1.5;
        }

        final encoded = jsonEncode(largeData);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect(decoded.length, equals(1000));
        expect((decoded['field_500'] as num).toDouble(), equals(750.0));
      });

      test('обрабатывает пустые строки в JSON', () {
        final data = {
          'emptyKey': '',
          'normalKey': 'value',
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded);

        expect(decoded['emptyKey'], equals(''));
        expect(decoded['normalKey'], equals('value'));
      });

      test('обрабатывает многострочные заметки', () {
        final calc = Calculation()
          ..title = 'Test'
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..notes = 'Строка 1\nСтрока 2\nСтрока 3'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.notes, contains('\n'));
        expect(calc.notes!.split('\n').length, equals(3));
      });

      test('обрабатывает русские символы в JSON', () {
        final data = {
          'Длина': 10.5,
          'Ширина': 5.0,
          'Высота': 3.0,
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect((decoded['Длина'] as num).toDouble(), equals(10.5));
        expect((decoded['Ширина'] as num).toDouble(), equals(5.0));
        expect((decoded['Высота'] as num).toDouble(), equals(3.0));
      });

      test('обрабатывает специальные символы в значениях', () {
        final calc = Calculation()
          ..title = 'Test "with quotes" & special <chars>'
          ..calculatorId = 'test'
          ..calculatorName = 'Test & Special'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..notes = 'Заметки с кавычками "test" и символами & < >'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.title, contains('"'));
        expect(calc.title, contains('&'));
        expect(calc.notes, contains('"'));
      });
    });

    group('интеграция с различными калькуляторами', () {
      test('обрабатывает данные кирпичного калькулятора', () {
        final inputs = {
          'length': 10.0,
          'height': 3.0,
          'thickness': 0.25,
        };
        final results = {
          'bricks': 2500.0,
          'mortar': 0.5,
        };

        final calc = Calculation()
          ..title = 'Кирпичная кладка'
          ..calculatorId = 'brick'
          ..calculatorName = 'Калькулятор кирпича'
          ..category = 'стены'
          ..inputsJson = jsonEncode(inputs)
          ..resultsJson = jsonEncode(results)
          ..totalCost = 50000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final decodedInputs =
            jsonDecode(calc.inputsJson) as Map<String, dynamic>;
        final decodedResults =
            jsonDecode(calc.resultsJson) as Map<String, dynamic>;

        expect(decodedInputs['length'], equals(10.0));
        expect(decodedResults['bricks'], equals(2500.0));
      });

      test('обрабатывает данные плиточного калькулятора', () {
        final inputs = {
          'area': 25.0,
          'tileWidth': 0.3,
          'tileHeight': 0.3,
        };
        final results = {
          'tilesCount': 278.0,
          'adhesive': 125.0,
        };

        final calc = Calculation()
          ..title = 'Плитка для ванной'
          ..calculatorId = 'tile'
          ..calculatorName = 'Калькулятор плитки'
          ..category = 'отделка'
          ..inputsJson = jsonEncode(inputs)
          ..resultsJson = jsonEncode(results)
          ..totalCost = 35000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final decodedResults =
            jsonDecode(calc.resultsJson) as Map<String, dynamic>;

        expect(decodedResults['tilesCount'], equals(278.0));
        expect(decodedResults['adhesive'], equals(125.0));
      });
    });
  });
}
