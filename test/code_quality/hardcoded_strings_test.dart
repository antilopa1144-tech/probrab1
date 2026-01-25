import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No hardcoded Cyrillic text in Dart files', () {
    final roots = [
      Directory('lib/presentation/views/calculator'),
      Directory('lib/presentation/widgets'),
    ];
    final russianPattern = RegExp(
      "'[\\u0400-\\u04FF][^']*'|\"[\\u0400-\\u04FF][^\"]*\"",
    );

    // Разрешённые короткие технические строки (ключи локализации, единицы измерения)
    final allowedShortStrings = <String>{
      'м', 'м²', 'м³', 'кг', 'г', 'л', 'мл', 'шт', 'см', 'мм',
      'геометрия', 'материал', 'проем', 'параметр', 'опци',
      'гипс', 'цемент', 'краск', 'дерев', 'стен', 'пол', 'потолок',
      'площадь', 'мешк', 'вес', 'объем', 'количество', 'стоимость',
    };

    final excludedFiles = <String>{
      'electrical_calculator_screen.dart',
      'gasblock_calculator_screen.dart',
      'gypsum_calculator_screen.dart',
      'plaster_calculator_screen.dart',
      'putty_calculator_screen_state.dart',
      'self_leveling_floor_calculator_screen.dart',
      'terrace_calculator_screen.dart',
      'three_d_panels_calculator_screen.dart',
      'tile_adhesive_calculator_screen.dart',
      'tile_calculator_screen.dart',
      'underfloor_heating_calculator_screen.dart',
      'wallpaper_calculator_screen.dart',
      'wood_lining_calculator_screen.dart',
      'modern_calculator_catalog_screen_v2.dart',
      'premium_badge.dart',
      'premium_lock_dialog.dart',
      // Технические обозначения марок бетона/стяжки (М100-М400)
      'concrete_universal_calculator_screen.dart',
      'screed_unified_calculator_screen.dart',
      'linoleum_calculator_screen.dart', // TODO: нужна локализация
    };

    final violations = <String>[];

    for (final root in roots) {
      if (!root.existsSync()) continue;
      for (final file in root.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.contains('.g.dart')) continue;
        if (file.path.contains('localization')) continue;
        // Исключаем example/demo файлы и готовые виджеты с дефолтными лейблами
        if (file.path.contains('example_calculator.dart')) continue;
        if (file.path.contains('dynamic_list.dart')) continue;
        if (excludedFiles.any((name) => file.path.endsWith(name))) continue;

        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
            continue;
          }

          final matches = russianPattern.allMatches(line);
          for (final match in matches) {
            final matchText = match.group(0)!;
            // Извлекаем строку без кавычек
            final stringContent = matchText.substring(1, matchText.length - 1);

            // Пропускаем разрешённые короткие технические строки
            if (allowedShortStrings.contains(stringContent)) {
              continue;
            }

            // Пропускаем assertion messages (assert(..., 'сообщение'))
            if (trimmed.contains('assert(') || trimmed.contains('throw ')) {
              continue;
            }

            // Пропускаем дефолтные лейблы в готовых виджетах (RoomDimensionsFields и т.д.)
            // Эти лейблы используются как значения по умолчанию и могут быть переопределены
            if (line.contains('label:') && (
                stringContent.contains('Длина') ||
                stringContent.contains('Ширина') ||
                stringContent.contains('Высота')
            )) {
              continue;
            }

            violations.add('${file.path}:${i + 1}: $matchText');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Hardcoded Cyrillic strings found:\n'
          '${violations.take(20).join("\n")}',
    );
  });
}
