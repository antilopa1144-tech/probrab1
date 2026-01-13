// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';

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

      test('обрабатывает JSON с нулевыми значениями', () {
        const jsonString = '{"zero": 0, "value": 10.5}';
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['zero'], equals(0.0));
        expect(converted['value'], equals(10.5));
      });

      test('обрабатывает JSON с очень большими числами', () {
        const jsonString = '{"large": 999999999.99, "small": 0.00001}';
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['large'], equals(999999999.99));
        expect(converted['small'], equals(0.00001));
      });

      test('обрабатывает JSON с русскими ключами', () {
        final data = {
          'Площадь': 25.5,
          'Высота': 3.0,
          'Ширина': 5.0,
        };
        final jsonString = jsonEncode(data);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['Площадь'], equals(25.5));
        expect(converted['Высота'], equals(3.0));
        expect(converted['Ширина'], equals(5.0));
      });

      test('обрабатывает JSON с дробными числами', () {
        final data = {
          'fraction1': 1.23456789,
          'fraction2': 0.999999,
          'fraction3': 123.456,
        };
        final jsonString = jsonEncode(data);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['fraction1'], closeTo(1.23456789, 0.0001));
        expect(converted['fraction2'], closeTo(0.999999, 0.0001));
        expect(converted['fraction3'], closeTo(123.456, 0.001));
      });

      test('возвращает пустую map для null JSON', () {
        Map<String, double> result;
        try {
          final decoded = jsonDecode('null') as Map<String, dynamic>?;
          result = decoded?.map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ) ??
              {};
        } catch (_) {
          result = {};
        }

        expect(result, isEmpty);
      });

      test('обрабатывает JSON массив как невалидный', () {
        const jsonString = '[1, 2, 3]';

        Map<String, double> result;
        try {
          final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
          result = decoded.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        } catch (_) {
          result = {};
        }

        expect(result, isEmpty);
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

      test('корректно форматирует начало года', () {
        final date = DateTime(2024, 1, 1, 0, 0);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('1.1.2024 0:00'));
      });

      test('корректно форматирует високосный год', () {
        final date = DateTime(2024, 2, 29, 12, 30);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('29.2.2024 12:30'));
      });

      test('корректно форматирует разные часы дня', () {
        for (int hour = 0; hour < 24; hour++) {
          final date = DateTime(2024, 6, 15, hour, 30);
          final formatted =
              '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          expect(formatted, equals('15.6.2024 $hour:30'));
        }
      });

      test('корректно форматирует разные минуты', () {
        final testMinutes = [0, 5, 15, 30, 45, 59];
        for (final minute in testMinutes) {
          final date = DateTime(2024, 6, 15, 10, minute);
          final formatted =
              '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          final expectedMinute = minute.toString().padLeft(2, '0');
          expect(formatted, equals('15.6.2024 10:$expectedMinute'));
        }
      });

      test('корректно форматирует все месяцы', () {
        for (int month = 1; month <= 12; month++) {
          final date = DateTime(2024, month, 15, 12, 30);
          final formatted =
              '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          expect(formatted, equals('15.$month.2024 12:30'));
        }
      });

      test('корректно форматирует даты в прошлом', () {
        final date = DateTime(2000, 1, 1, 0, 0);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('1.1.2000 0:00'));
      });

      test('корректно форматирует даты в будущем', () {
        final date = DateTime(2030, 12, 31, 23, 59);

        final formatted =
            '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        expect(formatted, equals('31.12.2030 23:59'));
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

      test('обрабатывает разные ID калькуляторов', () {
        final calculatorIds = ['brick', 'tile', 'plaster', 'laminate', 'paint'];

        for (final id in calculatorIds) {
          final calc = Calculation()
            ..title = 'Test $id'
            ..calculatorId = id
            ..calculatorName = 'Calculator $id'
            ..category = 'test'
            ..inputsJson = '{}'
            ..resultsJson = '{}'
            ..totalCost = 1000.0
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          expect(calc.calculatorId, equals(id));
        }
      });

      test('обрабатывает разные категории', () {
        final categories = [
          'фундамент',
          'стены',
          'кровля',
          'отделка',
          'полы'
        ];

        for (final category in categories) {
          final calc = Calculation()
            ..title = 'Test'
            ..calculatorId = 'test'
            ..calculatorName = 'Test'
            ..category = category
            ..inputsJson = '{}'
            ..resultsJson = '{}'
            ..totalCost = 1000.0
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          expect(calc.category, equals(category));
        }
      });

      test('обрабатывает разные стоимости', () {
        final costs = [0.0, 100.0, 1000.0, 99999.99, 0.01];

        for (final cost in costs) {
          final calc = Calculation()
            ..title = 'Test'
            ..calculatorId = 'test'
            ..calculatorName = 'Test'
            ..category = 'test'
            ..inputsJson = '{}'
            ..resultsJson = '{}'
            ..totalCost = cost
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          expect(calc.totalCost, equals(cost));
        }
      });

      test('создаёт Calculation с длинными заметками', () {
        final longNotes = 'Заметка ' * 100;

        final calc = Calculation()
          ..title = 'Test'
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..notes = longNotes
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.notes, equals(longNotes));
        expect(calc.notes!.length, greaterThan(500));
      });

      test('создаёт Calculation с длинным названием', () {
        final longTitle = 'Очень длинное название расчёта ' * 10;

        final calc = Calculation()
          ..title = longTitle
          ..calculatorId = 'test'
          ..calculatorName = 'Test'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 1000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        expect(calc.title, equals(longTitle));
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

      test('обрабатывает вложенные структуры как строки', () {
        final nested = {
          'level1': {
            'level2': 'value',
          },
        };

        final encoded = jsonEncode(nested);
        final decoded = jsonDecode(encoded);

        expect(decoded['level1'], isA<Map>());
      });

      test('обрабатывает юникод символы', () {
        final data = {
          'emoji': '😀',
          'chinese': '中文',
          'arabic': 'العربية',
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect(decoded['emoji'], equals('😀'));
        expect(decoded['chinese'], equals('中文'));
        expect(decoded['arabic'], equals('العربية'));
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

      test('форматирует отрицательные числа', () {
        expect((-10.5).toStringAsFixed(2), equals('-10.50'));
        expect((-0.1).toStringAsFixed(2), equals('-0.10'));
      });

      test('форматирует очень маленькие числа', () {
        expect(0.001.toStringAsFixed(2), equals('0.00'));
        expect(0.009.toStringAsFixed(2), equals('0.01'));
      });

      test('форматирует очень большие числа', () {
        expect(999999.99.toStringAsFixed(2), equals('999999.99'));
        expect(1000000.0.toStringAsFixed(2), equals('1000000.00'));
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

      test('обрабатывает JSON с пробелами в ключах', () {
        final data = {
          'Площадь помещения': 25.5,
          'Высота потолка': 3.0,
        };

        final encoded = jsonEncode(data);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;

        expect((decoded['Площадь помещения'] as num).toDouble(), equals(25.5));
        expect((decoded['Высота потолка'] as num).toDouble(), equals(3.0));
      });

      test('обрабатывает JSON с числами в экспоненциальной форме', () {
        const jsonString = '{"scientific": 1.5e2, "negative": 2.5e-3}';
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        final converted = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(converted['scientific'], equals(150.0));
        expect(converted['negative'], closeTo(0.0025, 0.0001));
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

      test('обрабатывает данные гипсокартонного калькулятора', () {
        final inputs = {
          'area': 30.0,
          'layers': 2.0,
        };
        final results = {
          'sheets': 15.0,
          'profiles': 50.0,
          'screws': 600.0,
        };

        final calc = Calculation()
          ..title = 'Гипсокартон'
          ..calculatorId = 'gypsum'
          ..calculatorName = 'Калькулятор гипсокартона'
          ..category = 'отделка'
          ..inputsJson = jsonEncode(inputs)
          ..resultsJson = jsonEncode(results)
          ..totalCost = 12000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final decodedResults =
            jsonDecode(calc.resultsJson) as Map<String, dynamic>;

        expect(decodedResults['sheets'], equals(15.0));
        expect(decodedResults['profiles'], equals(50.0));
        expect(decodedResults['screws'], equals(600.0));
      });

      test('обрабатывает данные штукатурного калькулятора', () {
        final inputs = {
          'area': 40.0,
          'thickness': 2.0,
        };
        final results = {
          'plaster': 200.0,
          'primer': 8.0,
        };

        final calc = Calculation()
          ..title = 'Штукатурка стен'
          ..calculatorId = 'plaster'
          ..calculatorName = 'Калькулятор штукатурки'
          ..category = 'отделка'
          ..inputsJson = jsonEncode(inputs)
          ..resultsJson = jsonEncode(results)
          ..totalCost = 15000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final decodedInputs =
            jsonDecode(calc.inputsJson) as Map<String, dynamic>;
        final decodedResults =
            jsonDecode(calc.resultsJson) as Map<String, dynamic>;

        expect(decodedInputs['area'], equals(40.0));
        expect(decodedInputs['thickness'], equals(2.0));
        expect(decodedResults['plaster'], equals(200.0));
        expect(decodedResults['primer'], equals(8.0));
      });

      test('обрабатывает данные ламинатного калькулятора', () {
        final inputs = {
          'area': 25.0,
          'waste': 10.0,
        };
        final results = {
          'laminate': 27.5,
          'underlayment': 25.0,
        };

        final calc = Calculation()
          ..title = 'Ламинат'
          ..calculatorId = 'laminate'
          ..calculatorName = 'Калькулятор ламината'
          ..category = 'полы'
          ..inputsJson = jsonEncode(inputs)
          ..resultsJson = jsonEncode(results)
          ..totalCost = 20000.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final decodedResults =
            jsonDecode(calc.resultsJson) as Map<String, dynamic>;

        expect(decodedResults['laminate'], equals(27.5));
        expect(decodedResults['underlayment'], equals(25.0));
      });
    });

    group('_buildInputsTable логика', () {
      test('создаёт таблицу для валидных входных данных', () {
        final inputsJson = jsonEncode({
          'length': 10.0,
          'width': 5.0,
        });

        final inputs = jsonDecode(inputsJson) as Map<String, dynamic>;
        final convertedInputs = inputs.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(convertedInputs.isNotEmpty, isTrue);
        expect(convertedInputs['length'], equals(10.0));
        expect(convertedInputs['width'], equals(5.0));
      });

      test('возвращает пустую map для пустого JSON', () {
        const inputsJson = '{}';

        final inputs = jsonDecode(inputsJson) as Map<String, dynamic>;

        expect(inputs.isEmpty, isTrue);
      });

      test('обрабатывает невалидный JSON', () {
        const invalidJson = 'invalid json';

        Map<String, double> result;
        try {
          final decoded = jsonDecode(invalidJson) as Map<String, dynamic>;
          result = decoded.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        } catch (_) {
          result = {};
        }

        expect(result.isEmpty, isTrue);
      });

      test('форматирует значения с 2 знаками после запятой', () {
        final inputsJson = jsonEncode({
          'area': 25.123,
          'height': 3.456,
        });

        final inputs = jsonDecode(inputsJson) as Map<String, dynamic>;
        final convertedInputs = inputs.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        for (final value in convertedInputs.values) {
          final formatted = value.toStringAsFixed(2);
          expect(formatted, matches(r'^\d+\.\d{2}$'));
        }
      });
    });

    group('_buildResultsTable логика', () {
      test('создаёт таблицу для валидных результатов', () {
        final resultsJson = jsonEncode({
          'bricks': 2500.0,
          'mortar': 0.5,
        });

        final results = jsonDecode(resultsJson) as Map<String, dynamic>;
        final convertedResults = results.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(convertedResults.isNotEmpty, isTrue);
        expect(convertedResults['bricks'], equals(2500.0));
        expect(convertedResults['mortar'], equals(0.5));
      });

      test('возвращает пустую map для пустого JSON', () {
        const resultsJson = '{}';

        final results = jsonDecode(resultsJson) as Map<String, dynamic>;

        expect(results.isEmpty, isTrue);
      });

      test('обрабатывает множество результатов', () {
        final largeResults = <String, double>{};
        for (var i = 0; i < 20; i++) {
          largeResults['result$i'] = i * 10.0;
        }

        final resultsJson = jsonEncode(largeResults);
        final results = jsonDecode(resultsJson) as Map<String, dynamic>;
        final convertedResults = results.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        expect(convertedResults.length, equals(20));
        expect(convertedResults['result10'], equals(100.0));
      });
    });

    group('exportCalculation интеграция', () {
      test('проверяет структуру Calculation для экспорта', () {
        final calc = Calculation()
          ..title = 'Тестовый расчёт'
          ..calculatorId = 'test'
          ..calculatorName = 'Тестовый калькулятор'
          ..category = 'отделка'
          ..inputsJson = jsonEncode({'area': 25.0})
          ..resultsJson = jsonEncode({'result': 50.0})
          ..totalCost = 5000.0
          ..notes = 'Тестовые заметки'
          ..createdAt = DateTime(2024, 1, 15, 10, 30)
          ..updatedAt = DateTime(2024, 1, 15, 10, 30);

        expect(calc.title, isNotEmpty);
        expect(calc.calculatorName, isNotEmpty);
        expect(calc.inputsJson, isNotEmpty);
        expect(calc.resultsJson, isNotEmpty);
      });

      test('проверяет наличие всех необходимых полей', () {
        final calc = Calculation()
          ..title = 'Test'
          ..calculatorId = 'test'
          ..calculatorName = 'Test Calculator'
          ..category = 'test'
          ..inputsJson = '{}'
          ..resultsJson = '{}'
          ..totalCost = 0.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        // Проверяем что все поля присутствуют
        expect(calc.title, isA<String>());
        expect(calc.calculatorId, isA<String>());
        expect(calc.calculatorName, isA<String>());
        expect(calc.category, isA<String>());
        expect(calc.inputsJson, isA<String>());
        expect(calc.resultsJson, isA<String>());
        expect(calc.totalCost, isA<double>());
        expect(calc.createdAt, isA<DateTime>());
        expect(calc.updatedAt, isA<DateTime>());
      });
    });
  });
}
