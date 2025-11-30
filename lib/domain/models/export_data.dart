/// Данные для экспорта проекта.
class ExportData {
  /// Название проекта
  final String projectName;

  /// Описание проекта
  final String? projectDescription;

  /// Дата создания
  final DateTime createdAt;

  /// Список расчётов
  final List<ExportCalculation> calculations;

  /// Общая стоимость материалов
  final double totalMaterialCost;

  /// Общая стоимость работ
  final double totalLaborCost;

  /// Общая стоимость
  final double totalCost;

  /// Дополнительные заметки
  final String? notes;

  const ExportData({
    required this.projectName,
    this.projectDescription,
    required this.createdAt,
    required this.calculations,
    required this.totalMaterialCost,
    required this.totalLaborCost,
    required this.totalCost,
    this.notes,
  });

  /// Конвертировать в CSV строки
  List<List<String>> toCsvRows() {
    final rows = <List<String>>[];

    // Заголовок проекта
    rows.add(['Проект', projectName]);
    if (projectDescription != null) {
      rows.add(['Описание', projectDescription!]);
    }
    rows.add(['Дата создания', _formatDate(createdAt)]);
    rows.add([]); // Пустая строка

    // Заголовки таблицы
    rows.add([
      'Калькулятор',
      'Параметр',
      'Значение',
      'Единица',
      'Стоимость материалов',
      'Стоимость работ',
    ]);

    // Данные расчётов
    for (final calc in calculations) {
      rows.add([
        calc.calculatorName,
        '',
        '',
        '',
        calc.materialCost?.toStringAsFixed(2) ?? '',
        calc.laborCost?.toStringAsFixed(2) ?? '',
      ]);

      // Входные данные
      calc.inputs.forEach((key, value) {
        rows.add([
          '',
          key,
          value.toStringAsFixed(2),
          '',
          '',
          '',
        ]);
      });

      // Результаты
      calc.results.forEach((key, value) {
        rows.add([
          '',
          key,
          value.toStringAsFixed(2),
          '',
          '',
          '',
        ]);
      });

      rows.add([]); // Пустая строка между расчётами
    }

    // Итоги
    rows.add(['ИТОГО', '', '', '', '', '']);
    rows.add([
      'Материалы',
      '',
      '',
      '',
      totalMaterialCost.toStringAsFixed(2),
      '',
    ]);
    rows.add([
      'Работы',
      '',
      '',
      '',
      '',
      totalLaborCost.toStringAsFixed(2),
    ]);
    rows.add([
      'ВСЕГО',
      '',
      '',
      '',
      totalCost.toStringAsFixed(2),
      '',
    ]);

    if (notes != null) {
      rows.add([]);
      rows.add(['Заметки', notes!]);
    }

    return rows;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Данные расчёта для экспорта.
class ExportCalculation {
  /// Название калькулятора
  final String calculatorName;

  /// Входные параметры
  final Map<String, double> inputs;

  /// Результаты
  final Map<String, double> results;

  /// Стоимость материалов
  final double? materialCost;

  /// Стоимость работ
  final double? laborCost;

  /// Заметки
  final String? notes;

  const ExportCalculation({
    required this.calculatorName,
    required this.inputs,
    required this.results,
    this.materialCost,
    this.laborCost,
    this.notes,
  });
}
