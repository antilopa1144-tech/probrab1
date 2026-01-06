import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';

void main() {
  group('Calculation', () {
    test('creates with default id', () {
      final calculation = Calculation();
      // Isar.autoIncrement is a special value
      expect(calculation.id, isNotNull);
    });

    test('can set title', () {
      final calculation = Calculation()..title = 'Test Calculation';
      expect(calculation.title, 'Test Calculation');
    });

    test('can set calculatorId', () {
      final calculation = Calculation()..calculatorId = 'tile_calculator';
      expect(calculation.calculatorId, 'tile_calculator');
    });

    test('can set calculatorName', () {
      final calculation = Calculation()..calculatorName = 'Tile Calculator';
      expect(calculation.calculatorName, 'Tile Calculator');
    });

    test('can set category', () {
      final calculation = Calculation()..category = 'finishing';
      expect(calculation.category, 'finishing');
    });

    test('can set inputsJson', () {
      final calculation = Calculation()..inputsJson = '{"area": 25.0}';
      expect(calculation.inputsJson, '{"area": 25.0}');
    });

    test('can set resultsJson', () {
      final calculation = Calculation()..resultsJson = '{"tiles": 250}';
      expect(calculation.resultsJson, '{"tiles": 250}');
    });

    test('can set totalCost', () {
      final calculation = Calculation()..totalCost = 15000.50;
      expect(calculation.totalCost, 15000.50);
    });

    test('can set createdAt', () {
      final now = DateTime.now();
      final calculation = Calculation()..createdAt = now;
      expect(calculation.createdAt, now);
    });

    test('can set updatedAt', () {
      final now = DateTime.now();
      final calculation = Calculation()..updatedAt = now;
      expect(calculation.updatedAt, now);
    });

    test('notes is nullable', () {
      final calculation = Calculation();
      expect(calculation.notes, isNull);
    });

    test('can set notes', () {
      final calculation = Calculation()..notes = 'Test notes';
      expect(calculation.notes, 'Test notes');
    });

    test('can create complete calculation', () {
      final now = DateTime.now();
      final calculation = Calculation()
        ..title = 'Kitchen Tiles'
        ..calculatorId = 'floors_tile'
        ..calculatorName = 'Tile Calculator'
        ..category = 'finishing'
        ..inputsJson = '{"area": 15.0, "tileSize": 0.09}'
        ..resultsJson = '{"tilesNeeded": 180, "glueNeeded": 22.5}'
        ..totalCost = 12500.0
        ..createdAt = now
        ..updatedAt = now
        ..notes = 'For kitchen renovation';

      expect(calculation.title, 'Kitchen Tiles');
      expect(calculation.calculatorId, 'floors_tile');
      expect(calculation.calculatorName, 'Tile Calculator');
      expect(calculation.category, 'finishing');
      expect(calculation.inputsJson, contains('area'));
      expect(calculation.resultsJson, contains('tilesNeeded'));
      expect(calculation.totalCost, 12500.0);
      expect(calculation.createdAt, now);
      expect(calculation.updatedAt, now);
      expect(calculation.notes, 'For kitchen renovation');
    });
  });
}
