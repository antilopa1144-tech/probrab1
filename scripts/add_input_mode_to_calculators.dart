// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, prefer_const_declarations, unnecessary_brace_in_string_interps

import 'dart:io';

/// Скрипт для автоматического добавления альтернативного ввода (InputMode)
/// в калькуляторы, которые работают с площадью
///
/// Использование:
/// dart run scripts/add_input_mode_to_calculators.dart

void main() async {
  print('🔧 Добавление InputMode в калькуляторы...\n');

  final calculatorsDir = Directory('lib/presentation/views/calculator');
  final files = calculatorsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_calculator_screen.dart'))
      .where((f) => !f.path.contains('_template'))
      .where((f) => !f.path.contains('pro_calculator'))
      .toList();

  print('Найдено ${files.length} файлов калькуляторов\n');

  final processed = <String>[];
  final skipped = <String>[];
  final errors = <String>[];

  for (final file in files) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final content = await file.readAsString();

    // Пропускаем если уже есть InputMode
    if (content.contains('InputMode')) {
      skipped.add(fileName);
      continue;
    }

    // Пропускаем если нет работы с площадью
    if (!content.contains('double _area') && !content.contains('final double area')) {
      skipped.add('$fileName (нет площади)');
      continue;
    }

    try {
      final newContent = await processCalculator(file, content, fileName);
      if (newContent != null) {
        await file.writeAsString(newContent);
        processed.add(fileName);
        print('✅ $fileName');
      } else {
        skipped.add('$fileName (не удалось обработать)');
      }
    } catch (e) {
      errors.add('$fileName: $e');
      print('❌ $fileName: $e');
    }
  }

  print('\n' + '═' * 60);
  print('📊 Результаты:');
  print('Обработано: ${processed.length}');
  print('Пропущено: ${skipped.length}');
  print('Ошибки: ${errors.length}');

  if (processed.isNotEmpty) {
    print('\n✅ Обработанные файлы:');
    for (final name in processed) {
      print('  - $name');
    }
  }

  if (skipped.isNotEmpty) {
    print('\n⏭️  Пропущенные файлы:');
    for (final name in skipped) {
      print('  - $name');
    }
  }

  if (errors.isNotEmpty) {
    print('\n❌ Ошибки:');
    for (final error in errors) {
      print('  - $error');
    }
  }

  print('\n🎉 Готово!');
  print('\n📝 Не забудьте:');
  print('   1. Добавить локализацию в assets/lang/ru.json');
  print('   2. Запустить flutter analyze');
  print('   3. Проверить работу калькуляторов');
}

Future<String?> processCalculator(File file, String content, String fileName) async {
  // Определяем тип калькулятора и параметры
  final calcName = fileName.replaceAll('_calculator_screen.dart', '');
  final enumName = _toCamelCase(calcName) + 'InputMode';

  // Определяем какие поля для ввода нужны (length×width или length×height)
  final needsHeight = _needsHeightInput(content);
  final dimension1 = 'length';
  final dimension2 = needsHeight ? 'height' : 'width';

  String newContent = content;

  // 1. Добавляем enum после других enum'ов
  newContent = _addInputModeEnum(newContent, enumName);

  // 2. Добавляем поля для альтернативного ввода
  newContent = _addInputFields(newContent, enumName, dimension1, dimension2);

  // 3. Добавляем метод _getCalculatedArea()
  newContent = _addGetCalculatedAreaMethod(newContent, enumName, dimension1, dimension2);

  // 4. Изменяем _calculate() чтобы использовать _getCalculatedArea()
  newContent = _updateCalculateMethod(newContent);

  // 5. Обновляем _buildAreaCard()
  newContent = _updateBuildAreaCard(newContent, calcName, enumName, dimension1, dimension2);

  return newContent;
}

String _addInputModeEnum(String content, String enumName) {
  // Находим последний enum перед классом Result или State
  final enumPattern = RegExp(r'(enum \w+\s*{[^}]+}\n)', multiLine: true);
  final matches = enumPattern.allMatches(content).toList();

  if (matches.isEmpty) {
    // Если нет enum, добавляем перед классом _Result
    final resultClassPattern = RegExp(r'(class _\w+Result)');
    final match = resultClassPattern.firstMatch(content);
    if (match != null) {
      final insertion = '\n/// Режим ввода площади\nenum $enumName { manual, dimensions }\n\n';
      return content.replaceRange(match.start, match.start, insertion);
    }
    return content;
  }

  // Добавляем после последнего enum
  final lastMatch = matches.last;
  final insertion = '\n/// Режим ввода площади\nenum $enumName { manual, dimensions }\n';
  return content.replaceRange(lastMatch.end, lastMatch.end, insertion);
}

String _addInputFields(String content, String enumName, String dim1, String dim2) {
  // Находим строку с double _area
  final areaPattern = RegExp(r'(\s+double _area = [\d.]+;)');
  final match = areaPattern.firstMatch(content);

  if (match == null) return content;

  final defaultVal1 = dim2 == 'height' ? '5.0' : '5.0';
  final defaultVal2 = dim2 == 'height' ? '2.7' : '4.0';
  final comment1 = ' // м';
  final comment2 = ' // м';

  final insertion = '''
  $enumName _inputMode = $enumName.manual;
  double _area = 20.0;
  double _$dim1 = $defaultVal1;$comment1
  double _$dim2 = $defaultVal2;$comment2''';

  return content.replaceRange(match.start, match.end, insertion);
}

String _addGetCalculatedAreaMethod(String content, String enumName, String dim1, String dim2) {
  // Находим метод _calculate()
  final calculatePattern = RegExp(r'(\s+)((?:_\w+Result|\w+Result) _calculate\(\) {)');
  final match = calculatePattern.firstMatch(content);

  if (match == null) return content;

  final indent = match.group(1)!;
  final methodDef = match.group(2)!;

  final getAreaMethod = '''
${indent}/// Возвращает рассчитанную площадь в зависимости от режима ввода
${indent}double _getCalculatedArea() {
${indent}  if (_inputMode == $enumName.manual) return _area;
${indent}  return _$dim1 * _$dim2;
${indent}}

${indent}$methodDef''';

  return content.replaceFirst(methodDef, getAreaMethod);
}

String _updateCalculateMethod(String content) {
  // Заменяем использование _area на _getCalculatedArea()
  // Ищем внутри метода _calculate()
  final calculateBodyPattern = RegExp(
    r'(_calculate\(\) \{[\s\S]*?)(final area = _area;)',
    multiLine: true,
  );
  final match = calculateBodyPattern.firstMatch(content);

  if (match != null) {
    return content.replaceFirst(
      'final area = _area;',
      'final area = _getCalculatedArea();',
    );
  }

  // Альтернативный подход - если используется inputs['area'] = _area
  final inputsAreaPattern = RegExp(r"(\s+)'area': _area,");
  if (content.contains(inputsAreaPattern)) {
    return content.replaceAllMapped(
      inputsAreaPattern,
      (match) => match.group(0)!.replaceFirst('_area', '_getCalculatedArea()'),
    );
  }

  return content;
}

String _updateBuildAreaCard(String content, String calcName, String enumName, String dim1, String dim2) {
  // Это сложная замена, делаем упрощенную версию
  // Просто добавляем комментарий-подсказку где нужно обновить UI

  final areaCardPattern = RegExp(r'(Widget _buildAreaCard\(\) \{)');
  final match = areaCardPattern.firstMatch(content);

  if (match == null) return content;

  final comment = '''
Widget _buildAreaCard() {
    // TODO: Добавить ModeSelector для переключения между manual и dimensions
    // См. sound_insulation_calculator_screen.dart как пример
    ''';

  return content.replaceFirst(
    'Widget _buildAreaCard() {',
    comment,
  );
}

bool _needsHeightInput(String content) {
  // Если есть wall, ceiling, floor - значит нужна высота
  // Если терраса/балкон - нужна ширина
  if (content.contains('wall') || content.contains('ceiling') || content.contains('Wall')) {
    return true;
  }
  if (content.contains('terrace') || content.contains('balcony') || content.contains('deck')) {
    return false;
  }
  // По умолчанию ширина
  return false;
}

String _toCamelCase(String snakeCase) {
  return snakeCase.split('_').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join('');
}
