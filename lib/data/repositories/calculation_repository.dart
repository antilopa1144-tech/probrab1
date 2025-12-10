import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../models/calculation.dart';

/// Репозиторий для работы с историей расчётов
class CalculationRepository {
  CalculationRepository(this.isar);

  /// Инстанс Isar, передаётся через провайдер
  final Isar isar;

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
    final calculation = Calculation()
      ..title = title
      ..calculatorId = calculatorId
      ..calculatorName = calculatorName
      ..category = category
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
    return isar.calculations.where().sortByUpdatedAtDesc().findAll();
  }

  /// Получить расчёты по категории
  Future<List<Calculation>> getCalculationsByCategory(String category) async {
    return isar.calculations
        .filter()
        .categoryEqualTo(category)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// Удалить расчёт
  Future<void> deleteCalculation(int id) async {
    await isar.writeTxn(() async {
      await isar.calculations.delete(id);
    });
  }

  /// Получить расчёт по ID
  Future<Calculation?> getCalculation(int id) async {
    return isar.calculations.get(id);
  }

  /// Поиск расчётов по названию
  Future<List<Calculation>> searchCalculations(String query) async {
    final all = await isar.calculations.where().findAll();
    return all
        .where((c) =>
            c.title.toLowerCase().contains(query.toLowerCase()) ||
            c.calculatorName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Получить общую статистику
  Future<Map<String, dynamic>> getStatistics() async {
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
