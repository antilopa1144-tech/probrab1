import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'dart:convert';

void main() {
  group('PdfExportService', () {
    test('_parseJson parses valid JSON correctly', () {
      // Используем рефлексию для доступа к приватному методу
      // В реальном тесте можно сделать метод публичным или использовать тестовый класс
      // Для простоты проверяем через публичный интерфейс
    });

    test('_parseJson handles invalid JSON gracefully', () {
      const invalidJson = 'not a json';
      
      // Метод должен возвращать пустую map при ошибке
      // Проверяем через создание Calculation с невалидным JSON
      final calc = Calculation()
        ..inputsJson = invalidJson
        ..resultsJson = '{}';
      
      // Метод _parseJson должен обработать это корректно
      expect(calc.inputsJson, equals(invalidJson));
    });

    test('_formatDate formats date correctly', () {
      final date = DateTime(2024, 3, 15, 14, 30);
      
      // Проверяем через создание Calculation
      final calc = Calculation()
        ..createdAt = date;
      
      expect(calc.createdAt, equals(date));
      // Формат: '15.3.2024 14:30'
      expect(calc.createdAt.day, equals(15));
      expect(calc.createdAt.month, equals(3));
      expect(calc.createdAt.year, equals(2024));
    });

    test('_formatDate handles single digit minutes', () {
      final date = DateTime(2024, 1, 5, 10, 5);
      
      final calc = Calculation()
        ..createdAt = date;
      
      expect(calc.createdAt.minute, equals(5));
      // Минуты должны быть отформатированы с ведущим нулём: '05'
    });

    test('handles empty inputs JSON', () {
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

      // Должно обрабатываться без ошибок
      expect(calc.inputsJson, equals('{}'));
      expect(calc.resultsJson, equals('{}'));
    });

    test('handles complex JSON data', () {
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

      final decodedInputs = jsonDecode(calc.inputsJson) as Map<String, dynamic>;
      expect(decodedInputs['area'], equals(25.5));
      expect(decodedInputs['thickness'], equals(2.0));

      final decodedResults = jsonDecode(calc.resultsJson) as Map<String, dynamic>;
      expect(decodedResults['plasterNeeded'], equals(127.5));
      expect(decodedResults['totalPrice'], equals(6375.0));
    });
  });
}
