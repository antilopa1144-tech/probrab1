// ignore_for_file: avoid_print

/// Генератор калькуляторов для проекта Прораб AI.
///
/// Создаёт все необходимые файлы для нового калькулятора:
/// - Use case в lib/domain/usecases/
/// - Экран в lib/presentation/views/calculator/
/// - Definition V2 (шаблон для ручной интеграции)
/// - Тест в test/domain/usecases/
/// - Ключи локализации для assets/lang/ru.json
///
/// Использование:
///   dart run scripts/calculator_generator.dart <name>
///   dart run scripts/calculator_generator.dart <name> --category walls --fields "area,thickness,layers"
///
/// Примеры:
///   dart run scripts/calculator_generator.dart foam_insulation
///   dart run scripts/calculator_generator.dart tile_grout --category floor --fields "area,jointWidth,depth"
///
/// Опции:
///   --category <category>   Категория калькулятора (walls, floor, foundation, roofing, exterior, interior)
///   --fields <fields>       Список полей через запятую (по умолчанию: area)
///   --dry-run               Показать что будет создано без создания файлов
///   --force                 Перезаписать существующие файлы
library;

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  // Парсинг аргументов
  final name = args[0];

  if (name == '--help' || name == '-h') {
    _printUsage();
    exit(0);
  }

  final categoryIndex = args.indexOf('--category');
  final category = categoryIndex != -1 && args.length > categoryIndex + 1
      ? args[categoryIndex + 1]
      : 'interior';

  final fieldsIndex = args.indexOf('--fields');
  final fieldsStr = fieldsIndex != -1 && args.length > fieldsIndex + 1
      ? args[fieldsIndex + 1]
      : 'area';
  final fields = fieldsStr.split(',').map((f) => f.trim()).toList();

  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');

  print('');
  print('╔════════════════════════════════════════════════════════════╗');
  print('║       ГЕНЕРАТОР КАЛЬКУЛЯТОРОВ - Прораб AI                 ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('');

  // Валидация имени
  if (!_isValidName(name)) {
    print('❌ Ошибка: Имя должно быть в snake_case (например: foam_insulation)');
    exit(1);
  }

  // Генерация имён
  final names = _generateNames(name);

  print('📋 Параметры генерации:');
  print('   Имя калькулятора:  ${names.snakeCase}');
  print('   Класс:             ${names.pascalCase}');
  print('   Категория:         $category');
  print('   Поля:              ${fields.join(", ")}');
  print('');

  if (dryRun) {
    print('🔍 Режим предпросмотра (--dry-run)');
    print('');
  }

  // Определяем файлы для создания
  final filesToCreate = <String, String>{
    'lib/domain/usecases/calculate_${names.snakeCase}.dart':
        _generateUseCase(names, fields),
    'lib/presentation/views/calculator/${names.snakeCase}_calculator_screen.dart':
        _generateScreen(names, category, fields),
    'test/domain/usecases/calculate_${names.snakeCase}_test.dart':
        _generateTest(names, fields),
  };

  // Проверяем существование файлов
  final existingFiles = <String>[];
  for (final path in filesToCreate.keys) {
    if (File(path).existsSync()) {
      existingFiles.add(path);
    }
  }

  if (existingFiles.isNotEmpty && !force && !dryRun) {
    print('⚠️  Следующие файлы уже существуют:');
    for (final file in existingFiles) {
      print('   - $file');
    }
    print('');
    print('Используйте --force для перезаписи.');
    exit(1);
  }

  // Создаём файлы
  print('📁 Создаваемые файлы:');
  for (final entry in filesToCreate.entries) {
    final status = existingFiles.contains(entry.key) ? '(перезапись)' : '(новый)';
    print('   ✓ ${entry.key} $status');

    if (!dryRun) {
      final file = File(entry.key);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }

  // Генерируем локализацию
  print('');
  print('🌐 Ключи локализации для assets/lang/ru.json:');
  final locKeys = _generateLocalizationKeys(names, fields);
  print(locKeys);

  // Генерируем Definition V2
  print('');
  print('📝 Шаблон CalculatorDefinitionV2:');
  final definition = _generateDefinitionV2(names, category, fields);
  print(definition);

  // Инструкции
  print('');
  print('═' * 60);
  print('📌 СЛЕДУЮЩИЕ ШАГИ:');
  print('═' * 60);
  print('');
  print('1. Добавьте ключи локализации в assets/lang/ru.json');
  print('');
  print('2. Создайте CalculatorDefinitionV2 в соответствующем файле:');
  print('   lib/domain/calculators/definitions/<category>/<category>_*.dart');
  print('');
  print('3. Зарегистрируйте definition в списке категории');
  print('');
  print('4. Реализуйте логику расчёта в use case:');
  print('   lib/domain/usecases/calculate_${names.snakeCase}.dart');
  print('');
  print('5. Настройте UI экрана:');
  print('   lib/presentation/views/calculator/${names.snakeCase}_calculator_screen.dart');
  print('');
  print('6. Запустите тесты:');
  print('   flutter test test/domain/usecases/calculate_${names.snakeCase}_test.dart');
  print('');

  if (dryRun) {
    print('ℹ️  Это был предпросмотр. Для создания файлов уберите --dry-run');
  } else {
    print('✅ Генерация завершена!');
  }
}

void _printUsage() {
  print('''
Генератор калькуляторов для Прораб AI

Использование:
  dart run scripts/calculator_generator.dart <name> [options]

Аргументы:
  name                    Имя калькулятора в snake_case (например: foam_insulation)

Опции:
  --category <category>   Категория (walls, floor, foundation, roofing, exterior, interior)
                          По умолчанию: interior
  --fields <fields>       Поля ввода через запятую
                          По умолчанию: area
  --dry-run               Предпросмотр без создания файлов
  --force                 Перезаписать существующие файлы
  --help, -h              Показать справку

Примеры:
  dart run scripts/calculator_generator.dart foam_insulation
  dart run scripts/calculator_generator.dart tile_grout --category floor --fields "area,jointWidth,depth"
  dart run scripts/calculator_generator.dart pool_tile --dry-run

Доступные категории:
  walls       - Стены (штукатурка, обои, панели)
  floor       - Пол (плитка, ламинат, стяжка)
  foundation  - Фундамент (бетон, армирование)
  roofing     - Кровля (черепица, утепление)
  exterior    - Фасад (сайдинг, штукатурка)
  interior    - Интерьер (потолки, перегородки)

Стандартные поля:
  area        - Площадь (м²)
  length      - Длина (м)
  width       - Ширина (м)
  height      - Высота (м)
  thickness   - Толщина (мм)
  layers      - Количество слоёв
  perimeter   - Периметр (м)
''');
}

bool _isValidName(String name) {
  return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
}

/// Класс с различными формами имени
class _Names {
  final String snakeCase;      // foam_insulation
  final String pascalCase;     // FoamInsulation
  final String camelCase;      // foamInsulation
  final String titleCase;      // Foam Insulation
  final String id;             // foam_insulation

  _Names({
    required this.snakeCase,
    required this.pascalCase,
    required this.camelCase,
    required this.titleCase,
    required this.id,
  });
}

_Names _generateNames(String snakeCase) {
  final words = snakeCase.split('_');

  final pascalCase = words.map((w) => w[0].toUpperCase() + w.substring(1)).join();
  final camelCase = words[0] + words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
  final titleCase = words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  return _Names(
    snakeCase: snakeCase,
    pascalCase: pascalCase,
    camelCase: camelCase,
    titleCase: titleCase,
    id: snakeCase,
  );
}

String _generateUseCase(_Names names, List<String> fields) {
  final fieldGetters = fields.map((f) {
    return "    final $f = getInput(inputs, '$f', defaultValue: ${_getDefaultValue(f)});";
  }).join('\n');

  final fieldValidation = fields.where((f) => _isRequiredField(f)).map((f) {
    return '''
    if ($f <= 0) {
      return 'Необходимо указать ${_getFieldLabel(f).toLowerCase()}';
    }''';
  }).join('\n');

  return '''
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор ${names.titleCase.toLowerCase()}.
///
/// Рассчитывает материалы для ${names.titleCase.toLowerCase()}.
///
/// Поля:
${fields.map((f) => '/// - $f: ${_getFieldDescription(f)}').join('\n')}
class Calculate${names.pascalCase} extends BaseCalculator {
  /// Запас на подрезку и отходы (%)
  static const double wastePercent = 10.0;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;
$fieldValidation

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
$fieldGetters

    // TODO: Реализуйте логику расчёта
    // Пример:
    // final materialNeeded = area * consumptionPerSqm * (1 + wastePercent / 100);

    final materialNeeded = ${fields.contains('area') ? 'area' : '0.0'} * 1.0; // Замените на реальный расчёт

    // Поиск цен
    final price = findPrice(priceList, ['${names.snakeCase}', '${names.id}_material']);
    final totalPrice = calculateCost(materialNeeded, price?.price);

    return createResult(
      values: {
${fields.map((f) => "        '$f': $f,").join('\n')}
        'materialNeeded': materialNeeded,
      },
      totalPrice: totalPrice,
    );
  }
}
''';
}

String _generateScreen(_Names names, String category, List<String> fields) {
  final colorMap = {
    'walls': 'CalculatorColors.walls',
    'floor': 'CalculatorColors.floor',
    'foundation': 'CalculatorColors.foundation',
    'roofing': 'CalculatorColors.roofing',
    'exterior': 'CalculatorColors.exterior',
    'interior': 'CalculatorColors.interior',
  };
  final accentColor = colorMap[category] ?? 'CalculatorColors.interior';

  final stateFields = fields.map((f) {
    return '  double _$f = ${_getDefaultValue(f)};';
  }).join('\n');

  final inputsMap = fields.map((f) {
    return "      '$f': _$f,";
  }).join('\n');

  final applyInitialInputs = fields.map((f) {
    return "    if (initial['$f'] != null) _$f = initial['$f']!.clamp(${_getMinValue(f)}, ${_getMaxValue(f)});";
  }).join('\n');

  final getCurrentInputs = fields.map((f) {
    return "      '$f': _$f,";
  }).join('\n');

  final sliderFields = fields.map((f) {
    return '''
        CalculatorSliderField(
          label: _loc.translate('${names.snakeCase}_calc.label.$f'),
          value: _$f,
          min: ${_getMinValue(f)},
          max: ${_getMaxValue(f)},
          suffix: _loc.translate('${_getUnitKey(f)}'),
          accentColor: _accentColor,
          onChanged: (v) {
            setState(() {
              _$f = v;
              _update();
            });
          },
        ),
        const SizedBox(height: 16),''';
  }).join('\n');

  return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_${names.snakeCase}.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Результат расчёта ${names.titleCase.toLowerCase()}
class _${names.pascalCase}Result {
  final double materialNeeded;
${fields.map((f) => '  final double $f;').join('\n')}

  const _${names.pascalCase}Result({
    required this.materialNeeded,
${fields.map((f) => '    required this.$f,').join('\n')}
  });

  factory _${names.pascalCase}Result.fromCalculatorResult(Map<String, double> values) {
    return _${names.pascalCase}Result(
      materialNeeded: values['materialNeeded'] ?? 0,
${fields.map((f) => "      $f: values['$f'] ?? ${_getDefaultValue(f)},").join('\n')}
    );
  }
}

class ${names.pascalCase}CalculatorScreen extends ConsumerStatefulWidget {
  final Map<String, double>? initialInputs;

  const ${names.pascalCase}CalculatorScreen({
    super.key,
    this.initialInputs,
  });

  @override
  ConsumerState<${names.pascalCase}CalculatorScreen> createState() => _${names.pascalCase}CalculatorScreenState();
}

class _${names.pascalCase}CalculatorScreenState extends ConsumerState<${names.pascalCase}CalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('${names.snakeCase}_calc.title');

  // Domain layer calculator
  final _calculator = Calculate${names.pascalCase}();

  // Состояние
$stateFields

  late _${names.pascalCase}Result _result;
  late AppLocalizations _loc;

  static const _accentColor = $accentColor;

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

$applyInitialInputs
  }

  /// Использует domain layer для расчёта
  _${names.pascalCase}Result _calculate() {
    final inputs = <String, double>{
$inputsMap
    };

    final result = _calculator(inputs, []);
    return _${names.pascalCase}Result.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String? get calculatorId => '${names.snakeCase}';

  @override
  Map<String, dynamic>? getCurrentInputs() {
    return {
$getCurrentInputs
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('${names.snakeCase}_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
${fields.map((f) => "    buffer.writeln(_loc.translate('${names.snakeCase}_calc.export.$f')\n        .replaceFirst('{value}', _result.$f.toStringAsFixed(1)));").join('\n')}
    buffer.writeln();
    buffer.writeln(_loc.translate('${names.snakeCase}_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('${names.snakeCase}_calc.export.material_needed')
        .replaceFirst('{value}', _result.materialNeeded.toStringAsFixed(1)));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('${names.snakeCase}_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('${names.snakeCase}_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
${fields.take(2).map((f) => '''
          ResultItem(
            label: _loc.translate('${names.snakeCase}_calc.result.$f').toUpperCase(),
            value: '\${_result.$f.toStringAsFixed(1)} \${_loc.translate('${_getUnitKey(f)}')}',
            icon: ${_getFieldIcon(f)},
          ),''').join('\n')}
          ResultItem(
            label: _loc.translate('${names.snakeCase}_calc.result.material').toUpperCase(),
            value: '\${_result.materialNeeded.toStringAsFixed(1)}',
            icon: Icons.inventory_2,
          ),
        ],
      ),
      children: [
        _buildInputsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('${names.snakeCase}_calc.section.inputs'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 16),
$sliderFields
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('${names.snakeCase}_calc.materials.main'),
        value: '\${_result.materialNeeded.toStringAsFixed(1)} \${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('${names.snakeCase}_calc.materials.main_subtitle'),
        icon: Icons.inventory_2,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('${names.snakeCase}_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      _loc.translate('${names.snakeCase}_calc.tip.1'),
      _loc.translate('${names.snakeCase}_calc.tip.2'),
      _loc.translate('${names.snakeCase}_calc.tip.3'),
    ];

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
''';
}

String _generateTest(_Names names, List<String> fields) {
  final defaultInputs = fields.map((f) {
    return "          '$f': ${_getTestValue(f)},";
  }).join('\n');

  return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_${names.snakeCase}.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('Calculate${names.pascalCase}', () {
    late Calculate${names.pascalCase} calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = Calculate${names.pascalCase}();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('calculates material correctly for standard inputs', () {
        final inputs = {
$defaultInputs
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['materialNeeded'], isNotNull);
        expect(result.values['materialNeeded'], greaterThan(0));
      });

      test('returns all input values in result', () {
        final inputs = {
$defaultInputs
        };

        final result = calculator(inputs, emptyPriceList);

${fields.map((f) => "        expect(result.values['$f'], equals(${_getTestValue(f)}));").join('\n')}
      });
    });

    group('Edge cases', () {
      test('handles minimum values', () {
        final inputs = {
${fields.map((f) => "          '$f': ${_getMinValue(f)}.1,").join('\n')}
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['materialNeeded'], greaterThanOrEqualTo(0));
      });

      test('handles maximum values', () {
        final inputs = {
${fields.map((f) => "          '$f': ${_getMaxValue(f)}.0,").join('\n')}
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['materialNeeded'], isNotNull);
      });
    });

    group('Validation', () {
${fields.where((f) => _isRequiredField(f)).map((f) => '''
      test('throws exception for zero $f', () {
        final inputs = {
${fields.map((field) => "          '$field': ${field == f ? '0.0' : _getTestValue(field)},").join('\n')}
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
''').join('\n')}

      test('throws exception for negative values', () {
        final inputs = {
${fields.map((f) => "          '$f': -1.0,").join('\n')}
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
$defaultInputs
        };
        final priceList = [
          const PriceItem(
            sku: '${names.snakeCase}',
            name: '${names.titleCase}',
            price: 100.0,
            unit: 'шт',
            imageUrl: '',
          ),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
$defaultInputs
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });
  });
}
''';
}

String _generateLocalizationKeys(_Names names, List<String> fields) {
  final fieldLabels = fields.map((f) {
    return '      "$f": "${_getFieldLabel(f)}"';
  }).join(',\n');

  final fieldResults = fields.map((f) {
    return '      "$f": "${_getFieldLabel(f)}"';
  }).join(',\n');

  final fieldExports = fields.map((f) {
    return '      "$f": "${_getFieldLabel(f)}: {value} ${_getUnitLabel(f)}"';
  }).join(',\n');

  return '''
  "${names.snakeCase}_calc": {
    "title": "${names.titleCase}",
    "description": "Расчёт материалов для ${names.titleCase.toLowerCase()}",
    "section": {
      "inputs": "Параметры",
      "materials": "Материалы"
    },
    "label": {
$fieldLabels
    },
    "result": {
$fieldResults,
      "material": "Материал"
    },
    "materials": {
      "main": "Основной материал",
      "main_subtitle": "С учётом запаса 10%"
    },
    "tip": {
      "1": "Добавляйте 10% запас на подрезку",
      "2": "Проверяйте качество материалов",
      "3": "Соблюдайте технологию укладки"
    },
    "export": {
      "title": "═══ ${names.titleCase.toUpperCase()} ═══",
$fieldExports,
      "materials_title": "▸ МАТЕРИАЛЫ",
      "material_needed": "Материал: {value} шт",
      "footer": "Рассчитано в Прораб AI"
    }
  }''';
}

String _generateDefinitionV2(_Names names, String category, List<String> fields) {
  final categoryMap = {
    'walls': 'CalculatorCategory.wallFinishing',
    'floor': 'CalculatorCategory.floor',
    'foundation': 'CalculatorCategory.foundation',
    'roofing': 'CalculatorCategory.roofing',
    'exterior': 'CalculatorCategory.exterior',
    'interior': 'CalculatorCategory.interior',
  };
  final categoryEnum = categoryMap[category] ?? 'CalculatorCategory.interior';

  final fieldsCode = fields.map((f) {
    return '''
        const CalculatorField(
          key: '$f',
          labelKey: 'input.${_getInputLabelKey(f)}',
          unitType: ${_getUnitType(f)},
          inputType: FieldInputType.number,
          defaultValue: ${_getDefaultValue(f)},
          required: ${_isRequiredField(f)},
          order: ${fields.indexOf(f) + 1},
        ),''';
  }).join('\n');

  return '''
  // Добавьте в соответствующий файл definitions:
  // lib/domain/calculators/definitions/$category/${category}_*.dart

  CalculatorDefinitionV2(
    id: '${names.snakeCase}',
    titleKey: 'calculator.${names.snakeCase}.title',
    descriptionKey: 'calculator.${names.snakeCase}.description',
    category: $categoryEnum,
    subCategoryKey: 'subcategory.$category',
    fields: [
$fieldsCode
    ],
    beforeHints: [
      const CalculatorHint(type: HintType.tip, messageKey: 'hint.${names.snakeCase}.tip1'),
    ],
    afterHints: [
      const CalculatorHint(type: HintType.tip, messageKey: 'hint.${names.snakeCase}.tip1'),
    ],
    useCase: Calculate${names.pascalCase}(),
    accentColor: kCalculatorAccentColor,
    complexity: 2,
    popularity: 10,
    tags: [
      'tag.$category',
      '${names.snakeCase}',
    ],
  ),''';
}

// Вспомогательные функции для полей
double _getDefaultValue(String field) {
  switch (field) {
    case 'area': return 20.0;
    case 'length': return 5.0;
    case 'width': return 4.0;
    case 'height': return 2.7;
    case 'thickness': return 10.0;
    case 'layers': return 1.0;
    case 'perimeter': return 18.0;
    case 'jointWidth': return 3.0;
    case 'depth': return 5.0;
    default: return 1.0;
  }
}

double _getMinValue(String field) {
  switch (field) {
    case 'area': return 1.0;
    case 'length': return 0.1;
    case 'width': return 0.1;
    case 'height': return 0.1;
    case 'thickness': return 1.0;
    case 'layers': return 1.0;
    case 'perimeter': return 1.0;
    default: return 0.1;
  }
}

double _getMaxValue(String field) {
  switch (field) {
    case 'area': return 1000.0;
    case 'length': return 100.0;
    case 'width': return 100.0;
    case 'height': return 50.0;
    case 'thickness': return 500.0;
    case 'layers': return 10.0;
    case 'perimeter': return 500.0;
    default: return 100.0;
  }
}

String _getTestValue(String field) {
  switch (field) {
    case 'area': return '20.0';
    case 'length': return '5.0';
    case 'width': return '4.0';
    case 'height': return '2.7';
    case 'thickness': return '10.0';
    case 'layers': return '2.0';
    case 'perimeter': return '18.0';
    default: return '1.0';
  }
}

String _getFieldLabel(String field) {
  switch (field) {
    case 'area': return 'Площадь';
    case 'length': return 'Длина';
    case 'width': return 'Ширина';
    case 'height': return 'Высота';
    case 'thickness': return 'Толщина';
    case 'layers': return 'Слои';
    case 'perimeter': return 'Периметр';
    case 'jointWidth': return 'Ширина шва';
    case 'depth': return 'Глубина';
    default: return field[0].toUpperCase() + field.substring(1);
  }
}

String _getFieldDescription(String field) {
  switch (field) {
    case 'area': return 'площадь поверхности (м²)';
    case 'length': return 'длина (м)';
    case 'width': return 'ширина (м)';
    case 'height': return 'высота (м)';
    case 'thickness': return 'толщина слоя (мм)';
    case 'layers': return 'количество слоёв';
    case 'perimeter': return 'периметр (м)';
    default: return field;
  }
}

String _getUnitKey(String field) {
  switch (field) {
    case 'area': return 'common.sqm';
    case 'length':
    case 'width':
    case 'height':
    case 'perimeter': return 'common.meters';
    case 'thickness':
    case 'jointWidth':
    case 'depth': return 'common.mm';
    case 'layers': return 'common.pcs';
    default: return 'common.pcs';
  }
}

String _getUnitLabel(String field) {
  switch (field) {
    case 'area': return 'м²';
    case 'length':
    case 'width':
    case 'height':
    case 'perimeter': return 'м';
    case 'thickness':
    case 'jointWidth':
    case 'depth': return 'мм';
    case 'layers': return 'шт';
    default: return '';
  }
}

String _getUnitType(String field) {
  switch (field) {
    case 'area': return 'UnitType.squareMeters';
    case 'length':
    case 'width':
    case 'height':
    case 'perimeter': return 'UnitType.meters';
    case 'thickness':
    case 'jointWidth':
    case 'depth': return 'UnitType.millimeters';
    case 'layers': return 'UnitType.pieces';
    default: return 'UnitType.pieces';
  }
}

String _getInputLabelKey(String field) {
  switch (field) {
    case 'area': return 'area';
    case 'length': return 'length';
    case 'width': return 'width';
    case 'height': return 'height';
    case 'thickness': return 'thickness';
    case 'layers': return 'layers';
    case 'perimeter': return 'perimeter';
    default: return field;
  }
}

String _getFieldIcon(String field) {
  switch (field) {
    case 'area': return 'Icons.square_foot';
    case 'length':
    case 'width':
    case 'perimeter': return 'Icons.straighten';
    case 'height': return 'Icons.height';
    case 'thickness':
    case 'depth': return 'Icons.layers';
    case 'layers': return 'Icons.filter_none';
    default: return 'Icons.edit';
  }
}

bool _isRequiredField(String field) {
  return ['area', 'length', 'width', 'height'].contains(field);
}
