import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_hint.dart';

void main() {
  group('HintType', () {
    test('has all expected values', () {
      expect(HintType.values, contains(HintType.info));
      expect(HintType.values, contains(HintType.warning));
      expect(HintType.values, contains(HintType.tip));
      expect(HintType.values, contains(HintType.important));
    });

    test('has exactly 4 values', () {
      expect(HintType.values.length, 4);
    });
  });

  group('HintConditionType', () {
    test('has all expected values', () {
      expect(HintConditionType.values, contains(HintConditionType.always));
      expect(HintConditionType.values, contains(HintConditionType.greaterThan));
      expect(HintConditionType.values, contains(HintConditionType.lessThan));
      expect(HintConditionType.values, contains(HintConditionType.equals));
      expect(HintConditionType.values, contains(HintConditionType.inRange));
      expect(HintConditionType.values, contains(HintConditionType.outOfRange));
    });

    test('has exactly 6 values', () {
      expect(HintConditionType.values.length, 6);
    });
  });

  group('HintCondition', () {
    test('creates with required parameters', () {
      const condition = HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'area',
        value: 100.0,
      );

      expect(condition.type, HintConditionType.greaterThan);
      expect(condition.fieldKey, 'area');
      expect(condition.value, 100.0);
      expect(condition.resultKey, isNull);
      expect(condition.range, isNull);
    });

    test('creates with range', () {
      const condition = HintCondition(
        type: HintConditionType.inRange,
        fieldKey: 'area',
        range: (10.0, 100.0),
      );

      expect(condition.type, HintConditionType.inRange);
      expect(condition.range, (10.0, 100.0));
    });

    group('isSatisfiedByInputs', () {
      test('returns false when fieldKey is null', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          resultKey: 'result',
          value: 100.0,
        );

        expect(condition.isSatisfiedByInputs({'area': 150.0}), isFalse);
      });

      test('returns false when field is missing', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          fieldKey: 'area',
          value: 100.0,
        );

        expect(condition.isSatisfiedByInputs({}), isFalse);
        expect(condition.isSatisfiedByInputs({'other': 150.0}), isFalse);
      });

      test('always condition returns true', () {
        const condition = HintCondition(
          type: HintConditionType.always,
          fieldKey: 'area',
        );

        expect(condition.isSatisfiedByInputs({'area': 0.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 100.0}), isTrue);
      });

      test('greaterThan condition works correctly', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          fieldKey: 'area',
          value: 100.0,
        );

        expect(condition.isSatisfiedByInputs({'area': 150.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 100.0}), isFalse);
        expect(condition.isSatisfiedByInputs({'area': 50.0}), isFalse);
      });

      test('greaterThan returns false when value is null', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          fieldKey: 'area',
        );

        expect(condition.isSatisfiedByInputs({'area': 150.0}), isFalse);
      });

      test('lessThan condition works correctly', () {
        const condition = HintCondition(
          type: HintConditionType.lessThan,
          fieldKey: 'area',
          value: 100.0,
        );

        expect(condition.isSatisfiedByInputs({'area': 50.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 100.0}), isFalse);
        expect(condition.isSatisfiedByInputs({'area': 150.0}), isFalse);
      });

      test('equals condition works correctly', () {
        const condition = HintCondition(
          type: HintConditionType.equals,
          fieldKey: 'mode',
          value: 1.0,
        );

        expect(condition.isSatisfiedByInputs({'mode': 1.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'mode': 2.0}), isFalse);
      });

      test('inRange condition works correctly', () {
        const condition = HintCondition(
          type: HintConditionType.inRange,
          fieldKey: 'area',
          range: (10.0, 100.0),
        );

        expect(condition.isSatisfiedByInputs({'area': 50.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 10.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 100.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 5.0}), isFalse);
        expect(condition.isSatisfiedByInputs({'area': 150.0}), isFalse);
      });

      test('inRange returns false when range is null', () {
        const condition = HintCondition(
          type: HintConditionType.inRange,
          fieldKey: 'area',
        );

        expect(condition.isSatisfiedByInputs({'area': 50.0}), isFalse);
      });

      test('outOfRange condition works correctly', () {
        const condition = HintCondition(
          type: HintConditionType.outOfRange,
          fieldKey: 'area',
          range: (10.0, 100.0),
        );

        expect(condition.isSatisfiedByInputs({'area': 5.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 150.0}), isTrue);
        expect(condition.isSatisfiedByInputs({'area': 50.0}), isFalse);
        expect(condition.isSatisfiedByInputs({'area': 10.0}), isFalse);
        expect(condition.isSatisfiedByInputs({'area': 100.0}), isFalse);
      });
    });

    group('isSatisfiedByResults', () {
      test('returns false when resultKey is null', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          fieldKey: 'area',
          value: 100.0,
        );

        expect(condition.isSatisfiedByResults({'result': 150.0}), isFalse);
      });

      test('returns false when result is missing', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          resultKey: 'total',
          value: 100.0,
        );

        expect(condition.isSatisfiedByResults({}), isFalse);
        expect(condition.isSatisfiedByResults({'other': 150.0}), isFalse);
      });

      test('greaterThan condition works correctly', () {
        const condition = HintCondition(
          type: HintConditionType.greaterThan,
          resultKey: 'total',
          value: 100.0,
        );

        expect(condition.isSatisfiedByResults({'total': 150.0}), isTrue);
        expect(condition.isSatisfiedByResults({'total': 100.0}), isFalse);
        expect(condition.isSatisfiedByResults({'total': 50.0}), isFalse);
      });

      test('inRange condition works on results', () {
        const condition = HintCondition(
          type: HintConditionType.inRange,
          resultKey: 'total',
          range: (10.0, 100.0),
        );

        expect(condition.isSatisfiedByResults({'total': 50.0}), isTrue);
        expect(condition.isSatisfiedByResults({'total': 5.0}), isFalse);
      });
    });
  });

  group('CalculatorHint', () {
    test('creates with messageKey', () {
      const hint = CalculatorHint(
        type: HintType.info,
        messageKey: 'hint.area_large',
      );

      expect(hint.type, HintType.info);
      expect(hint.messageKey, 'hint.area_large');
      expect(hint.message, isNull);
      expect(hint.condition, isNull);
      expect(hint.iconName, isNull);
    });

    test('creates with message', () {
      const hint = CalculatorHint(
        type: HintType.warning,
        message: 'Direct warning message',
      );

      expect(hint.type, HintType.warning);
      expect(hint.message, 'Direct warning message');
      expect(hint.messageKey, isNull);
    });

    test('creates with all parameters', () {
      const hint = CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tip_message',
        message: 'Fallback message',
        condition: HintCondition(
          type: HintConditionType.greaterThan,
          fieldKey: 'area',
          value: 100.0,
        ),
        iconName: 'lightbulb',
      );

      expect(hint.type, HintType.tip);
      expect(hint.messageKey, 'hint.tip_message');
      expect(hint.message, 'Fallback message');
      expect(hint.condition, isNotNull);
      expect(hint.condition!.type, HintConditionType.greaterThan);
      expect(hint.iconName, 'lightbulb');
    });

    test('creates important hint type', () {
      const hint = CalculatorHint(
        type: HintType.important,
        messageKey: 'hint.important_notice',
      );

      expect(hint.type, HintType.important);
    });
  });
}
