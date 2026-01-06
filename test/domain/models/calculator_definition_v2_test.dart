import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';
import 'package:probrab_ai/core/enums/unit_type.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/domain/models/calculator_field.dart';
import 'package:probrab_ai/domain/models/calculator_hint.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Простой тестовый usecase.
class _TestUseCase implements CalculatorUseCase {
  @override
  CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
    final area = inputs['area'] ?? 0.0;
    return CalculatorResult(
      values: {'result': area * 2},
    );
  }
}

void main() {
  group('CalculatorDefinitionV2', () {
    late CalculatorDefinitionV2 definition;

    setUp(() {
      definition = CalculatorDefinitionV2(
        id: 'test_calculator',
        titleKey: 'calculator.test.title',
        descriptionKey: 'calculator.test.description',
        category: CalculatorCategory.interior,
        subCategoryKey: 'subcategory.test',
        fields: [
          const CalculatorField(
            key: 'area',
            labelKey: 'input.area',
            unitType: UnitType.squareMeters,
            defaultValue: 10.0,
            order: 1,
          ),
          const CalculatorField(
            key: 'height',
            labelKey: 'input.height',
            unitType: UnitType.meters,
            defaultValue: 2.7,
            order: 2,
          ),
          const CalculatorField(
            key: 'width',
            labelKey: 'input.width',
            unitType: UnitType.meters,
            defaultValue: 0.0,
            order: 0,
          ),
        ],
        beforeHints: const [
          CalculatorHint(type: HintType.info, message: 'Before hint'),
        ],
        afterHints: const [
          CalculatorHint(type: HintType.tip, message: 'After hint'),
        ],
        useCase: _TestUseCase(),
        iconName: 'test_icon',
        accentColor: 0xFF123456,
        complexity: 3,
        popularity: 100,
        isFavorite: true,
        tags: ['tag1', 'tag2'],
        showToolsSection: false,
      );
    });

    test('creates with required parameters', () {
      expect(definition.id, 'test_calculator');
      expect(definition.titleKey, 'calculator.test.title');
      expect(definition.descriptionKey, 'calculator.test.description');
      expect(definition.category, CalculatorCategory.interior);
      expect(definition.subCategoryKey, 'subcategory.test');
    });

    test('creates with default values', () {
      final simpleDefinition = CalculatorDefinitionV2(
        id: 'simple',
        titleKey: 'simple.title',
        category: CalculatorCategory.exterior,
        subCategoryKey: 'sub.simple',
        fields: const [],
        useCase: _TestUseCase(),
      );

      expect(simpleDefinition.beforeHints, isEmpty);
      expect(simpleDefinition.afterHints, isEmpty);
      expect(simpleDefinition.complexity, 1);
      expect(simpleDefinition.popularity, 0);
      expect(simpleDefinition.isFavorite, false);
      expect(simpleDefinition.tags, isEmpty);
      expect(simpleDefinition.showToolsSection, true);
    });

    test('has correct metadata', () {
      expect(definition.iconName, 'test_icon');
      expect(definition.accentColor, 0xFF123456);
      expect(definition.complexity, 3);
      expect(definition.popularity, 100);
      expect(definition.isFavorite, true);
      expect(definition.tags, ['tag1', 'tag2']);
      expect(definition.showToolsSection, false);
    });

    group('sortedFields', () {
      test('returns fields sorted by order', () {
        final sorted = definition.sortedFields;

        expect(sorted[0].key, 'width'); // order: 0
        expect(sorted[1].key, 'area'); // order: 1
        expect(sorted[2].key, 'height'); // order: 2
      });

      test('returns all fields', () {
        expect(definition.sortedFields.length, 3);
      });
    });

    group('getVisibleFields', () {
      test('returns all fields when no conditions', () {
        final visible = definition.getVisibleFields({'area': 10.0});
        expect(visible.length, 3);
      });

      test('returns fields with satisfied conditions', () {
        final defWithConditions = CalculatorDefinitionV2(
          id: 'conditional',
          titleKey: 'conditional.title',
          category: CalculatorCategory.interior,
          subCategoryKey: 'sub.conditional',
          fields: [
            const CalculatorField(
              key: 'mode',
              labelKey: 'input.mode',
              unitType: UnitType.pieces,
              defaultValue: 0,
              order: 0,
            ),
            const CalculatorField(
              key: 'advanced',
              labelKey: 'input.advanced',
              unitType: UnitType.pieces,
              defaultValue: 0,
              order: 1,
              dependency: FieldDependency(
                fieldKey: 'mode',
                condition: DependencyCondition.equals,
                value: 1,
              ),
            ),
          ],
          useCase: _TestUseCase(),
        );

        // When mode is 0, advanced field should not be visible
        var visible = defWithConditions.getVisibleFields({'mode': 0});
        expect(visible.length, 1);
        expect(visible[0].key, 'mode');

        // When mode is 1, advanced field should be visible
        visible = defWithConditions.getVisibleFields({'mode': 1});
        expect(visible.length, 2);
      });
    });

    group('getFieldsByGroup', () {
      test('groups fields by group name', () {
        final defWithGroups = CalculatorDefinitionV2(
          id: 'grouped',
          titleKey: 'grouped.title',
          category: CalculatorCategory.interior,
          subCategoryKey: 'sub.grouped',
          fields: const [
            CalculatorField(
              key: 'length',
              labelKey: 'input.length',
              unitType: UnitType.meters,
              defaultValue: 0,
              group: 'dimensions',
            ),
            CalculatorField(
              key: 'width',
              labelKey: 'input.width',
              unitType: UnitType.meters,
              defaultValue: 0,
              group: 'dimensions',
            ),
            CalculatorField(
              key: 'coverage',
              labelKey: 'input.coverage',
              unitType: UnitType.litersPerSqm,
              defaultValue: 0,
              group: 'parameters',
            ),
            CalculatorField(
              key: 'ungrouped',
              labelKey: 'input.ungrouped',
              unitType: UnitType.pieces,
              defaultValue: 0,
            ),
          ],
          useCase: _TestUseCase(),
        );

        final grouped = defWithGroups.getFieldsByGroup();

        expect(grouped.containsKey('dimensions'), true);
        expect(grouped.containsKey('parameters'), true);
        expect(grouped.containsKey('default'), true);

        expect(grouped['dimensions']!.length, 2);
        expect(grouped['parameters']!.length, 1);
        expect(grouped['default']!.length, 1);
      });
    });

    group('getBeforeHints', () {
      test('returns all hints when no conditions', () {
        final hints = definition.getBeforeHints({});
        expect(hints.length, 1);
        expect(hints[0].message, 'Before hint');
      });
    });

    group('getAfterHints', () {
      test('returns all hints when no conditions', () {
        final hints = definition.getAfterHints({}, {});
        expect(hints.length, 1);
        expect(hints[0].message, 'After hint');
      });
    });

    group('calculate', () {
      test('executes useCase and returns result', () {
        final result = definition.calculate(
          {'area': 25.0},
          const [],
          useCache: false,
        );

        expect(result.values['result'], 50.0);
      });

      test('returns cached result when available', () {
        // First call - should compute
        final result1 = definition.calculate(
          {'area': 30.0},
          const [],
          useCache: true,
        );

        // Second call with same inputs - should use cache
        final result2 = definition.calculate(
          {'area': 30.0},
          const [],
          useCache: true,
        );

        expect(result1.values['result'], result2.values['result']);
      });
    });

    group('copyWith', () {
      test('creates copy with same values', () {
        final copy = definition.copyWith();

        expect(copy.id, definition.id);
        expect(copy.titleKey, definition.titleKey);
        expect(copy.category, definition.category);
        expect(copy.complexity, definition.complexity);
      });

      test('creates copy with changed values', () {
        final copy = definition.copyWith(
          id: 'new_id',
          titleKey: 'new.title',
          complexity: 5,
          isFavorite: false,
        );

        expect(copy.id, 'new_id');
        expect(copy.titleKey, 'new.title');
        expect(copy.complexity, 5);
        expect(copy.isFavorite, false);

        // Unchanged values
        expect(copy.category, definition.category);
        expect(copy.subCategoryKey, definition.subCategoryKey);
      });

      test('preserves useCase in copy', () {
        final copy = definition.copyWith();
        final result = copy.calculate({'area': 10.0}, const [], useCache: false);

        expect(result.values['result'], 20.0);
      });
    });
  });
}
