import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';

void main() {
  group('ConstantValueParams', () {
    test('creates instance with required fields', () {
      const params = ConstantValueParams(
        calculatorId: 'warmfloor',
        constantKey: 'room_power',
        valueKey: 'bathroom',
      );

      expect(params.calculatorId, 'warmfloor');
      expect(params.constantKey, 'room_power');
      expect(params.valueKey, 'bathroom');
      expect(params.defaultValue, isNull);
    });

    test('creates instance with default value', () {
      const params = ConstantValueParams(
        calculatorId: 'plaster',
        constantKey: 'consumption',
        valueKey: 'gypsum',
        defaultValue: 8.5,
      );

      expect(params.defaultValue, 8.5);
    });

    test('supports various default value types', () {
      const intParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
        defaultValue: 42,
      );
      expect(intParams.defaultValue, 42);

      const stringParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
        defaultValue: 'default',
      );
      expect(stringParams.defaultValue, 'default');

      const boolParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
        defaultValue: true,
      );
      expect(boolParams.defaultValue, true);
    });

    group('equality', () {
      test('equal params are equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 10.0,
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 10.0,
        );

        expect(params1, equals(params2));
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('different calculatorId makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc1',
          constantKey: 'const',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc2',
          constantKey: 'const',
          valueKey: 'val',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('different constantKey makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const1',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const2',
          valueKey: 'val',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('different valueKey makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val1',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val2',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('different defaultValue makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 1.0,
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 2.0,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('null vs non-null defaultValue makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 0.0,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('both null defaultValues are equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
        );

        expect(params1, equals(params2));
      });
    });

    group('hashCode', () {
      test('same params have same hashCode', () {
        const params1 = ConstantValueParams(
          calculatorId: 'warmfloor',
          constantKey: 'room_power',
          valueKey: 'bathroom',
          defaultValue: 180.0,
        );

        const params2 = ConstantValueParams(
          calculatorId: 'warmfloor',
          constantKey: 'room_power',
          valueKey: 'bathroom',
          defaultValue: 180.0,
        );

        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('different params likely have different hashCodes', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc1',
          constantKey: 'key1',
          valueKey: 'val1',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc2',
          constantKey: 'key2',
          valueKey: 'val2',
        );

        // hashCodes COULD collide but very unlikely for different data
        expect(params1.hashCode, isNot(equals(params2.hashCode)));
      });
    });

    test('can be used as map key', () {
      const params = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
      );

      final map = <ConstantValueParams, String>{};
      map[params] = 'test value';

      const sameParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
      );

      expect(map[sameParams], 'test value');
    });
  });
}
