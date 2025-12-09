import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/repositories/calculation_repository.dart';

import '../../helpers/test_path_provider.dart';
import '../../helpers/isar_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalculationRepository repository;
  late TestPathProviderPlatform pathProvider;

  setUpAll(() async {
    pathProvider = installTestPathProvider();
    await ensureIsarInitialized();
  });

  setUp(() {
    repository = CalculationRepository();
  });

  tearDown(() async {
    // Закрываем базу данных после каждого теста
    await repository.close(deleteFromDisk: true);
  });

  tearDownAll(() {
    pathProvider.dispose();
  });

  group('CalculationRepository', () {
    test('saves calculation correctly', () async {
      await repository.saveCalculation(
        title: 'Test Calculation',
        calculatorId: 'plaster',
        calculatorName: 'Штукатурка',
        category: 'отделка',
        inputs: {'area': 20.0, 'thickness': 2.0},
        results: {'plasterNeeded': 100.0},
        totalCost: 5000.0,
        notes: 'Test notes',
      );

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Test Calculation'));
      expect(all.first.calculatorId, equals('plaster'));
      expect(all.first.totalCost, equals(5000.0));
      expect(all.first.notes, equals('Test notes'));
    });

    test('updates calculation correctly', () async {
      await repository.saveCalculation(
        title: 'Original Title',
        calculatorId: 'tile',
        calculatorName: 'Плитка',
        category: 'отделка',
        inputs: {'area': 10.0},
        results: {'tilesNeeded': 50.0},
        totalCost: 3000.0,
      );

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      final id = all.first.id;

      await repository.updateCalculation(
        id,
        title: 'Updated Title',
        totalCost: 4000.0,
        notes: 'Updated notes',
      );

      final updated = await repository.getCalculation(id);
      expect(updated, isNotNull);
      expect(updated!.title, equals('Updated Title'));
      expect(updated.totalCost, equals(4000.0));
      expect(updated.notes, equals('Updated notes'));
    });

    test('gets calculations by category', () async {
      await repository.saveCalculation(
        title: 'Foundation Calc',
        calculatorId: 'strip_foundation',
        calculatorName: 'Ленточный фундамент',
        category: 'фундамент',
        inputs: {'length': 20.0},
        results: {'concreteVolume': 10.0},
        totalCost: 50000.0,
      );

      await repository.saveCalculation(
        title: 'Wall Calc',
        calculatorId: 'plaster',
        calculatorName: 'Штукатурка',
        category: 'отделка',
        inputs: {'area': 15.0},
        results: {'plasterNeeded': 75.0},
        totalCost: 3000.0,
      );

      final foundationCalcs = await repository.getCalculationsByCategory('фундамент');
      expect(foundationCalcs.length, equals(1));
      expect(foundationCalcs.first.title, equals('Foundation Calc'));

      final finishingCalcs = await repository.getCalculationsByCategory('отделка');
      expect(finishingCalcs.length, equals(1));
      expect(finishingCalcs.first.title, equals('Wall Calc'));
    });

    test('deletes calculation correctly', () async {
      await repository.saveCalculation(
        title: 'To Delete',
        calculatorId: 'test',
        calculatorName: 'Test',
        category: 'отделка',
        inputs: {},
        results: {},
        totalCost: 1000.0,
      );

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      final id = all.first.id;

      await repository.deleteCalculation(id);

      expect(await repository.getCalculation(id), isNull);
      expect(await repository.getAllCalculations(), isEmpty);
    });

    test('searches calculations by title', () async {
      await repository.saveCalculation(
        title: 'Kitchen Renovation',
        calculatorId: 'tile',
        calculatorName: 'Плитка',
        category: 'отделка',
        inputs: {},
        results: {},
        totalCost: 10000.0,
      );

      await repository.saveCalculation(
        title: 'Bathroom Tiles',
        calculatorId: 'bathroom_tile',
        calculatorName: 'Плитка в ванную',
        category: 'отделка',
        inputs: {},
        results: {},
        totalCost: 8000.0,
      );

      final results = await repository.searchCalculations('Kitchen');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Kitchen Renovation'));

      final tileResults = await repository.searchCalculations('плитка');
      expect(tileResults.length, equals(2));
    });

    test('calculates statistics correctly', () async {
      await repository.saveCalculation(
        title: 'Calc 1',
        calculatorId: 'test1',
        calculatorName: 'Test 1',
        category: 'фундамент',
        inputs: {},
        results: {},
        totalCost: 10000.0,
      );

      await repository.saveCalculation(
        title: 'Calc 2',
        calculatorId: 'test2',
        calculatorName: 'Test 2',
        category: 'фундамент',
        inputs: {},
        results: {},
        totalCost: 15000.0,
      );

      await repository.saveCalculation(
        title: 'Calc 3',
        calculatorId: 'test3',
        calculatorName: 'Test 3',
        category: 'отделка',
        inputs: {},
        results: {},
        totalCost: 5000.0,
      );

      final stats = await repository.getStatistics();
      expect(stats['totalCalculations'], equals(3));
      expect(stats['totalCost'], equals(30000.0));
      expect(stats['categoryCount']['фундамент'], equals(2));
      expect(stats['categoryCount']['отделка'], equals(1));
    });

    test('handles empty repository', () async {
      final all = await repository.getAllCalculations();
      expect(all, isEmpty);

      final stats = await repository.getStatistics();
      expect(stats['totalCalculations'], equals(0));
      expect(stats['totalCost'], equals(0.0));
    });

    test('preserves JSON data correctly', () async {
      final complexInputs = {
        'area': 25.5,
        'thickness': 2.0,
        'windowsArea': 5.0,
      };
      final complexResults = {
        'plasterNeeded': 127.5,
        'primerNeeded': 5.1,
      };

      await repository.saveCalculation(
        title: 'Complex Calc',
        calculatorId: 'plaster',
        calculatorName: 'Штукатурка',
        category: 'отделка',
        inputs: complexInputs,
        results: complexResults,
        totalCost: 6375.0,
      );

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      // JSON данные должны быть сохранены и восстановлены
      expect(all.first.inputsJson, isNotEmpty);
      expect(all.first.resultsJson, isNotEmpty);
    });
  });
}
// ignore_for_file: avoid_dynamic_calls
