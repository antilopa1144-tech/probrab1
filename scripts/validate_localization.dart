// ignore_for_file: avoid_print

/// Скрипт валидации ключей локализации.
///
/// Проверяет, что все ключи, используемые в коде через _loc.translate(),
/// существуют в файле ru.json.
///
/// Использование: dart run scripts/validate_localization.dart
///
/// Опции:
///   --fix     Показать предложения по исправлению
///   --strict  Также проверять неиспользуемые ключи в JSON
library;

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final showFix = args.contains('--fix');
  final strictMode = args.contains('--strict');

  print('Validating localization keys...\n');

  // Загружаем JSON
  final jsonFile = File('assets/lang/ru.json');
  if (!jsonFile.existsSync()) {
    print('ERROR: ru.json not found!');
    exit(1);
  }

  final Map<String, dynamic> json = jsonDecode(jsonFile.readAsStringSync());
  final allKeys = flattenJson(json);
  print('Keys in ru.json: ${allKeys.length}');

  // Ищем все файлы калькуляторов
  final calculatorDir = Directory('lib/presentation/views/calculator');
  if (!calculatorDir.existsSync()) {
    print('ERROR: Calculator directory not found!');
    exit(1);
  }

  final dartFiles = calculatorDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('_template'))
      .toList();

  print('Dart files found: ${dartFiles.length}\n');

  final usedKeys = <String>{};
  final missingKeys = <String, List<String>>{};

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final lines = content.split('\n');

    // Ищем translate() вызовы с одинарными кавычками
    final singleQuotePattern = RegExp(r"_loc\.translate\('([^']+)'\)");
    for (final match in singleQuotePattern.allMatches(content)) {
      final key = match.group(1)!;
      usedKeys.add(key);
      if (!allKeys.contains(key)) {
        missingKeys.putIfAbsent(fileName, () => []).add(key);
      }
    }

    // Ищем translate() вызовы с двойными кавычками
    final doubleQuotePattern = RegExp(r'_loc\.translate\("([^"]+)"\)');
    for (final match in doubleQuotePattern.allMatches(content)) {
      final key = match.group(1)!;
      usedKeys.add(key);
      if (!allKeys.contains(key)) {
        missingKeys.putIfAbsent(fileName, () => []).add(key);
      }
    }

    // Ищем ключи в enum'ах (nameKey, descKey, labelKey)
    final enumKeyPattern = RegExp(r"'([a-z_]+\.[a-z_]+(?:\.[a-z_]+)*)'");
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('nameKey') ||
          line.contains('descKey') ||
          line.contains('labelKey')) {
        for (final match in enumKeyPattern.allMatches(line)) {
          final key = match.group(1)!;
          if (key.contains('.') &&
              !key.startsWith('Icons.') &&
              !key.startsWith('Colors.')) {
            usedKeys.add(key);
            if (!allKeys.contains(key)) {
              missingKeys
                  .putIfAbsent(fileName, () => [])
                  .add('$key (enum, line ${i + 1})');
            }
          }
        }
      }
    }
  }

  // Отчёт
  var hasErrors = false;

  if (missingKeys.isNotEmpty) {
    hasErrors = true;
    print('MISSING KEYS:');
    print('-' * 60);
    for (final entry in missingKeys.entries) {
      print('\n${entry.key}:');
      for (final key in entry.value.toSet()) {
        print('   - $key');
      }
    }
    print('');
  }

  if (strictMode) {
    final unusedKeys = allKeys.where((k) => !usedKeys.contains(k)).toList();
    if (unusedKeys.isNotEmpty) {
      print('UNUSED KEYS (${unusedKeys.length}):');
      print('-' * 60);
      for (final key in unusedKeys.take(20)) {
        print('   - $key');
      }
      if (unusedKeys.length > 20) {
        print('   ... and ${unusedKeys.length - 20} more');
      }
      print('');
    }
  }

  if (showFix && missingKeys.isNotEmpty) {
    print('SUGGESTED FIXES:');
    print('-' * 60);
    print('Add these keys to ru.json:\n');

    final allMissing = missingKeys.values
        .expand((e) => e)
        .map((e) => e.split(' ').first)
        .toSet();
    for (final key in allMissing) {
      print('"$key": "TODO",');
    }
    print('');
  }

  // Итог
  print('=' * 60);
  if (hasErrors) {
    print('Validation FAILED');
    exit(1);
  } else {
    print('Validation PASSED');
    print('   Used keys: ${usedKeys.length}');
    print('   Total keys in JSON: ${allKeys.length}');
  }
}

/// Преобразует вложенный JSON в плоский список ключей
Set<String> flattenJson(Map<String, dynamic> json, [String prefix = '']) {
  final keys = <String>{};

  for (final entry in json.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

    if (entry.value is Map<String, dynamic>) {
      keys.addAll(flattenJson(entry.value as Map<String, dynamic>, key));
    } else {
      keys.add(key);
    }
  }

  return keys;
}
