import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/project.dart';
import 'package:probrab_ai/data/models/calculation.dart';

void main() {
  group('Project', () {
    test('creates project with default values', () {
      final project = Project(
        id: 'test-1',
        name: 'Test Project',
        description: 'Test Description',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.id, equals('test-1'));
      expect(project.name, equals('Test Project'));
      expect(project.description, equals('Test Description'));
      expect(project.objectType, equals('дом'));
      expect(project.calculationIds, isEmpty);
      expect(project.totalBudget, equals(0));
      expect(project.spentAmount, equals(0));
      expect(project.metadata, isEmpty);
    });

    test('creates project with all fields', () {
      final startDate = DateTime(2024, 1, 1);
      final completionDate = DateTime(2024, 6, 1);
      final project = Project(
        id: 'test-2',
        name: 'Full Project',
        description: 'Full Description',
        objectType: 'квартира',
        calculationIds: ['calc-1', 'calc-2'],
        createdAt: DateTime(2023, 12, 1),
        startDate: startDate,
        completionDate: completionDate,
        totalBudget: 100000,
        spentAmount: 50000,
        metadata: {'key1': 'value1', 'key2': 42},
      );

      expect(project.calculationIds.length, equals(2));
      expect(project.startDate, equals(startDate));
      expect(project.completionDate, equals(completionDate));
      expect(project.totalBudget, equals(100000));
      expect(project.spentAmount, equals(50000));
      expect(project.metadata['key1'], equals('value1'));
      expect(project.metadata['key2'], equals(42));
    });

    test('fromCalculations creates project correctly', () {
      final calc1 = Calculation()
        ..title = 'Calc 1'
        ..calculatorId = 'plaster'
        ..calculatorName = 'Штукатурка'
        ..category = 'отделка'
        ..inputsJson = '{}'
        ..resultsJson = '{}'
        ..totalCost = 10000.0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final calc2 = Calculation()
        ..title = 'Calc 2'
        ..calculatorId = 'tile'
        ..calculatorName = 'Плитка'
        ..category = 'отделка'
        ..inputsJson = '{}'
        ..resultsJson = '{}'
        ..totalCost = 15000.0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final project = Project.fromCalculations(
        id: 'from-calc',
        name: 'From Calculations',
        description: 'Test',
        objectType: 'дом',
        calculations: [calc1, calc2],
      );

      expect(project.id, equals('from-calc'));
      expect(project.name, equals('From Calculations'));
      expect(project.totalBudget, equals(25000.0));
      expect(project.calculationIds.length, equals(2));
    });

    test('getProgress returns 100 when completed', () {
      final project = Project(
        id: 'completed',
        name: 'Completed',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        startDate: DateTime(2024, 1, 1),
        completionDate: DateTime(2024, 6, 1),
      );

      expect(project.getProgress(), equals(100.0));
    });

    test('getProgress returns 0 when not started', () {
      final project = Project(
        id: 'not-started',
        name: 'Not Started',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        // startDate is null
      );

      expect(project.getProgress(), equals(0.0));
    });

    test('getProgress returns 50 when started but not completed', () {
      final project = Project(
        id: 'in-progress',
        name: 'In Progress',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        startDate: DateTime(2024, 1, 1),
        // completionDate is null
      );

      // Текущая реализация возвращает 50.0 как заглушку
      expect(project.getProgress(), equals(50.0));
    });

    test('getRemainingBudget calculates correctly', () {
      final project = Project(
        id: 'budget-test',
        name: 'Budget Test',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        totalBudget: 100000,
        spentAmount: 30000,
      );

      expect(project.getRemainingBudget(), equals(70000.0));
    });

    test('getRemainingBudget returns totalBudget when nothing spent', () {
      final project = Project(
        id: 'no-spent',
        name: 'No Spent',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        totalBudget: 50000,
        spentAmount: 0,
      );

      expect(project.getRemainingBudget(), equals(50000.0));
    });

    test('getRemainingBudget returns 0 when all spent', () {
      final project = Project(
        id: 'all-spent',
        name: 'All Spent',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        totalBudget: 100000,
        spentAmount: 100000,
      );

      expect(project.getRemainingBudget(), equals(0.0));
    });

    test('getRemainingBudget handles negative values', () {
      final project = Project(
        id: 'over-budget',
        name: 'Over Budget',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime(2024, 1, 1),
        totalBudget: 100000,
        spentAmount: 120000,
      );

      expect(project.getRemainingBudget(), equals(-20000.0));
    });
  });
}
