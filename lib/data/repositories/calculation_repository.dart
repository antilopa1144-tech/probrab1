import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../models/calculation.dart';
import '../../core/migrations/migration_flag_store.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/history_category.dart';

/// Репозиторий для работы с историей расчётов
class CalculationRepository {
  CalculationRepository(
    this.isar, {
    MigrationFlagStore? flagStore,
  }) : _flagStore = flagStore ?? InMemoryMigrationFlagStore();

  /// Инстанс Isar, передаётся через провайдер
  final Isar isar;

  final MigrationFlagStore _flagStore;

  static const int _calculatorIdMigrationVersion = 1;
  static const String _calculatorIdMigrationKey =
      'migration.calculation.calculatorId.version';

  static const int _categoryStorageMigrationVersion = 1;
  static const String _categoryStorageMigrationKey =
      'migration.calculation.categoryStorage.version';

  bool _calculatorIdMigrationDone = false;
  bool _categoryStorageMigrationDone = false;

  Future<void> _ensureCalculatorIdsMigrated() async {
    if (_calculatorIdMigrationDone && _categoryStorageMigrationDone) return;

    if (!_calculatorIdMigrationDone) {
      final currentVersion = await _flagStore.getInt(_calculatorIdMigrationKey);
      if (currentVersion != null &&
          currentVersion >= _calculatorIdMigrationVersion) {
        _calculatorIdMigrationDone = true;
      } else {
        await migrateLegacyCalculatorIds();
        await _flagStore.setInt(
          _calculatorIdMigrationKey,
          _calculatorIdMigrationVersion,
        );
        _calculatorIdMigrationDone = true;
      }
    }

    if (!_categoryStorageMigrationDone) {
      final categoryVersion =
          await _flagStore.getInt(_categoryStorageMigrationKey);
      if (categoryVersion != null &&
          categoryVersion >= _categoryStorageMigrationVersion) {
        _categoryStorageMigrationDone = true;
      } else {
        await migrateCategoryStorage();
        await _flagStore.setInt(
          _categoryStorageMigrationKey,
          _categoryStorageMigrationVersion,
        );
        _categoryStorageMigrationDone = true;
      }
    }
  }

  /// One-time migration: normalize `Calculation.category` to a stable enum name
  /// (`foundation`, `walls`, `roofing`, `finishing`) so UI can localize it.
  Future<int> migrateCategoryStorage() async {
    return isar.writeTxn(() async {
      final all = await isar.calculations.where().findAll();
      final changed = <Calculation>[];

      for (final calculation in all) {
        var mutated = false;
        final canonicalId =
            CalculatorIdMigration.canonicalize(calculation.calculatorId);
        if (canonicalId != calculation.calculatorId) {
          calculation.calculatorId = canonicalId;
          mutated = true;
        }

        final category = HistoryCategoryResolver.fromCalculatorId(
          calculation.calculatorId,
          fallbackStoredCategory: calculation.category,
        );
        final stored = calculation.category.trim();
        final nextCategory = category.name;

        if (stored != nextCategory) {
          calculation.category = nextCategory;
          mutated = true;
        }

        if (mutated) {
          changed.add(calculation);
        }
      }

      for (final calculation in changed) {
        await isar.calculations.put(calculation);
      }

      return changed.length;
    });
  }

  /// One-time migration for stored legacy calculator IDs.
  ///
  /// Updates existing rows in Isar to use canonical IDs.
  Future<int> migrateLegacyCalculatorIds() async {
    return isar.writeTxn(() async {
      final all = await isar.calculations.where().findAll();
      final changed = <Calculation>[];

      for (final calculation in all) {
        final canonical =
            CalculatorIdMigration.canonicalize(calculation.calculatorId);
        if (canonical != calculation.calculatorId) {
          calculation.calculatorId = canonical;
          changed.add(calculation);
        }
      }

      for (final calculation in changed) {
        await isar.calculations.put(calculation);
      }

      return changed.length;
    });
  }

  /// Сохранить новый расчёт
  Future<void> saveCalculation({
    required String title,
    required String calculatorId,
    required String calculatorName,
    required String category,
    required Map<String, double> inputs,
    required Map<String, double> results,
    required double totalCost,
    String? notes,
  }) async {
    await _ensureCalculatorIdsMigrated();

    final canonicalCalculatorId =
        CalculatorIdMigration.canonicalize(calculatorId);
    final historyCategory = HistoryCategoryResolver.fromCalculatorId(
      canonicalCalculatorId,
      fallbackStoredCategory: category,
    );
    final calculation = Calculation()
      ..title = title
      ..calculatorId = canonicalCalculatorId
      ..calculatorName = calculatorName
      ..category = historyCategory.name
      ..inputsJson = jsonEncode(inputs)
      ..resultsJson = jsonEncode(results)
      ..totalCost = totalCost
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..notes = notes;

    await isar.writeTxn(() async {
      await isar.calculations.put(calculation);
    });
  }

  /// Обновить существующий расчёт
  Future<void> updateCalculation(
    int id, {
    String? title,
    Map<String, double>? inputs,
    Map<String, double>? results,
    double? totalCost,
    String? notes,
  }) async {
    await _ensureCalculatorIdsMigrated();
    final calculation = await isar.calculations.get(id);

    if (calculation == null) return;

    if (title != null) calculation.title = title;
    if (inputs != null) calculation.inputsJson = jsonEncode(inputs);
    if (results != null) calculation.resultsJson = jsonEncode(results);
    if (totalCost != null) calculation.totalCost = totalCost;
    if (notes != null) calculation.notes = notes;

    calculation.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.calculations.put(calculation);
    });
  }

  /// Получить все расчёты
  Future<List<Calculation>> getAllCalculations() async {
    await _ensureCalculatorIdsMigrated();
    return isar.calculations.where().sortByUpdatedAtDesc().findAll();
  }

  /// Получить расчёты по категории
  Future<List<Calculation>> getCalculationsByCategory(String category) async {
    await _ensureCalculatorIdsMigrated();
    final parsed = HistoryCategoryResolver.tryParse(category);
    final normalized =
        (parsed == null || parsed == HistoryCategory.all) ? category : parsed.name;
    return isar.calculations
        .filter()
        .categoryEqualTo(normalized)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// Удалить расчёт
  Future<void> deleteCalculation(int id) async {
    await _ensureCalculatorIdsMigrated();
    await isar.writeTxn(() async {
      await isar.calculations.delete(id);
    });
  }

  /// Получить расчёт по ID
  Future<Calculation?> getCalculation(int id) async {
    await _ensureCalculatorIdsMigrated();
    return isar.calculations.get(id);
  }

  /// Поиск расчётов по названию
  Future<List<Calculation>> searchCalculations(String query) async {
    await _ensureCalculatorIdsMigrated();
    final all = await isar.calculations.where().findAll();
    return all
        .where((c) =>
            c.title.toLowerCase().contains(query.toLowerCase()) ||
            c.calculatorName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Получить общую статистику
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureCalculatorIdsMigrated();
    final all = await isar.calculations.where().findAll();

    double totalCost = 0;
    final categoryCount = <String, int>{};

    for (final calc in all) {
      totalCost += calc.totalCost;
      categoryCount[calc.category] = (categoryCount[calc.category] ?? 0) + 1;
    }

    return {
      'totalCalculations': all.length,
      'totalCost': totalCost,
      'categoryCount': categoryCount,
      'lastUpdate': all.isNotEmpty ? all.first.updatedAt : null,
    };
  }

  void getMaterialPrice(String s) {}

  /// Закрыть базу данных (для тестирования)
  Future<void> close({bool deleteFromDisk = false}) async {
    await isar.close(deleteFromDisk: deleteFromDisk);
  }
}
