import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/datasources/local_constants_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalConstantsDataSource', () {
    late LocalConstantsDataSource dataSource;

    setUp(() {
      dataSource = LocalConstantsDataSource();
    });

    group('getConstants', () {
      test('returns CalculatorConstants for warmfloor', () async {
        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'warmfloor');
        expect(constants.version, isNotEmpty);
        expect(constants.constants, isNotEmpty);
      });

      test('returns CalculatorConstants for electrical', () async {
        final constants = await dataSource.getConstants('electrical');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'electrical');
        expect(constants.constants.containsKey('room_type_multipliers'), true);
      });

      test('returns CalculatorConstants for gasblock', () async {
        final constants = await dataSource.getConstants('gasblock');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'gasblock');
        expect(constants.constants.containsKey('block_sizes'), true);
      });

      test('returns CalculatorConstants for tile', () async {
        final constants = await dataSource.getConstants('tile');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'tile');
      });

      test('returns CalculatorConstants for gypsum', () async {
        final constants = await dataSource.getConstants('gypsum');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'gypsum');
      });

      test('returns CalculatorConstants for putty', () async {
        final constants = await dataSource.getConstants('putty');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'putty');
      });

      test('returns null for non-existent calculator', () async {
        final constants = await dataSource.getConstants('nonexistent_calculator');

        expect(constants, isNull);
      });

      test('handles case insensitivity in calculator id', () async {
        final constants1 = await dataSource.getConstants('WARMFLOOR');
        final constants2 = await dataSource.getConstants('Warmfloor');
        final constants3 = await dataSource.getConstants('warmfloor');

        expect(constants1, isNotNull);
        expect(constants2, isNotNull);
        expect(constants3, isNotNull);
      });
    });

    group('caching', () {
      test('caches loaded constants', () async {
        expect(dataSource.isCached('warmfloor'), false);
        expect(dataSource.cacheSize, 0);

        await dataSource.getConstants('warmfloor');

        expect(dataSource.isCached('warmfloor'), true);
        expect(dataSource.cacheSize, 1);
      });

      test('returns cached version on subsequent calls', () async {
        final constants1 = await dataSource.getConstants('warmfloor');
        final constants2 = await dataSource.getConstants('warmfloor');

        expect(identical(constants1, constants2), true);
      });

      test('caches multiple calculators', () async {
        await dataSource.getConstants('warmfloor');
        await dataSource.getConstants('electrical');
        await dataSource.getConstants('gasblock');

        expect(dataSource.cacheSize, 3);
        expect(dataSource.isCached('warmfloor'), true);
        expect(dataSource.isCached('electrical'), true);
        expect(dataSource.isCached('gasblock'), true);
      });

      test('clearCache removes specific calculator', () async {
        await dataSource.getConstants('warmfloor');
        await dataSource.getConstants('electrical');

        expect(dataSource.cacheSize, 2);

        dataSource.clearCache('warmfloor');

        expect(dataSource.isCached('warmfloor'), false);
        expect(dataSource.isCached('electrical'), true);
        expect(dataSource.cacheSize, 1);
      });

      test('clearCache removes all when no id specified', () async {
        await dataSource.getConstants('warmfloor');
        await dataSource.getConstants('electrical');
        await dataSource.getConstants('gasblock');

        expect(dataSource.cacheSize, 3);

        dataSource.clearCache();

        expect(dataSource.cacheSize, 0);
        expect(dataSource.isCached('warmfloor'), false);
        expect(dataSource.isCached('electrical'), false);
        expect(dataSource.isCached('gasblock'), false);
      });

      test('does not cache non-existent calculators', () async {
        await dataSource.getConstants('nonexistent');

        expect(dataSource.isCached('nonexistent'), false);
        expect(dataSource.cacheSize, 0);
      });
    });

    group('getCommonConstants', () {
      test('is shortcut for getConstants common', () async {
        // This will return null if common.json doesn't exist,
        // but it should behave the same as getConstants('common')
        final common1 = await dataSource.getCommonConstants();
        final common2 = await dataSource.getConstants('common');

        // Either both are null or both are equal
        expect(common1 == null, common2 == null);
      });
    });

    group('CalculatorConstants helper methods', () {
      test('getDouble returns correct value', () async {
        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);

        // Check a known constant
        final power = constants!.getDouble('room_power', 'bathroom', defaultValue: 0.0);
        expect(power, greaterThan(0.0));
      });

      test('getDouble returns default for missing key', () async {
        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);

        final value = constants!.getDouble('nonexistent', 'key', defaultValue: 42.0);
        expect(value, 42.0);
      });

      test('getInt returns correct value', () async {
        final constants = await dataSource.getConstants('putty');

        expect(constants, isNotNull);

        final bagWeight = constants!.getInt('start_putty', 'bag_weight', defaultValue: 0);
        expect(bagWeight, 25);
      });

      test('getMap returns constant values', () async {
        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);

        final map = constants!.getMap('room_power');
        expect(map, isNotEmpty);
        expect(map.containsKey('bathroom'), true);
      });

      test('has returns true for existing constant', () async {
        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.has('room_power'), true);
      });

      test('has returns false for non-existing constant', () async {
        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.has('nonexistent_constant'), false);
      });
    });
  });
}
