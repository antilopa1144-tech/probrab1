import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/datasources/local_constants_data_source.dart';
import 'package:probrab_ai/domain/models/calculator_constant.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Constants System', () {
    late LocalConstantsDataSource dataSource;

    setUp(() {
      dataSource = LocalConstantsDataSource();
    });

    test('loads warmfloor constants from JSON', () async {
      final constants = await dataSource.getConstants('warmfloor');

      expect(constants, isNotNull);
      expect(constants!.calculatorId, 'warmfloor');
      expect(constants.version, isNotEmpty);
      expect(constants.constants, isNotEmpty);

      // Check specific constants exist
      expect(constants.constants.containsKey('room_power'), true);
      expect(constants.constants.containsKey('cable_power'), true);
      expect(constants.constants.containsKey('materials'), true);
    });

    test('loads electrical constants from JSON', () async {
      final constants = await dataSource.getConstants('electrical');

      expect(constants, isNotNull);
      expect(constants!.calculatorId, 'electrical');
      expect(constants.constants, isNotEmpty);

      // Check specific constants exist
      expect(constants.constants.containsKey('room_type_multipliers'), true);
      expect(constants.constants.containsKey('socket_calculation'), true);
      expect(constants.constants.containsKey('cable_lengths_hidden'), true);
    });

    test('loads gasblock constants from JSON', () async {
      final constants = await dataSource.getConstants('gasblock');

      expect(constants, isNotNull);
      expect(constants!.calculatorId, 'gasblock');
      expect(constants.constants, isNotEmpty);

      // Check specific constants exist
      expect(constants.constants.containsKey('block_sizes'), true);
      expect(constants.constants.containsKey('thicknesses'), true);
      expect(constants.constants.containsKey('glue_consumption'), true);
    });

    test('loads tile constants from JSON', () async {
      final constants = await dataSource.getConstants('tile');

      expect(constants, isNotNull);
      expect(constants!.calculatorId, 'tile');
      expect(constants.constants, isNotEmpty);

      // Check specific constants exist
      expect(constants.constants.containsKey('glue_consumption'), true);
      expect(constants.constants.containsKey('layout_margins'), true);
      expect(constants.constants.containsKey('grout_calculation'), true);
    });

    test('loads gypsum constants from JSON', () async {
      final constants = await dataSource.getConstants('gypsum');

      expect(constants, isNotNull);
      expect(constants!.calculatorId, 'gypsum');
      expect(constants.constants, isNotEmpty);

      // Check specific constants exist
      expect(constants.constants.containsKey('sheet_sizes'), true);
      expect(constants.constants.containsKey('wall_lining'), true);
      expect(constants.constants.containsKey('partition'), true);
      expect(constants.constants.containsKey('ceiling'), true);
    });

    test('returns null for non-existent calculator', () async {
      final constants = await dataSource.getConstants('nonexistent');
      expect(constants, isNull);
    });

    test('caches loaded constants', () async {
      // First load
      final constants1 = await dataSource.getConstants('warmfloor');
      expect(constants1, isNotNull);

      // Second load should return cached version
      final constants2 = await dataSource.getConstants('warmfloor');
      expect(constants2, isNotNull);
      expect(identical(constants1, constants2), true);
    });

    test('CalculatorConstants helper methods work correctly', () {
      const constant = CalculatorConstant(
        key: 'test_constant',
        category: ConstantCategory.coefficients,
        description: 'Test constant',
        unit: 'm',
        values: {
          'value1': 10.5,
          'value2': 20,
          'value3': 'text',
        },
      );

      final constants = CalculatorConstants(
        calculatorId: 'test',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: const {'test_constant': constant},
      );

      // Test getDouble with defaultValue
      expect(constants.getDouble('test_constant', 'value1', defaultValue: 0.0), 10.5);
      expect(constants.getDouble('test_constant', 'value2', defaultValue: 0.0), 20.0);
      expect(constants.getDouble('test_constant', 'missing', defaultValue: 99.0), 99.0);

      // Test getInt with defaultValue (10.5 rounds to 11)
      expect(constants.getInt('test_constant', 'value2', defaultValue: 0), 20);
      expect(constants.getInt('test_constant', 'value1', defaultValue: 0), 11);
      expect(constants.getInt('test_constant', 'missing', defaultValue: 99), 99);

      // Test getMap
      final map = constants.getMap('test_constant');
      expect(map['value1'], 10.5);
      expect(map['value2'], 20);
      expect(map['value3'], 'text');

      // Test has
      expect(constants.has('test_constant'), true);
      expect(constants.has('nonexistent'), false);
    });

    test('validates all constant categories are recognized', () {
      const categories = [
        ConstantCategory.coefficients,
        ConstantCategory.formulas,
        ConstantCategory.margins,
        ConstantCategory.materials,
        ConstantCategory.measurements,
        ConstantCategory.power,
        ConstantCategory.packaging,
        ConstantCategory.conversion,
      ];

      for (var category in categories) {
        expect(category.name, isNotEmpty);
      }
    });
  });
}
