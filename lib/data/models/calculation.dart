import 'package:isar_community/isar.dart';

part 'calculation.g.dart';

/// Модель сохранённого расчёта
@Collection()
class Calculation {
  Id id = Isar.autoIncrement;

  /// Название расчёта (задаётся пользователем)
  late String title;

  /// ID калькулятора
  late String calculatorId;

  /// Название калькулятора (для отображения)
  late String calculatorName;

  /// Категория (фундамент, стены, кровля, отделка)
  late String category;

  /// Входные данные в формате JSON
  late String inputsJson;

  /// Результаты в формате JSON
  late String resultsJson;

  /// Стоимость
  late double totalCost;

  /// Дата создания
  late DateTime createdAt;

  /// Дата изменения
  late DateTime updatedAt;

  /// Заметки пользователя
  String? notes;
}
