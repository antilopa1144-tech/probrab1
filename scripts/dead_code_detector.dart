// ignore_for_file: avoid_print

/// Скрипт поиска мёртвого (неиспользуемого) кода.
///
/// Анализирует:
/// - Неиспользуемые классы
/// - Неиспользуемые функции и методы
/// - Неиспользуемые переменные верхнего уровня
/// - Неиспользуемые провайдеры Riverpod
/// - Устаревшие use cases (без экранов)
///
/// Использование: dart run scripts/dead_code_detector.dart
///
/// Опции:
///   --verbose    Подробный вывод
///   --json       Вывод в JSON формате
///   --strict     Строгий режим (больше проверок)
library;

import 'dart:io';

void main(List<String> args) {
  final verbose = args.contains('--verbose');
  final jsonOutput = args.contains('--json');
  final strictMode = args.contains('--strict');

  if (!jsonOutput) {
    print('🔍 Поиск мёртвого кода...\n');
  }

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('ERROR: Папка lib не найдена!');
    exit(1);
  }

  // 1. Собираем все Dart файлы
  final dartFiles = <DartFile>[];
  _collectDartFiles(libDir, dartFiles);

  if (!jsonOutput) {
    print('Dart файлов для анализа: ${dartFiles.length}');
  }

  // 2. Парсим все файлы
  final allDefinitions = <CodeDefinition>[];
  final allReferences = <String>{};

  for (final file in dartFiles) {
    file.parse();
    allDefinitions.addAll(file.definitions);
    allReferences.addAll(file.references);
  }

  if (!jsonOutput) {
    print('Определений найдено: ${allDefinitions.length}');
    print('Ссылок найдено: ${allReferences.length}');
    print('');
  }

  // 3. Находим неиспользуемые определения
  final unused = <CodeDefinition>[];
  final potentiallyUnused = <CodeDefinition>[];

  for (final def in allDefinitions) {
    // Пропускаем main, build, и другие специальные методы
    if (_isSpecialName(def.name)) continue;

    // Пропускаем публичный API (экспорты)
    if (def.isExported) continue;

    // Пропускаем override методы
    if (def.isOverride) continue;

    // Проверяем использование
    final isUsed = allReferences.contains(def.name);

    if (!isUsed) {
      // Дополнительная проверка: может использоваться через строку
      final usedAsString = dartFiles.any((f) =>
          f.content.contains("'${def.name}'") || f.content.contains('"${def.name}"'));

      if (usedAsString) {
        if (strictMode) {
          potentiallyUnused.add(def);
        }
      } else {
        unused.add(def);
      }
    }
  }

  // 4. Группируем по типу
  final unusedClasses = unused.where((d) => d.type == DefinitionType.classType).toList();
  final unusedFunctions = unused.where((d) => d.type == DefinitionType.function).toList();
  final unusedVariables = unused.where((d) => d.type == DefinitionType.variable).toList();
  final unusedProviders = unused.where((d) => d.type == DefinitionType.provider).toList();

  // 5. Проверяем use cases без экранов
  final orphanUseCases = _findOrphanUseCases(dartFiles);

  // 6. Выводим результаты
  if (jsonOutput) {
    _printJsonOutput(unusedClasses, unusedFunctions, unusedVariables, unusedProviders,
        orphanUseCases, potentiallyUnused);
  } else {
    _printTextOutput(unusedClasses, unusedFunctions, unusedVariables, unusedProviders,
        orphanUseCases, potentiallyUnused, verbose);
  }

  // Exit code
  final totalUnused = unused.length + orphanUseCases.length;
  if (totalUnused > 0) {
    exit(1);
  }
}

void _collectDartFiles(Directory dir, List<DartFile> files) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Пропускаем сгенерированные файлы
      if (entity.path.contains('.g.dart') || entity.path.contains('.freezed.dart')) {
        continue;
      }
      files.add(DartFile(entity));
    }
  }
}

bool _isSpecialName(String name) {
  const specialNames = {
    'main',
    'build',
    'initState',
    'dispose',
    'didChangeDependencies',
    'didUpdateWidget',
    'deactivate',
    'createState',
    'toString',
    'hashCode',
    'operator',
    'noSuchMethod',
    'runtimeType',
    'call',
  };
  return specialNames.contains(name) || name.startsWith('_');
}

List<String> _findOrphanUseCases(List<DartFile> files) {
  final useCases = <String>{};
  final usedUseCases = <String>{};

  // Находим все use cases
  for (final file in files) {
    if (file.file.path.contains('usecases') && file.file.path.contains('calculate_')) {
      final name = file.file.path.split(Platform.pathSeparator).last.replaceAll('.dart', '');
      useCases.add(name);
    }
  }

  // Находим использования везде
  for (final file in files) {
    final filePath = file.file.path;

    for (final useCase in useCases) {
      // Пропускаем сам файл use case
      if (filePath.endsWith('$useCase.dart')) continue;

      // Проверяем прямое использование (импорт или вызов)
      if (file.content.contains(useCase)) {
        usedUseCases.add(useCase);
        continue;
      }

      // Проверяем использование через camelCase имя функции
      // calculate_paint_universal -> calculatePaintUniversal
      final camelCaseName = _snakeToCamelCase(useCase);
      if (file.content.contains(camelCaseName)) {
        usedUseCases.add(useCase);
        continue;
      }

      // Проверяем использование через ID калькулятора
      // calculate_paint_universal -> paint_universal
      final calcId = useCase.replaceFirst('calculate_', '').replaceAll('_v2', '');
      if (file.content.contains("'$calcId'") || file.content.contains('"$calcId"')) {
        usedUseCases.add(useCase);
      }
    }
  }

  // Дополнительно: проверяем CalculatorDefinitionV2 и definitions
  for (final file in files) {
    if (file.file.path.contains('calculators') || file.file.path.contains('definitions')) {
      for (final useCase in useCases) {
        final calcId = useCase.replaceFirst('calculate_', '').replaceAll('_v2', '');
        if (file.content.contains("id: '$calcId'") ||
            file.content.contains('id: "$calcId"') ||
            file.content.contains("'$calcId'") ||
            file.content.contains('"$calcId"')) {
          usedUseCases.add(useCase);
        }
      }
    }
  }

  // Проверяем использование внутри других use cases (вспомогательные функции)
  for (final file in files) {
    if (file.file.path.contains('usecases')) {
      for (final useCase in useCases) {
        // Проверяем импорт этого use case в другом use case
        if (file.content.contains("'$useCase.dart'") ||
            file.content.contains('"$useCase.dart"')) {
          usedUseCases.add(useCase);
        }
      }
    }
  }

  // Также помечаем use cases с тестами как используемые
  final testDir = Directory('test');
  if (testDir.existsSync()) {
    for (final entity in testDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        final testContent = entity.readAsStringSync();
        for (final useCase in useCases) {
          if (testContent.contains(useCase) || testContent.contains(_snakeToCamelCase(useCase))) {
            usedUseCases.add(useCase);
          }
        }
      }
    }
  }

  return useCases.where((uc) => !usedUseCases.contains(uc)).toList();
}

/// Преобразует snake_case в camelCase
String _snakeToCamelCase(String snake) {
  final parts = snake.split('_');
  if (parts.isEmpty) return snake;

  final buffer = StringBuffer(parts.first);
  for (var i = 1; i < parts.length; i++) {
    if (parts[i].isNotEmpty) {
      buffer.write(parts[i][0].toUpperCase());
      buffer.write(parts[i].substring(1));
    }
  }
  return buffer.toString();
}

void _printTextOutput(
  List<CodeDefinition> classes,
  List<CodeDefinition> functions,
  List<CodeDefinition> variables,
  List<CodeDefinition> providers,
  List<String> orphanUseCases,
  List<CodeDefinition> potentiallyUnused,
  bool verbose,
) {
  print('${'═' * 60}');
  print('ОТЧЁТ О МЁРТВОМ КОДЕ');
  print('${'═' * 60}');
  print('');

  var totalUnused = 0;

  if (classes.isNotEmpty) {
    print('НЕИСПОЛЬЗУЕМЫЕ КЛАССЫ (${classes.length}):');
    print('-' * 40);
    for (final def in classes) {
      print('  - ${def.name}');
      if (verbose) {
        print('    Файл: ${def.filePath}:${def.line}');
      }
    }
    print('');
    totalUnused += classes.length;
  }

  if (functions.isNotEmpty) {
    print('НЕИСПОЛЬЗУЕМЫЕ ФУНКЦИИ (${functions.length}):');
    print('-' * 40);
    for (final def in functions) {
      print('  - ${def.name}');
      if (verbose) {
        print('    Файл: ${def.filePath}:${def.line}');
      }
    }
    print('');
    totalUnused += functions.length;
  }

  if (variables.isNotEmpty) {
    print('НЕИСПОЛЬЗУЕМЫЕ ПЕРЕМЕННЫЕ (${variables.length}):');
    print('-' * 40);
    for (final def in variables) {
      print('  - ${def.name}');
      if (verbose) {
        print('    Файл: ${def.filePath}:${def.line}');
      }
    }
    print('');
    totalUnused += variables.length;
  }

  if (providers.isNotEmpty) {
    print('НЕИСПОЛЬЗУЕМЫЕ ПРОВАЙДЕРЫ (${providers.length}):');
    print('-' * 40);
    for (final def in providers) {
      print('  - ${def.name}');
      if (verbose) {
        print('    Файл: ${def.filePath}:${def.line}');
      }
    }
    print('');
    totalUnused += providers.length;
  }

  if (orphanUseCases.isNotEmpty) {
    print('USE CASES БЕЗ ЭКРАНОВ (${orphanUseCases.length}):');
    print('-' * 40);
    for (final uc in orphanUseCases) {
      print('  - $uc');
    }
    print('');
    totalUnused += orphanUseCases.length;
  }

  if (potentiallyUnused.isNotEmpty) {
    print('ПОТЕНЦИАЛЬНО НЕИСПОЛЬЗУЕМЫЕ (${potentiallyUnused.length}):');
    print('-' * 40);
    print('  (могут использоваться через reflection/строки)');
    for (final def in potentiallyUnused.take(10)) {
      print('  ? ${def.name} (${def.filePath})');
    }
    if (potentiallyUnused.length > 10) {
      print('  ... и ещё ${potentiallyUnused.length - 10}');
    }
    print('');
  }

  print('${'═' * 60}');
  if (totalUnused == 0) {
    print('✅ Мёртвый код не обнаружен!');
  } else {
    print('⚠️  Обнаружено элементов мёртвого кода: $totalUnused');
    print('');
    print('💡 Рекомендации:');
    print('   1. Удалите неиспользуемый код');
    print('   2. Или добавьте // ignore: unused_element если код нужен');
    print('   3. Запустите flutter analyze для проверки');
  }
}

void _printJsonOutput(
  List<CodeDefinition> classes,
  List<CodeDefinition> functions,
  List<CodeDefinition> variables,
  List<CodeDefinition> providers,
  List<String> orphanUseCases,
  List<CodeDefinition> potentiallyUnused,
) {
  final toMap = (CodeDefinition d) => {
        'name': d.name,
        'file': d.filePath,
        'line': d.line,
      };

  print('{');
  print('  "unusedClasses": [${classes.map((d) => _mapToJson(toMap(d))).join(', ')}],');
  print('  "unusedFunctions": [${functions.map((d) => _mapToJson(toMap(d))).join(', ')}],');
  print('  "unusedVariables": [${variables.map((d) => _mapToJson(toMap(d))).join(', ')}],');
  print('  "unusedProviders": [${providers.map((d) => _mapToJson(toMap(d))).join(', ')}],');
  print('  "orphanUseCases": [${orphanUseCases.map((s) => '"$s"').join(', ')}],');
  print(
      '  "potentiallyUnused": [${potentiallyUnused.map((d) => _mapToJson(toMap(d))).join(', ')}],');
  print('  "totalUnused": ${classes.length + functions.length + variables.length + providers.length + orphanUseCases.length}');
  print('}');
}

String _mapToJson(Map<String, dynamic> map) {
  final entries = map.entries.map((e) {
    final value = e.value is String ? '"${e.value}"' : e.value;
    return '"${e.key}": $value';
  });
  return '{${entries.join(', ')}}';
}

enum DefinitionType { classType, function, variable, provider }

class CodeDefinition {
  final String name;
  final DefinitionType type;
  final String filePath;
  final int line;
  final bool isExported;
  final bool isOverride;

  CodeDefinition({
    required this.name,
    required this.type,
    required this.filePath,
    required this.line,
    this.isExported = false,
    this.isOverride = false,
  });
}

class DartFile {
  final File file;
  late final String content;
  final definitions = <CodeDefinition>[];
  final references = <String>{};

  DartFile(this.file);

  void parse() {
    content = file.readAsStringSync();
    final lines = content.split('\n');
    final filePath = file.path.replaceAll('\\', '/');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // Проверяем @override на предыдущей строке
      final hasOverride = i > 0 && lines[i - 1].trim() == '@override';

      // Классы
      final classMatch = RegExp(r'^(?:abstract\s+)?class\s+(\w+)').firstMatch(line.trim());
      if (classMatch != null) {
        definitions.add(CodeDefinition(
          name: classMatch.group(1)!,
          type: DefinitionType.classType,
          filePath: filePath,
          line: lineNum,
          isOverride: hasOverride,
        ));
      }

      // Функции верхнего уровня
      final funcMatch =
          RegExp(r'^(?:Future|void|String|int|double|bool|dynamic|List|Map|Set|\w+)\s+(\w+)\s*[<(]')
              .firstMatch(line.trim());
      if (funcMatch != null && !line.contains('class ') && !line.trim().startsWith('return')) {
        final name = funcMatch.group(1)!;
        if (!name.startsWith('_') && name != 'build') {
          definitions.add(CodeDefinition(
            name: name,
            type: DefinitionType.function,
            filePath: filePath,
            line: lineNum,
            isOverride: hasOverride,
          ));
        }
      }

      // Переменные верхнего уровня (final/const/var)
      final varMatch = RegExp(r'^(?:final|const|var)\s+(\w+)\s*=').firstMatch(line.trim());
      if (varMatch != null) {
        final name = varMatch.group(1)!;
        // Проверяем, это провайдер или обычная переменная
        if (line.contains('Provider')) {
          definitions.add(CodeDefinition(
            name: name,
            type: DefinitionType.provider,
            filePath: filePath,
            line: lineNum,
          ));
        } else if (!name.startsWith('_')) {
          definitions.add(CodeDefinition(
            name: name,
            type: DefinitionType.variable,
            filePath: filePath,
            line: lineNum,
          ));
        }
      }
    }

    // Собираем все ссылки (идентификаторы в коде)
    final identifierPattern = RegExp(r'\b([A-Z][a-zA-Z0-9_]*|[a-z][a-zA-Z0-9_]*)\b');
    for (final match in identifierPattern.allMatches(content)) {
      references.add(match.group(1)!);
    }
  }
}
