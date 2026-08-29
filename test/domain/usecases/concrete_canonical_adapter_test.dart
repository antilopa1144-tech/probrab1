import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/concrete_universal_calculator_v2.dart';
import 'package:probrab_ai/domain/usecases/concrete_canonical_adapter.dart';

void main() {
  group('calculateCanonicalConcrete v3', () {
    test('Flutter-definition совпадает с canonical полями и дефолтами', () {
      final defaults = {
        for (final field in concreteUniversalCalculatorV2.fields)
          field.key: field.defaultValue,
      };

      expect(defaults.keys, [
        'inputMode',
        'concreteVolume',
        'area',
        'thickness',
        'concreteGrade',
        'manualMix',
        'readyMixOrderStepM3',
        'reserve',
      ]);
      expect(defaults['inputMode'], 0);
      expect(defaults['concreteVolume'], 5);
      expect(defaults['area'], 20);
      expect(defaults['thickness'], 200);
      expect(defaults['concreteGrade'], 3);
      expect(defaults['manualMix'], 0);
      expect(defaults['readyMixOrderStepM3'], 0.1);
      expect(defaults['reserve'], 5);
    });

    test('условный ввод показывает объём либо площадь с толщиной', () {
      final byVolume = concreteUniversalCalculatorV2
          .getVisibleFields({'inputMode': 0})
          .map((field) => field.key)
          .toList();
      final byArea = concreteUniversalCalculatorV2
          .getVisibleFields({'inputMode': 1})
          .map((field) => field.key)
          .toList();

      expect(byVolume, contains('concreteVolume'));
      expect(byVolume, isNot(contains('area')));
      expect(byVolume, isNot(contains('thickness')));
      expect(byArea, isNot(contains('concreteVolume')));
      expect(byArea, containsAll(['area', 'thickness']));
    });

    test('разделяет чистый объём, выбранный запас и заказ', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'concreteGrade': 3,
        'manualMix': 0,
        'readyMixOrderStepM3': 0.1,
        'reserve': 5,
      });
      final concrete = result.materials.single;

      expect(result.formulaVersion, 'concrete-canonical-v3');
      expect(result.totals['sourceVolume'], 5);
      expect(result.totals['totalVolume'], 5.25);
      expect(result.scenarios['MIN']!.exactNeed, 5);
      expect(result.scenarios['REC']!.exactNeed, 5.25);
      expect(result.scenarios['REC']!.purchaseQuantity, 5.3);
      expect(result.scenarios['MAX']!.exactNeed, 5.5);
      expect(concrete.quantity, 5);
      expect(concrete.withReserve, 5.25);
      expect(concrete.purchaseQty, 5.3);
      expect(concrete.packageInfo, isNull);
    });

    test('округляет готовую смесь по выбранному шагу поставщика', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'manualMix': 0,
        'readyMixOrderStepM3': 0.5,
        'reserve': 5,
      });

      expect(result.scenarios['REC']!.exactNeed, 5.25);
      expect(result.scenarios['REC']!.purchaseQuantity, 5.5);
      expect(result.totals['readyMixOrderStepM3'], 0.5);
    });

    test('ввод по площади и толщине считает геометрический объём', () {
      final result = calculateCanonicalConcrete({
        'inputMode': 1,
        'area': 20,
        'thickness': 200,
        'reserve': 5,
      });

      expect(result.totals['sourceVolume'], 4);
      expect(result.totals['totalVolume'], 4.2);
    });

    test('ручной замес показывает только компоненты и предупреждение', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'concreteGrade': 3,
        'manualMix': 1,
        'reserve': 5,
      });
      final names = result.materials.map((material) => material.name).toList();
      final cement = result.materials.firstWhere(
        (material) => material.name.startsWith('Цемент'),
      );

      expect(names, containsAll(['Песок строительный', 'Щебень']));
      expect(names.any((name) => name.startsWith('Бетон ')), isFalse);
      expect(names, isNot(contains('Вода')));
      expect(result.totals['cementKg'], 1522.5);
      expect(cement.purchaseQty, 1550);
      expect(
        result.warnings.any((warning) => warning.contains('не рецепт')),
        isTrue,
      );
      expect(
        result.scenarios['REC']!.assumptions,
        contains('mix_table_status:project_estimate_not_mix_design'),
      );
    });

    test('не придумывает арматуру и опалубку по одному объёму', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'manualMix': 0,
      });
      final names = result.materials.map((material) => material.name).join(' ');

      expect(names, isNot(matches(RegExp('Арматур|Опалуб|Мастик|Стульчик'))));
    });

    test('заполнители округляются до 0.1 м³, а не целого куба', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 1,
        'concreteGrade': 3,
        'manualMix': 1,
        'reserve': 0,
      });
      final sand = result.materials.firstWhere(
        (material) => material.name == 'Песок строительный',
      );
      final gravel = result.materials.firstWhere(
        (material) => material.name == 'Щебень',
      );

      expect(sand.purchaseQty, 0.5);
      expect(gravel.purchaseQty, 0.9);
    });
  });
}
