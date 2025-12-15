import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/data/repositories/calculation_repository.dart';
import 'package:probrab_ai/core/migrations/migration_flag_store.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

import '../../helpers/isar_test_utils.dart';
import '../../helpers/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalculationRepository repository;
  late InMemoryMigrationFlagStore flagStore;
  late TestPathProviderPlatform pathProvider;
  late Isar isar;

  setUpAll(() async {
    pathProvider = installTestPathProvider();
    await ensureIsarInitialized();
  });

  setUp(() async {
    // Закрываем предыдущие инстансы, чтобы не ловить конфликтов имен
    for (final name in List<String>.from(Isar.instanceNames)) {
      final instance = Isar.getInstance(name);
      if (instance != null && instance.isOpen) {
        await instance.close(deleteFromDisk: true);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ProjectV2Schema, ProjectCalculationSchema, CalculationSchema],
      directory: dir.path,
      name: 'calculation_test',
    );
    flagStore = InMemoryMigrationFlagStore();
    repository = CalculationRepository(isar, flagStore: flagStore);
  });

  tearDown(() async {
    // Закрываем базу данных после каждого теста
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
  });

  tearDownAll(() {
    pathProvider.dispose();
  });

  group('CalculationRepository', () {
    test('migrates stored legacy category labels to stable category name', () async {
      final legacy = Calculation()
        ..title = 'Legacy category'
        ..calculatorId = 'foundation_strip'
        ..calculatorName = 'Ленточный фундамент'
        ..category = 'Фундамент'
        ..inputsJson = '{}'
        ..resultsJson = '{}'
        ..totalCost = 0.0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.calculations.put(legacy);
      });

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      expect(all.first.category, equals('foundation'));

      final persisted = await isar.calculations.get(all.first.id);
      expect(persisted, isNotNull);
      expect(persisted!.category, equals('foundation'));
    });

    test('canonicalizes legacy calculatorId on save', () async {
      await repository.saveCalculation(
        title: 'Legacy ID',
        calculatorId: 'strip_foundation',
        calculatorName: 'Ленточный фундамент',
        category: 'foundation',
        inputs: {'length': 20.0},
        results: {'concreteVolume': 10.0},
        totalCost: 50000.0,
      );

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      expect(all.first.calculatorId, equals('foundation_strip'));
    });

    test('migrates legacy calculatorIds already stored in Isar', () async {
      final legacy = Calculation()
        ..title = 'Legacy stored'
        ..calculatorId = 'walls_paint'
        ..calculatorName = 'Покраска стен'
        ..category = 'Отделка'
        ..inputsJson = '{}'
        ..resultsJson = '{}'
        ..totalCost = 0.0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.calculations.put(legacy);
      });

      final all = await repository.getAllCalculations();
      expect(all.length, equals(1));
      expect(all.first.calculatorId, equals('wall_paint'));
      expect(all.first.category, equals('walls'));

      final persisted = await isar.calculations.get(all.first.id);
      expect(persisted, isNotNull);
      expect(persisted!.calculatorId, equals('wall_paint'));
      expect(persisted.category, equals('walls'));
    });

    test('saves calculation correctly', () async {
      await repository.saveCalculation(
        title: 'Test Calculation',
        calculatorId: 'plaster',
        calculatorName: 'Штукатурка',
        category: 'finishing',
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
        category: 'finishing',
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
        calculatorId: 'foundation_strip',
        calculatorName: 'Ленточный фундамент',
        category: 'foundation',
        inputs: {'length': 20.0},
        results: {'concreteVolume': 10.0},
        totalCost: 50000.0,
      );

      await repository.saveCalculation(
        title: 'Wall Calc',
        calculatorId: 'plaster',
        calculatorName: 'Штукатурка',
        category: 'finishing',
        inputs: {'area': 15.0},
        results: {'plasterNeeded': 75.0},
        totalCost: 3000.0,
      );

      final foundationCalcs =
          await repository.getCalculationsByCategory('foundation');
      expect(foundationCalcs.length, equals(1));
      expect(foundationCalcs.first.title, equals('Foundation Calc'));

      final finishingCalcs =
          await repository.getCalculationsByCategory('finishing');
      expect(finishingCalcs.length, equals(1));
      expect(finishingCalcs.first.title, equals('Wall Calc'));
    });

    test('deletes calculation correctly', () async {
      await repository.saveCalculation(
        title: 'To Delete',
        calculatorId: 'test',
        calculatorName: 'Test',
        category: 'finishing',
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
        category: 'finishing',
        inputs: {},
        results: {},
        totalCost: 10000.0,
      );

      await repository.saveCalculation(
        title: 'Bathroom Tiles',
        calculatorId: 'bathroom_tile',
        calculatorName: 'Плитка в ванную',
        category: 'finishing',
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
        category: 'foundation',
        inputs: {},
        results: {},
        totalCost: 10000.0,
      );

      await repository.saveCalculation(
        title: 'Calc 2',
        calculatorId: 'test2',
        calculatorName: 'Test 2',
        category: 'foundation',
        inputs: {},
        results: {},
        totalCost: 15000.0,
      );

      await repository.saveCalculation(
        title: 'Calc 3',
        calculatorId: 'test3',
        calculatorName: 'Test 3',
        category: 'finishing',
        inputs: {},
        results: {},
        totalCost: 5000.0,
      );

      final stats = await repository.getStatistics();
      expect(stats['totalCalculations'], equals(3));
      expect(stats['totalCost'], equals(30000.0));
      expect(stats['categoryCount']['foundation'], equals(2));
      expect(stats['categoryCount']['finishing'], equals(1));
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
        category: 'finishing',
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
