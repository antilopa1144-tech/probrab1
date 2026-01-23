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
///   --verbose Показать детальную информацию о динамических ключах
library;

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final showFix = args.contains('--fix');
  final strictMode = args.contains('--strict');
  final verbose = args.contains('--verbose');

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
  final dynamicKeys = <String, List<String>>{}; // Ключи с интерполяцией
  final validatedDynamicKeys = <String, List<String>>{}; // Проверенные динамические

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split(Platform.pathSeparator).last;

    // Ищем translate() вызовы с одинарными кавычками (статические ключи)
    final singleQuotePattern = RegExp(r"_loc\.translate\('([^'$]+)'\)");
    for (final match in singleQuotePattern.allMatches(content)) {
      final key = match.group(1)!;
      usedKeys.add(key);
      if (!allKeys.contains(key)) {
        missingKeys.putIfAbsent(fileName, () => []).add(key);
      }
    }

    // Ищем translate() вызовы с двойными кавычками (статические ключи)
    final doubleQuotePattern = RegExp(r'_loc\.translate\("([^"$]+)"\)');
    for (final match in doubleQuotePattern.allMatches(content)) {
      final key = match.group(1)!;
      usedKeys.add(key);
      if (!allKeys.contains(key)) {
        missingKeys.putIfAbsent(fileName, () => []).add(key);
      }
    }

    // Ищем translate() с интерполяцией (динамические ключи)
    // Паттерн: 'prefix.$variable' или 'prefix.${expression}'
    final dynamicSinglePattern =
        RegExp(r"_loc\.translate\('([^']*\$[^']+)'\)");
    for (final match in dynamicSinglePattern.allMatches(content)) {
      final key = match.group(1)!;
      final validationResult = validateDynamicKey(key, allKeys);
      if (validationResult.isValid) {
        validatedDynamicKeys.putIfAbsent(fileName, () => []).add(key);
      } else {
        dynamicKeys
            .putIfAbsent(fileName, () => [])
            .add('$key → ${validationResult.reason}');
      }
    }

    // Ищем translate() с интерполяцией в двойных кавычках
    final dynamicDoublePattern =
        RegExp(r'_loc\.translate\("([^"]*\$[^"]+)"\)');
    for (final match in dynamicDoublePattern.allMatches(content)) {
      final key = match.group(1)!;
      final validationResult = validateDynamicKey(key, allKeys);
      if (validationResult.isValid) {
        validatedDynamicKeys.putIfAbsent(fileName, () => []).add(key);
      } else {
        dynamicKeys
            .putIfAbsent(fileName, () => [])
            .add('$key → ${validationResult.reason}');
      }
    }

    // Ищем ключи в enum'ах (nameKey, descKey, labelKey)
    final lines = content.split('\n');
    final enumKeyPattern = RegExp(r"'([a-z_]+\.[a-z_]+(?:\.[a-z_0-9]+)*)'");
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

  // Показываем непроверенные динамические ключи только если есть проблемы
  final problematicDynamic = dynamicKeys.entries
      .where((e) => e.value.any((v) => v.contains('NOT FOUND')))
      .toList();

  if (problematicDynamic.isNotEmpty) {
    hasErrors = true;
    print('DYNAMIC KEYS WITH ISSUES:');
    print('-' * 60);
    for (final entry in problematicDynamic) {
      print('\n${entry.key}:');
      for (final key in entry.value.where((v) => v.contains('NOT FOUND'))) {
        print('   ⚠ $key');
      }
    }
    print('');
  }

  if (verbose) {
    if (validatedDynamicKeys.isNotEmpty) {
      print('VALIDATED DYNAMIC KEYS:');
      print('-' * 60);
      for (final entry in validatedDynamicKeys.entries) {
        print('\n${entry.key}:');
        for (final key in entry.value.toSet()) {
          print('   ✓ $key');
        }
      }
      print('');
    }

    final okDynamic = dynamicKeys.entries
        .where((e) => e.value.every((v) => !v.contains('NOT FOUND')))
        .toList();
    if (okDynamic.isNotEmpty) {
      print('DYNAMIC KEYS (assumed OK):');
      print('-' * 60);
      for (final entry in okDynamic) {
        print('\n${entry.key}:');
        for (final key in entry.value.toSet()) {
          print('   ~ $key');
        }
      }
      print('');
    }
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

  // Статистика
  final totalDynamic = dynamicKeys.values.expand((e) => e).length +
      validatedDynamicKeys.values.expand((e) => e).length;

  // Итог
  print('=' * 60);
  if (hasErrors) {
    print('Validation FAILED');
    exit(1);
  } else {
    print('Validation PASSED ✓');
    print('   Static keys used: ${usedKeys.length}');
    print('   Dynamic keys found: $totalDynamic');
    print('   Total keys in JSON: ${allKeys.length}');
  }
}

/// Результат валидации динамического ключа
class DynamicKeyValidation {
  final bool isValid;
  final String reason;

  DynamicKeyValidation(this.isValid, this.reason);
}

/// Валидирует динамический ключ с интерполяцией
///
/// Проверяет, что префикс ключа существует в JSON и имеет дочерние ключи.
/// Например: 'roofing_calc.tip.$type' → проверяем что 'roofing_calc.tip.*' существуют
/// Также поддерживает ключи без точки: 'bag_weight.kg$weight' → ищет 'bag_weight.kg20', 'bag_weight.kg25'
DynamicKeyValidation validateDynamicKey(String key, Set<String> allKeys) {
  // Извлекаем статическую часть (до первого $)
  final dollarIndex = key.indexOf(r'$');
  if (dollarIndex == -1) {
    return DynamicKeyValidation(false, 'No interpolation found');
  }

  String prefix = key.substring(0, dollarIndex);
  final originalPrefix = prefix;

  // Убираем trailing dot если есть
  if (prefix.endsWith('.')) {
    prefix = prefix.substring(0, prefix.length - 1);
  }

  if (prefix.isEmpty) {
    // Полностью динамический ключ — не можем проверить
    return DynamicKeyValidation(true, 'Fully dynamic, cannot validate');
  }

  // 1. Проверяем ключи с точкой после префикса: prefix.*
  final matchingWithDot = allKeys.where((k) => k.startsWith('$prefix.')).toList();
  if (matchingWithDot.isNotEmpty) {
    return DynamicKeyValidation(
        true, 'Found ${matchingWithDot.length} keys with prefix "$prefix."');
  }

  // 2. Проверяем ключи БЕЗ точки (например: prefix='bag_weight.kg' → ищем 'bag_weight.kg20')
  // Это для случаев типа 'self_leveling.bag_weight.kg$weightKg' → 'self_leveling.bag_weight.kg20'
  final matchingWithoutDot = allKeys.where((k) =>
      k.startsWith(originalPrefix) && k != originalPrefix).toList();
  if (matchingWithoutDot.isNotEmpty) {
    return DynamicKeyValidation(
        true, 'Found ${matchingWithoutDot.length} keys starting with "$originalPrefix"');
  }

  // 3. Проверяем родительский ключ (может это вложенный объект)
  final parentPrefix = prefix.contains('.')
      ? prefix.substring(0, prefix.lastIndexOf('.'))
      : prefix;
  final parentKeys = allKeys.where((k) => k.startsWith('$parentPrefix.')).toList();
  if (parentKeys.isNotEmpty) {
    return DynamicKeyValidation(
        true, 'Found ${parentKeys.length} keys under parent "$parentPrefix"');
  }

  return DynamicKeyValidation(false, 'Prefix "$prefix" NOT FOUND in JSON');
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
