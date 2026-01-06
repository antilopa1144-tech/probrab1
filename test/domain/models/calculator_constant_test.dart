import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_constant.dart';

void main() {
  group('ConstantCategory', () {
    test('has all expected values', () {
      expect(ConstantCategory.values, contains(ConstantCategory.coefficients));
      expect(ConstantCategory.values, contains(ConstantCategory.formulas));
      expect(ConstantCategory.values, contains(ConstantCategory.margins));
      expect(ConstantCategory.values, contains(ConstantCategory.materials));
      expect(ConstantCategory.values, contains(ConstantCategory.measurements));
      expect(ConstantCategory.values, contains(ConstantCategory.power));
      expect(ConstantCategory.values, contains(ConstantCategory.packaging));
      expect(ConstantCategory.values, contains(ConstantCategory.conversion));
    });

    test('has exactly 8 values', () {
      expect(ConstantCategory.values.length, 8);
    });
  });

  group('CalculatorConstant', () {
    test('creates with required parameters', () {
      const constant = CalculatorConstant(
        key: 'room_power',
        category: ConstantCategory.power,
        description: 'Power per room type',
        values: {'bathroom': 180.0, 'living_room': 150.0},
      );

      expect(constant.key, 'room_power');
      expect(constant.category, ConstantCategory.power);
      expect(constant.description, 'Power per room type');
      expect(constant.unit, isNull);
      expect(constant.values['bathroom'], 180.0);
    });

    test('creates with unit', () {
      const constant = CalculatorConstant(
        key: 'room_power',
        category: ConstantCategory.power,
        description: 'Power per room type',
        unit: 'watt_per_m2',
        values: {'bathroom': 180.0},
      );

      expect(constant.unit, 'watt_per_m2');
    });

    group('fromJson', () {
      test('creates from valid JSON', () {
        final json = {
          'category': 'power',
          'description': 'Room power values',
          'unit': 'W/m2',
          'values': {'bathroom': 180.0, 'kitchen': 130.0},
        };

        final constant = CalculatorConstant.fromJson('room_power', json);

        expect(constant.key, 'room_power');
        expect(constant.category, ConstantCategory.power);
        expect(constant.description, 'Room power values');
        expect(constant.unit, 'W/m2');
        expect(constant.values['bathroom'], 180.0);
      });

      test('uses default category for unknown category', () {
        final json = <String, dynamic>{
          'category': 'unknown_category',
          'description': 'Test',
          'values': <String, dynamic>{},
        };

        final constant = CalculatorConstant.fromJson('test', json);

        expect(constant.category, ConstantCategory.coefficients);
      });

      test('handles missing optional fields', () {
        final json = <String, dynamic>{
          'category': 'margins',
        };

        final constant = CalculatorConstant.fromJson('test', json);

        expect(constant.description, '');
        expect(constant.unit, isNull);
        expect(constant.values, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        const constant = CalculatorConstant(
          key: 'room_power',
          category: ConstantCategory.power,
          description: 'Power values',
          unit: 'W/m2',
          values: {'bathroom': 180.0},
        );

        final json = constant.toJson();

        expect(json['category'], 'power');
        expect(json['description'], 'Power values');
        expect(json['unit'], 'W/m2');
        expect(json['values'], {'bathroom': 180.0});
      });

      test('omits unit when null', () {
        const constant = CalculatorConstant(
          key: 'test',
          category: ConstantCategory.coefficients,
          description: 'Test',
          values: {},
        );

        final json = constant.toJson();

        expect(json.containsKey('unit'), isFalse);
      });
    });

    group('getDouble', () {
      test('returns double value', () {
        const constant = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'Test',
          values: {'value': 180.0},
        );

        expect(constant.getDouble('value'), 180.0);
      });

      test('converts int to double', () {
        const constant = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'Test',
          values: {'value': 180},
        );

        expect(constant.getDouble('value'), 180.0);
      });

      test('returns null for missing key', () {
        const constant = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'Test',
          values: {},
        );

        expect(constant.getDouble('missing'), isNull);
      });

      test('returns null for non-numeric value', () {
        const constant = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'Test',
          values: {'value': 'string'},
        );

        expect(constant.getDouble('value'), isNull);
      });
    });

    group('getInt', () {
      test('returns int value', () {
        const constant = CalculatorConstant(
          key: 'count',
          category: ConstantCategory.packaging,
          description: 'Test',
          values: {'value': 10},
        );

        expect(constant.getInt('value'), 10);
      });

      test('rounds double to int', () {
        const constant = CalculatorConstant(
          key: 'count',
          category: ConstantCategory.packaging,
          description: 'Test',
          values: {'value': 10.7},
        );

        expect(constant.getInt('value'), 11);
      });

      test('returns null for missing key', () {
        const constant = CalculatorConstant(
          key: 'count',
          category: ConstantCategory.packaging,
          description: 'Test',
          values: {},
        );

        expect(constant.getInt('missing'), isNull);
      });

      test('returns null for non-numeric value', () {
        const constant = CalculatorConstant(
          key: 'count',
          category: ConstantCategory.packaging,
          description: 'Test',
          values: {'value': 'string'},
        );

        expect(constant.getInt('value'), isNull);
      });
    });

    group('getString', () {
      test('returns string value', () {
        const constant = CalculatorConstant(
          key: 'label',
          category: ConstantCategory.materials,
          description: 'Test',
          values: {'name': 'cement'},
        );

        expect(constant.getString('name'), 'cement');
      });

      test('converts numeric to string', () {
        const constant = CalculatorConstant(
          key: 'label',
          category: ConstantCategory.materials,
          description: 'Test',
          values: {'count': 10},
        );

        expect(constant.getString('count'), '10');
      });

      test('returns null for missing key', () {
        const constant = CalculatorConstant(
          key: 'label',
          category: ConstantCategory.materials,
          description: 'Test',
          values: {},
        );

        expect(constant.getString('missing'), isNull);
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        const constant = CalculatorConstant(
          key: 'room_power',
          category: ConstantCategory.power,
          description: 'Test',
          values: {'a': 1, 'b': 2, 'c': 3},
        );

        expect(
          constant.toString(),
          'CalculatorConstant(key: room_power, category: power, values: 3)',
        );
      });
    });

    group('equality', () {
      test('equals same key and category', () {
        const a = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'A',
          values: {'x': 1.0},
        );
        const b = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'B',
          values: {'y': 2.0},
        );

        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('not equals different key', () {
        const a = CalculatorConstant(
          key: 'power1',
          category: ConstantCategory.power,
          description: 'Test',
          values: {},
        );
        const b = CalculatorConstant(
          key: 'power2',
          category: ConstantCategory.power,
          description: 'Test',
          values: {},
        );

        expect(a == b, isFalse);
      });

      test('not equals different category', () {
        const a = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.power,
          description: 'Test',
          values: {},
        );
        const b = CalculatorConstant(
          key: 'power',
          category: ConstantCategory.margins,
          description: 'Test',
          values: {},
        );

        expect(a == b, isFalse);
      });
    });
  });

  group('CalculatorConstants', () {
    test('creates with required parameters', () {
      final now = DateTime.now();
      final constants = CalculatorConstants(
        calculatorId: 'warmfloor',
        version: '1.0.0',
        lastUpdated: now,
        constants: {},
      );

      expect(constants.calculatorId, 'warmfloor');
      expect(constants.version, '1.0.0');
      expect(constants.lastUpdated, now);
      expect(constants.constants, isEmpty);
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = {
          'calculator_id': 'warmfloor',
          'version': '2.0.0',
          'last_updated': '2024-01-15T10:30:00.000Z',
          'constants': {
            'room_power': {
              'category': 'power',
              'description': 'Room power',
              'values': {'bathroom': 180.0},
            },
          },
        };

        final constants = CalculatorConstants.fromJson(json);

        expect(constants.calculatorId, 'warmfloor');
        expect(constants.version, '2.0.0');
        expect(constants.constants.length, 1);
        expect(constants.constants['room_power'], isNotNull);
      });

      test('uses defaults for missing fields', () {
        final constants = CalculatorConstants.fromJson({});

        expect(constants.calculatorId, 'unknown');
        expect(constants.version, '1.0.0');
        expect(constants.constants, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final constants = CalculatorConstants(
          calculatorId: 'tile',
          version: '1.2.0',
          lastUpdated: DateTime.utc(2024, 1, 15, 10, 30),
          constants: {
            'margin': const CalculatorConstant(
              key: 'margin',
              category: ConstantCategory.margins,
              description: 'Margin percent',
              values: {'default': 10.0},
            ),
          },
        );

        final json = constants.toJson();

        expect(json['calculator_id'], 'tile');
        expect(json['version'], '1.2.0');
        expect(json['last_updated'], '2024-01-15T10:30:00.000Z');
        expect(json['constants'], isNotNull);
        final constantsMap = json['constants'] as Map<String, dynamic>;
        expect(constantsMap['margin'], isNotNull);
      });
    });

    group('get', () {
      test('returns constant by key', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'power': const CalculatorConstant(
              key: 'power',
              category: ConstantCategory.power,
              description: 'Test',
              values: {'value': 100.0},
            ),
          },
        );

        expect(constants.get('power'), isNotNull);
        expect(constants.get('power')!.key, 'power');
      });

      test('returns null for missing key', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(constants.get('missing'), isNull);
      });
    });

    group('getDouble', () {
      test('returns double value from constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'power': const CalculatorConstant(
              key: 'power',
              category: ConstantCategory.power,
              description: 'Test',
              values: {'bathroom': 180.0},
            ),
          },
        );

        expect(
          constants.getDouble('power', 'bathroom', defaultValue: 0.0),
          180.0,
        );
      });

      test('returns default for missing constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(
          constants.getDouble('missing', 'value', defaultValue: 50.0),
          50.0,
        );
      });

      test('returns default for missing value', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'power': const CalculatorConstant(
              key: 'power',
              category: ConstantCategory.power,
              description: 'Test',
              values: {},
            ),
          },
        );

        expect(
          constants.getDouble('power', 'missing', defaultValue: 50.0),
          50.0,
        );
      });
    });

    group('getInt', () {
      test('returns int value from constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'count': const CalculatorConstant(
              key: 'count',
              category: ConstantCategory.packaging,
              description: 'Test',
              values: {'perPack': 10},
            ),
          },
        );

        expect(
          constants.getInt('count', 'perPack', defaultValue: 0),
          10,
        );
      });

      test('returns default for missing constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(
          constants.getInt('missing', 'value', defaultValue: 5),
          5,
        );
      });
    });

    group('getMap', () {
      test('returns values map from constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'power': const CalculatorConstant(
              key: 'power',
              category: ConstantCategory.power,
              description: 'Test',
              values: {'a': 1.0, 'b': 2.0},
            ),
          },
        );

        final map = constants.getMap('power');

        expect(map['a'], 1.0);
        expect(map['b'], 2.0);
      });

      test('returns empty map for missing constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(constants.getMap('missing'), isEmpty);
      });
    });

    group('has', () {
      test('returns true for existing constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'power': const CalculatorConstant(
              key: 'power',
              category: ConstantCategory.power,
              description: 'Test',
              values: {},
            ),
          },
        );

        expect(constants.has('power'), isTrue);
      });

      test('returns false for missing constant', () {
        final constants = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(constants.has('missing'), isFalse);
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        final constants = CalculatorConstants(
          calculatorId: 'warmfloor',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {
            'a': const CalculatorConstant(
              key: 'a',
              category: ConstantCategory.power,
              description: '',
              values: {},
            ),
            'b': const CalculatorConstant(
              key: 'b',
              category: ConstantCategory.margins,
              description: '',
              values: {},
            ),
          },
        );

        expect(
          constants.toString(),
          'CalculatorConstants(id: warmfloor, version: 1.0.0, constants: 2)',
        );
      });
    });

    group('equality', () {
      test('equals same id and version', () {
        final a = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime(2024),
          constants: {},
        );
        final b = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime(2025),
          constants: {'x': const CalculatorConstant(key: 'x', category: ConstantCategory.power, description: '', values: {})},
        );

        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('not equals different id', () {
        final a = CalculatorConstants(
          calculatorId: 'test1',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );
        final b = CalculatorConstants(
          calculatorId: 'test2',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(a == b, isFalse);
      });

      test('not equals different version', () {
        final a = CalculatorConstants(
          calculatorId: 'test',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );
        final b = CalculatorConstants(
          calculatorId: 'test',
          version: '2.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        );

        expect(a == b, isFalse);
      });
    });
  });
}
