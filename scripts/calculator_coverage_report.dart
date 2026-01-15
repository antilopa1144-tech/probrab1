// ignore_for_file: avoid_print

/// Скрипт отчёта покрытия калькуляторов.
///
/// Анализирует:
/// - Какие калькуляторы имеют тесты
/// - Покрытие ценами (все регионы)
/// - Покрытие локализацией
/// - Генерирует markdown отчёт
///
/// Использование: dart run scripts/calculator_coverage_report.dart
///
/// Опции:
///   --markdown  Генерировать отчёт в markdown формате
///   --output    Путь для сохранения отчёта (по умолчанию stdout)
library;

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final generateMarkdown = args.contains('--markdown');
  final outputIndex = args.indexOf('--output');
  final outputPath =
      outputIndex != -1 && args.length > outputIndex + 1 ? args[outputIndex + 1] : null;

  print('Анализ покрытия калькуляторов...\n');

  // 1. Собираем все use cases калькуляторов
  final useCasesDir = Directory('lib/domain/usecases');
  final useCaseFiles = useCasesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('calculate_') && f.path.endsWith('.dart'))
      .map((f) => _extractCalculatorName(f.path))
      .toSet();

  print('Use cases найдено: ${useCaseFiles.length}');

  // 2. Собираем все тесты
  final testDir = Directory('test/domain/usecases');
  final testFiles = testDir.existsSync()
      ? testDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('calculate_') && f.path.endsWith('_test.dart'))
          .map((f) => _extractCalculatorName(f.path.replaceAll('_test.dart', '.dart')))
          .toSet()
      : <String>{};

  print('Тестов найдено: ${testFiles.length}');

  // 3. Собираем V2 definitions
  final definitionsDir = Directory('lib/domain/calculators');
  final v2Definitions = <String>{};
  if (definitionsDir.existsSync()) {
    for (final file in definitionsDir.listSync().whereType<File>()) {
      if (file.path.endsWith('_v2.dart') && !file.path.contains('calculator_registry')) {
        v2Definitions.add(_extractCalculatorName(file.path));
      }
    }
  }

  // Также проверяем definitions/index.dart
  final definitionsIndexDir = Directory('lib/domain/calculators/definitions');
  if (definitionsIndexDir.existsSync()) {
    for (final file in definitionsIndexDir.listSync().whereType<File>()) {
      if (file.path.endsWith('.dart') && !file.path.contains('index')) {
        final content = file.readAsStringSync();
        // Считаем количество CalculatorDefinitionV2 в файле
        final matches = RegExp(r'final\s+\w+\s*=\s*CalculatorDefinitionV2').allMatches(content);
        v2Definitions.addAll(matches.map((_) => file.path));
      }
    }
  }

  print('V2 Definitions найдено: ${v2Definitions.length}');

  // 4. Анализируем цены
  final priceFiles = [
    'assets/json/prices_moscow.json',
    'assets/json/prices_spb.json',
    'assets/json/prices_ekaterinburg.json',
    'assets/json/prices_krasnodar.json',
    'assets/json/prices_regions.json',
  ];

  final priceData = <String, List<dynamic>>{};
  final allMaterials = <String>{};

  for (final pricePath in priceFiles) {
    final file = File(pricePath);
    if (file.existsSync()) {
      final region = pricePath.split('prices_').last.split('.').first;
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      priceData[region] = json;
      // Извлекаем SKU материалов
      for (final item in json) {
        if (item is Map<String, dynamic> && item['sku'] != null) {
          allMaterials.add(item['sku'] as String);
        }
      }
    }
  }

  print('Регионов с ценами: ${priceData.length}');
  print('Уникальных материалов: ${allMaterials.length}');

  // 5. Проверяем локализацию
  final locFile = File('assets/lang/ru.json');
  Set<String> locKeys = {};
  if (locFile.existsSync()) {
    final json = jsonDecode(locFile.readAsStringSync()) as Map<String, dynamic>;
    locKeys = _flattenJson(json);
  }

  print('Ключей локализации: ${locKeys.length}');

  // 6. Анализируем покрытие
  final coverage = <String, CalculatorCoverage>{};

  for (final useCase in useCaseFiles) {
    final name = useCase.replaceAll('calculate_', '').replaceAll('_v2', '');
    coverage.putIfAbsent(
      name,
      () => CalculatorCoverage(name: name),
    );
    coverage[name]!.hasUseCase = true;
  }

  for (final test in testFiles) {
    final name = test.replaceAll('calculate_', '').replaceAll('_v2', '');
    coverage.putIfAbsent(
      name,
      () => CalculatorCoverage(name: name),
    );
    coverage[name]!.hasTest = true;
  }

  // Проверяем локализацию для каждого калькулятора
  for (final entry in coverage.entries) {
    final name = entry.key;
    // Ищем ключи, связанные с калькулятором
    final relatedKeys = locKeys.where((k) => k.toLowerCase().contains(name.replaceAll('_', '')));
    entry.value.localizationKeys = relatedKeys.length;
  }

  // 7. Статистика
  final total = coverage.length;
  final withTests = coverage.values.where((c) => c.hasTest).length;
  final withUseCases = coverage.values.where((c) => c.hasUseCase).length;
  final fullyTestedPercent = total > 0 ? (withTests / total * 100).toStringAsFixed(1) : '0';

  // 8. Выводим отчёт
  final buffer = StringBuffer();

  if (generateMarkdown) {
    buffer.writeln('# Отчёт покрытия калькуляторов');
    buffer.writeln();
    buffer.writeln('*Сгенерировано: ${DateTime.now().toIso8601String()}*');
    buffer.writeln();
    buffer.writeln('## Общая статистика');
    buffer.writeln();
    buffer.writeln('| Метрика | Значение |');
    buffer.writeln('|---------|----------|');
    buffer.writeln('| Всего калькуляторов | $total |');
    buffer.writeln('| С use cases | $withUseCases |');
    buffer.writeln('| С тестами | $withTests |');
    buffer.writeln('| Покрытие тестами | $fullyTestedPercent% |');
    buffer.writeln('| Регионов с ценами | ${priceData.length} |');
    buffer.writeln('| Материалов в ценах | ${allMaterials.length} |');
    buffer.writeln('| Ключей локализации | ${locKeys.length} |');
    buffer.writeln();

    // Калькуляторы без тестов
    final noTests = coverage.values.where((c) => !c.hasTest && c.hasUseCase).toList();
    if (noTests.isNotEmpty) {
      buffer.writeln('## Калькуляторы без тестов (${noTests.length})');
      buffer.writeln();
      for (final calc in noTests) {
        buffer.writeln('- `${calc.name}`');
      }
      buffer.writeln();
    }

    // Тесты без use cases (возможно устаревшие)
    final orphanTests = coverage.values.where((c) => c.hasTest && !c.hasUseCase).toList();
    if (orphanTests.isNotEmpty) {
      buffer.writeln('## Тесты без use cases (возможно устаревшие) (${orphanTests.length})');
      buffer.writeln();
      for (final calc in orphanTests) {
        buffer.writeln('- `${calc.name}`');
      }
      buffer.writeln();
    }

    // Детальная таблица
    buffer.writeln('## Детальный отчёт');
    buffer.writeln();
    buffer.writeln('| Калькулятор | Use Case | Тест | Локализация |');
    buffer.writeln('|-------------|:--------:|:----:|:-----------:|');
    final sorted = coverage.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    for (final calc in sorted) {
      final useCaseIcon = calc.hasUseCase ? '✅' : '❌';
      final testIcon = calc.hasTest ? '✅' : '❌';
      final locStatus = calc.localizationKeys > 0 ? '${calc.localizationKeys} keys' : '❌';
      buffer.writeln('| ${calc.name} | $useCaseIcon | $testIcon | $locStatus |');
    }
  } else {
    buffer.writeln('═' * 60);
    buffer.writeln('ОТЧЁТ ПОКРЫТИЯ КАЛЬКУЛЯТОРОВ');
    buffer.writeln('═' * 60);
    buffer.writeln();
    buffer.writeln('ОБЩАЯ СТАТИСТИКА:');
    buffer.writeln('  Всего калькуляторов:    $total');
    buffer.writeln('  С use cases:            $withUseCases');
    buffer.writeln('  С тестами:              $withTests');
    buffer.writeln('  Покрытие тестами:       $fullyTestedPercent%');
    buffer.writeln('  Регионов с ценами:      ${priceData.length}');
    buffer.writeln('  Материалов в ценах:     ${allMaterials.length}');
    buffer.writeln('  Ключей локализации:     ${locKeys.length}');
    buffer.writeln();

    // Калькуляторы без тестов
    final noTests = coverage.values.where((c) => !c.hasTest && c.hasUseCase).toList();
    if (noTests.isNotEmpty) {
      buffer.writeln('КАЛЬКУЛЯТОРЫ БЕЗ ТЕСТОВ (${noTests.length}):');
      buffer.writeln('-' * 40);
      for (final calc in noTests) {
        buffer.writeln('  - ${calc.name}');
      }
      buffer.writeln();
    }

    // Полностью покрытые
    final fullyCovered = coverage.values.where((c) => c.hasTest && c.hasUseCase).toList();
    buffer.writeln('ПОЛНОСТЬЮ ПОКРЫТЫЕ (${fullyCovered.length}):');
    buffer.writeln('-' * 40);
    for (final calc in fullyCovered) {
      buffer.writeln('  ✓ ${calc.name}');
    }
  }

  final report = buffer.toString();

  if (outputPath != null) {
    File(outputPath).writeAsStringSync(report);
    print('\nОтчёт сохранён в: $outputPath');
  } else {
    print('\n$report');
  }

  // Exit code
  final coveragePercent = total > 0 ? withTests / total * 100 : 0;
  if (coveragePercent < 80) {
    print('\n⚠️  Покрытие ниже 80%!');
    exit(1);
  } else {
    print('\n✅ Покрытие в норме ($fullyTestedPercent%)');
  }
}

String _extractCalculatorName(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  return fileName.replaceAll('.dart', '');
}

Set<String> _flattenJson(Map<String, dynamic> json, [String prefix = '']) {
  final keys = <String>{};

  for (final entry in json.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

    if (entry.value is Map<String, dynamic>) {
      keys.addAll(_flattenJson(entry.value as Map<String, dynamic>, key));
    } else {
      keys.add(key);
    }
  }

  return keys;
}

class CalculatorCoverage {
  final String name;
  bool hasUseCase;
  bool hasTest;
  int localizationKeys;

  CalculatorCoverage({
    required this.name,
    this.hasUseCase = false,
    this.hasTest = false,
    this.localizationKeys = 0,
  });
}
