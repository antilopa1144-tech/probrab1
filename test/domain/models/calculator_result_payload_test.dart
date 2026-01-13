import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_result_payload.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

void main() {
  group('CalculatorResultPayload', () {
    test('создаётся с обязательными параметрами', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'gypsum',
        calculatorName: 'Гипсокартон',
        inputs: {'area': 20.0, 'layers': 2.0},
        results: {'gkl_sheets': 10.0, 'screws': 500.0},
      );

      expect(payload.calculatorId, 'gypsum');
      expect(payload.calculatorName, 'Гипсокартон');
      expect(payload.inputs, {'area': 20.0, 'layers': 2.0});
      expect(payload.results, {'gkl_sheets': 10.0, 'screws': 500.0});
      expect(payload.materialCost, isNull);
      expect(payload.laborCost, isNull);
      expect(payload.materials, isNull);
      expect(payload.notes, isNull);
    });

    test('создаётся со всеми параметрами', () {
      final materials = [
        ProjectMaterial()
          ..name = 'ГКЛ'
          ..quantity = 10.0
          ..unit = 'лист'
          ..pricePerUnit = 500.0,
      ];

      final payload = CalculatorResultPayload(
        calculatorId: 'osb',
        calculatorName: 'OSB плиты',
        inputs: {'width': 5.0, 'length': 4.0},
        results: {'sheets': 3.0},
        materialCost: 1500.0,
        laborCost: 500.0,
        materials: materials,
        notes: 'Для пола',
      );

      expect(payload.calculatorId, 'osb');
      expect(payload.calculatorName, 'OSB плиты');
      expect(payload.materialCost, 1500.0);
      expect(payload.laborCost, 500.0);
      expect(payload.materials, materials);
      expect(payload.notes, 'Для пола');
    });

    test('toProjectCalculation конвертирует в ProjectCalculation', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'brick',
        calculatorName: 'Кирпич',
        inputs: {'area': 15.0, 'height': 2.5},
        results: {'bricks': 1000.0, 'mortar': 50.0},
        materialCost: 25000.0,
        laborCost: 10000.0,
        notes: 'Наружная стена',
      );

      final calculation = payload.toProjectCalculation();

      expect(calculation.calculatorId, 'brick');
      expect(calculation.name, 'Кирпич');
      expect(calculation.materialCost, 25000.0);
      expect(calculation.laborCost, 10000.0);
      expect(calculation.notes, 'Наружная стена');
    });

    test('toProjectCalculation сохраняет inputs', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'tile',
        calculatorName: 'Плитка',
        inputs: {'width': 3.0, 'length': 4.0, 'reserve': 10.0},
        results: {'tiles': 15.0},
      );

      final calculation = payload.toProjectCalculation();

      // Проверяем что inputs были сохранены через inputsMap
      expect(calculation.inputsMap.length, 3);
      expect(calculation.inputsMap['width'], 3.0);
      expect(calculation.inputsMap['length'], 4.0);
      expect(calculation.inputsMap['reserve'], 10.0);
    });

    test('toProjectCalculation сохраняет results', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'paint',
        calculatorName: 'Краска',
        inputs: {'area': 50.0},
        results: {'liters': 5.0, 'cans': 2.0},
      );

      final calculation = payload.toProjectCalculation();

      // Проверяем что results были сохранены через resultsMap
      expect(calculation.resultsMap.length, 2);
      expect(calculation.resultsMap['liters'], 5.0);
      expect(calculation.resultsMap['cans'], 2.0);
    });

    test('toProjectCalculation создаёт пустой список materials если null', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'wallpaper',
        calculatorName: 'Обои',
        inputs: {'area': 30.0},
        results: {'rolls': 4.0},
        materials: null,
      );

      final calculation = payload.toProjectCalculation();

      expect(calculation.materials, isEmpty);
    });

    test('toProjectCalculation сохраняет materials', () {
      final materials = [
        ProjectMaterial()
          ..name = 'Обои'
          ..quantity = 4.0
          ..unit = 'рулон'
          ..pricePerUnit = 1200.0,
        ProjectMaterial()
          ..name = 'Клей'
          ..quantity = 2.0
          ..unit = 'кг'
          ..pricePerUnit = 300.0,
      ];

      final payload = CalculatorResultPayload(
        calculatorId: 'wallpaper',
        calculatorName: 'Обои',
        inputs: {'area': 30.0},
        results: {'rolls': 4.0},
        materials: materials,
      );

      final calculation = payload.toProjectCalculation();

      expect(calculation.materials.length, 2);
      expect(calculation.materials[0].name, 'Обои');
      expect(calculation.materials[1].name, 'Клей');
    });

    test('создаётся с пустыми inputs и results', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'custom',
        calculatorName: 'Пользовательский',
        inputs: {},
        results: {},
      );

      expect(payload.inputs, isEmpty);
      expect(payload.results, isEmpty);

      final calculation = payload.toProjectCalculation();
      expect(calculation.inputsMap, isEmpty);
      expect(calculation.resultsMap, isEmpty);
    });

    test('обрабатывает нулевые значения стоимости', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'test',
        calculatorName: 'Тест',
        inputs: {'value': 1.0},
        results: {'output': 2.0},
        materialCost: 0.0,
        laborCost: 0.0,
      );

      final calculation = payload.toProjectCalculation();

      expect(calculation.materialCost, 0.0);
      expect(calculation.laborCost, 0.0);
    });

    test('обрабатывает дробные значения', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'precision',
        calculatorName: 'Точный',
        inputs: {'width': 3.14159, 'height': 2.71828},
        results: {'area': 8.539728},
      );

      expect(payload.inputs['width'], 3.14159);
      expect(payload.inputs['height'], 2.71828);
      expect(payload.results['area'], 8.539728);
    });

    test('обрабатывает отрицательные значения стоимости', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'discount',
        calculatorName: 'Скидка',
        inputs: {'amount': 100.0},
        results: {'discount': 10.0},
        materialCost: -500.0, // скидка
        laborCost: -100.0,
      );

      final calculation = payload.toProjectCalculation();

      expect(calculation.materialCost, -500.0);
      expect(calculation.laborCost, -100.0);
    });

    test('обрабатывает большие значения', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'large',
        calculatorName: 'Большой проект',
        inputs: {'area': 1000000.0},
        results: {'materials': 9999999.0},
        materialCost: 1000000000.0,
      );

      expect(payload.inputs['area'], 1000000.0);
      expect(payload.results['materials'], 9999999.0);
      expect(payload.materialCost, 1000000000.0);
    });

    test('обрабатывает unicode в названиях', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'unicode',
        calculatorName: 'Калькулятор',
        inputs: {'площадь': 20.0},
        results: {'материалы': 10.0},
        notes: 'Примечание',
      );

      expect(payload.calculatorName, 'Калькулятор');
      expect(payload.inputs['площадь'], 20.0);
      expect(payload.notes, 'Примечание');
    });

    test('materials сохраняют totalCost', () {
      final materials = [
        ProjectMaterial()
          ..name = 'Материал'
          ..quantity = 5.0
          ..unit = 'шт'
          ..pricePerUnit = 100.0,
      ];

      final payload = CalculatorResultPayload(
        calculatorId: 'test',
        calculatorName: 'Тест',
        inputs: {'x': 1.0},
        results: {'y': 2.0},
        materials: materials,
      );

      final calculation = payload.toProjectCalculation();

      expect(calculation.materials[0].totalCost, 500.0);
    });
  });

  group('CalculatorResultPayload - Дополнительные тесты покрытия', () {
    test('создаётся только с обязательными полями без materials', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'simple',
        calculatorName: 'Простой',
        inputs: {'x': 1.0},
        results: {'y': 2.0},
      );

      expect(payload.calculatorId, 'simple');
      expect(payload.calculatorName, 'Простой');
      expect(payload.inputs['x'], 1.0);
      expect(payload.results['y'], 2.0);
      expect(payload.materials, isNull);
    });

    test('toProjectCalculation сохраняет все поля корректно', () {
      final materials = [
        ProjectMaterial()
          ..name = 'Доска'
          ..quantity = 10.0
          ..unit = 'м'
          ..pricePerUnit = 500.0,
        ProjectMaterial()
          ..name = 'Гвозди'
          ..quantity = 100.0
          ..unit = 'шт'
          ..pricePerUnit = 2.0,
      ];

      final payload = CalculatorResultPayload(
        calculatorId: 'wood',
        calculatorName: 'Деревянные работы',
        inputs: {'length': 20.0, 'width': 10.0},
        results: {'boards': 10.0, 'nails': 100.0},
        materialCost: 5200.0,
        laborCost: 3000.0,
        materials: materials,
        notes: 'Важные заметки',
      );

      final calc = payload.toProjectCalculation();

      expect(calc.calculatorId, 'wood');
      expect(calc.name, 'Деревянные работы');
      expect(calc.materialCost, 5200.0);
      expect(calc.laborCost, 3000.0);
      expect(calc.notes, 'Важные заметки');
      expect(calc.materials.length, 2);
      expect(calc.materials[0].name, 'Доска');
      expect(calc.materials[1].name, 'Гвозди');
    });

    test('toProjectCalculation с нулевыми стоимостями', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'free',
        calculatorName: 'Бесплатный',
        inputs: {'value': 1.0},
        results: {'output': 1.0},
        materialCost: 0.0,
        laborCost: 0.0,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.materialCost, 0.0);
      expect(calc.laborCost, 0.0);
    });

    test('toProjectCalculation с пустыми inputs и results', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'empty',
        calculatorName: 'Пустой',
        inputs: {},
        results: {},
      );

      final calc = payload.toProjectCalculation();

      expect(calc.inputsMap, isEmpty);
      expect(calc.resultsMap, isEmpty);
    });

    test('toProjectCalculation с множеством inputs', () {
      final inputs = Map<String, double>.fromIterable(
        List.generate(15, (i) => 'param_$i'),
        value: (key) => double.parse(key.toString().split('_').last),
      );

      final payload = CalculatorResultPayload(
        calculatorId: 'complex',
        calculatorName: 'Сложный',
        inputs: inputs,
        results: {'total': 100.0},
      );

      final calc = payload.toProjectCalculation();

      expect(calc.inputsMap.length, 15);
      expect(calc.inputsMap.containsKey('param_0'), isTrue);
      expect(calc.inputsMap.containsKey('param_14'), isTrue);
    });

    test('toProjectCalculation с множеством results', () {
      final results = Map<String, double>.fromIterable(
        List.generate(10, (i) => 'result_$i'),
        value: (key) => double.parse(key.toString().split('_').last) * 10,
      );

      final payload = CalculatorResultPayload(
        calculatorId: 'multi',
        calculatorName: 'Мульти',
        inputs: {'input': 1.0},
        results: results,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.resultsMap.length, 10);
      expect(calc.resultsMap['result_0'], 0.0);
      expect(calc.resultsMap['result_9'], 90.0);
    });

    test('toProjectCalculation с очень большими значениями', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'huge',
        calculatorName: 'Огромный проект',
        inputs: {'area': 1000000.0},
        results: {'materials': 999999999.0},
        materialCost: 1000000000.0,
        laborCost: 500000000.0,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.inputsMap['area'], 1000000.0);
      expect(calc.resultsMap['materials'], 999999999.0);
      expect(calc.materialCost, 1000000000.0);
      expect(calc.laborCost, 500000000.0);
    });

    test('toProjectCalculation с очень маленькими значениями', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'tiny',
        calculatorName: 'Крошечный',
        inputs: {'length': 0.001},
        results: {'amount': 0.00001},
        materialCost: 0.01,
        laborCost: 0.001,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.inputsMap['length'], closeTo(0.001, 0.0001));
      expect(calc.resultsMap['amount'], closeTo(0.00001, 0.000001));
      expect(calc.materialCost, closeTo(0.01, 0.001));
      expect(calc.laborCost, closeTo(0.001, 0.0001));
    });

    test('toProjectCalculation с отрицательными значениями', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'negative',
        calculatorName: 'Отрицательный',
        inputs: {'value': -10.0},
        results: {'result': -20.0},
        materialCost: -100.0,
        laborCost: -50.0,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.inputsMap['value'], -10.0);
      expect(calc.resultsMap['result'], -20.0);
      expect(calc.materialCost, -100.0);
      expect(calc.laborCost, -50.0);
    });

    test('toProjectCalculation с notes null', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'no_notes',
        calculatorName: 'Без заметок',
        inputs: {'x': 1.0},
        results: {'y': 2.0},
        notes: null,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.notes, isNull);
    });

    test('toProjectCalculation с notes пустой строкой', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'empty_notes',
        calculatorName: 'Пустые заметки',
        inputs: {'x': 1.0},
        results: {'y': 2.0},
        notes: '',
      );

      final calc = payload.toProjectCalculation();

      expect(calc.notes, '');
    });

    test('toProjectCalculation с длинными notes', () {
      final longNotes = 'Очень ' * 100 + 'длинные заметки';

      final payload = CalculatorResultPayload(
        calculatorId: 'long_notes',
        calculatorName: 'Длинные заметки',
        inputs: {'x': 1.0},
        results: {'y': 2.0},
        notes: longNotes,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.notes, longNotes);
      expect(calc.notes!.length, greaterThan(500));
    });

    test('toProjectCalculation с кириллицей в notes', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'cyrillic',
        calculatorName: 'Кириллица',
        inputs: {'площадь': 20.0},
        results: {'материалы': 100.0},
        notes: 'Заметки на русском языке с эмодзи 🏗️',
      );

      final calc = payload.toProjectCalculation();

      expect(calc.notes, 'Заметки на русском языке с эмодзи 🏗️');
    });

    test('toProjectCalculation с множеством materials', () {
      final materials = List.generate(
        20,
        (i) => ProjectMaterial()
          ..name = 'Материал $i'
          ..quantity = (i + 1).toDouble()
          ..unit = 'шт'
          ..pricePerUnit = (i + 1) * 100.0,
      );

      final payload = CalculatorResultPayload(
        calculatorId: 'many_materials',
        calculatorName: 'Много материалов',
        inputs: {'count': 20.0},
        results: {'total': 20.0},
        materials: materials,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.materials.length, 20);
      expect(calc.materials[0].name, 'Материал 0');
      expect(calc.materials[19].name, 'Материал 19');
      expect(calc.materials[0].quantity, 1.0);
      expect(calc.materials[19].quantity, 20.0);
    });

    test('toProjectCalculation materials сохраняют все свойства', () {
      final materials = [
        ProjectMaterial()
          ..name = 'Цемент'
          ..sku = 'CEM001'
          ..quantity = 50.0
          ..unit = 'кг'
          ..pricePerUnit = 15.0
          ..purchased = false
          ..priority = 5
          ..calculatorId = 'detailed',
      ];

      final payload = CalculatorResultPayload(
        calculatorId: 'detailed',
        calculatorName: 'Детальный',
        inputs: {'amount': 50.0},
        results: {'bags': 2.0},
        materials: materials,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.materials[0].name, 'Цемент');
      expect(calc.materials[0].sku, 'CEM001');
      expect(calc.materials[0].quantity, 50.0);
      expect(calc.materials[0].unit, 'кг');
      expect(calc.materials[0].pricePerUnit, 15.0);
      expect(calc.materials[0].totalCost, 750.0);
      expect(calc.materials[0].purchased, false);
      expect(calc.materials[0].priority, 5);
      expect(calc.materials[0].calculatorId, 'detailed');
    });

    test('const конструктор работает корректно', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'const_test',
        calculatorName: 'Const Test',
        inputs: {'a': 1.0},
        results: {'b': 2.0},
      );

      expect(payload.calculatorId, 'const_test');
      expect(payload.calculatorName, 'Const Test');
    });

    test('payload с специальными символами в названии', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'special_chars',
        calculatorName: r'Название с "кавычками" и апострофами и символами: @#$%',
        inputs: {'value': 1.0},
        results: {'result': 2.0},
      );

      final calc = payload.toProjectCalculation();

      expect(calc.name, contains('кавычками'));
      expect(calc.name, contains('апострофами'));
      expect(calc.name, contains('@#'));
    });

    test('payload с пустым calculatorId', () {
      const payload = CalculatorResultPayload(
        calculatorId: '',
        calculatorName: 'Empty ID',
        inputs: {},
        results: {},
      );

      final calc = payload.toProjectCalculation();

      expect(calc.calculatorId, '');
      expect(calc.name, 'Empty ID');
    });

    test('payload с пустым calculatorName', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'empty_name',
        calculatorName: '',
        inputs: {},
        results: {},
      );

      final calc = payload.toProjectCalculation();

      expect(calc.calculatorId, 'empty_name');
      expect(calc.name, '');
    });

    test('toProjectCalculation сохраняет порядок inputs', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'ordered',
        calculatorName: 'Упорядоченный',
        inputs: {
          'first': 1.0,
          'second': 2.0,
          'third': 3.0,
          'fourth': 4.0,
        },
        results: {'total': 10.0},
      );

      final calc = payload.toProjectCalculation();

      expect(calc.inputsMap.length, 4);
      expect(calc.inputsMap['first'], 1.0);
      expect(calc.inputsMap['second'], 2.0);
      expect(calc.inputsMap['third'], 3.0);
      expect(calc.inputsMap['fourth'], 4.0);
    });

    test('toProjectCalculation сохраняет порядок results', () {
      const payload = CalculatorResultPayload(
        calculatorId: 'ordered_results',
        calculatorName: 'Упорядоченные результаты',
        inputs: {'x': 1.0},
        results: {
          'alpha': 1.0,
          'beta': 2.0,
          'gamma': 3.0,
          'delta': 4.0,
        },
      );

      final calc = payload.toProjectCalculation();

      expect(calc.resultsMap.length, 4);
      expect(calc.resultsMap['alpha'], 1.0);
      expect(calc.resultsMap['beta'], 2.0);
      expect(calc.resultsMap['gamma'], 3.0);
      expect(calc.resultsMap['delta'], 4.0);
    });

    test('payload с дробными значениями количества materials', () {
      final materials = [
        ProjectMaterial()
          ..name = 'Краска'
          ..quantity = 2.5
          ..unit = 'л'
          ..pricePerUnit = 450.5,
      ];

      final payload = CalculatorResultPayload(
        calculatorId: 'fractional',
        calculatorName: 'Дробный',
        inputs: {'area': 12.5},
        results: {'liters': 2.5},
        materials: materials,
      );

      final calc = payload.toProjectCalculation();

      expect(calc.materials[0].quantity, closeTo(2.5, 0.01));
      expect(calc.materials[0].pricePerUnit, closeTo(450.5, 0.01));
      expect(calc.materials[0].totalCost, closeTo(1126.25, 0.01));
    });
  });
}
