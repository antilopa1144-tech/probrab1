import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_input.dart';

void main() {
  group('TileCalculatorInput', () {
    test('creates with required parameters', () {
      const input = TileCalculatorInput(area: 20.0);
      expect(input.area, 20.0);
      expect(input.tileWidth, 30.0);
      expect(input.tileHeight, 30.0);
      expect(input.jointWidth, 3.0);
    });

    test('creates with all parameters', () {
      const input = TileCalculatorInput(
        area: 25.0,
        tileWidth: 60.0,
        tileHeight: 60.0,
        jointWidth: 2.0,
      );
      expect(input.area, 25.0);
      expect(input.tileWidth, 60.0);
      expect(input.tileHeight, 60.0);
      expect(input.jointWidth, 2.0);
    });

    test('toMap returns correct values', () {
      const input = TileCalculatorInput(area: 20.0, tileWidth: 40.0);
      final map = input.toMap();
      expect(map['area'], 20.0);
      expect(map['tileWidth'], 40.0);
    });

    test('isValid returns true for valid input', () {
      const input = TileCalculatorInput(area: 20.0);
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false for zero area', () {
      const input = TileCalculatorInput(area: 0.0);
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for negative tile width', () {
      const input = TileCalculatorInput(area: 20.0, tileWidth: -1.0);
      expect(input.isValid(), isFalse);
    });

    test('getValidationErrors returns errors for invalid input', () {
      const input = TileCalculatorInput(area: 0.0, tileWidth: -1.0);
      final errors = input.getValidationErrors();
      expect(errors.length, greaterThan(0));
    });

    test('copyWith creates new instance with updated values', () {
      const input = TileCalculatorInput(area: 20.0);
      final copied = input.copyWith(area: 30.0);
      expect(copied.area, 30.0);
      expect(copied.tileWidth, input.tileWidth);
    });
  });

  group('LaminateCalculatorInput', () {
    test('creates with required parameters', () {
      const input = LaminateCalculatorInput(area: 25.0);
      expect(input.area, 25.0);
      expect(input.packArea, 2.0);
      expect(input.underlayThickness, 3.0);
      expect(input.perimeter, isNull);
    });

    test('toMap includes perimeter when set', () {
      const input = LaminateCalculatorInput(area: 25.0, perimeter: 20.0);
      final map = input.toMap();
      expect(map['perimeter'], 20.0);
    });

    test('toMap excludes perimeter when null', () {
      const input = LaminateCalculatorInput(area: 25.0);
      final map = input.toMap();
      expect(map.containsKey('perimeter'), isFalse);
    });

    test('isValid returns true for valid input', () {
      const input = LaminateCalculatorInput(area: 25.0);
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false for zero packArea', () {
      const input = LaminateCalculatorInput(area: 25.0, packArea: 0.0);
      expect(input.isValid(), isFalse);
    });

    test('copyWith preserves perimeter', () {
      const input = LaminateCalculatorInput(area: 25.0, perimeter: 15.0);
      final copied = input.copyWith(area: 30.0);
      expect(copied.perimeter, 15.0);
    });
  });

  group('ScreedCalculatorInput', () {
    test('creates with default values', () {
      const input = ScreedCalculatorInput(area: 30.0);
      expect(input.thickness, 50.0);
      expect(input.cementGrade, 400.0);
    });

    test('isValid returns true for valid input', () {
      const input = ScreedCalculatorInput(area: 30.0, thickness: 50.0);
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false for thickness below minimum', () {
      const input = ScreedCalculatorInput(area: 30.0, thickness: 10.0);
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for thickness above maximum', () {
      const input = ScreedCalculatorInput(area: 30.0, thickness: 250.0);
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for invalid cement grade', () {
      const input = ScreedCalculatorInput(area: 30.0, cementGrade: 300.0);
      expect(input.isValid(), isFalse);
    });

    test('isValid returns true for cement grade 500', () {
      const input = ScreedCalculatorInput(area: 30.0, cementGrade: 500.0);
      expect(input.isValid(), isTrue);
    });

    test('getValidationErrors lists all issues', () {
      const input = ScreedCalculatorInput(
        area: 0.0,
        thickness: 10.0,
        cementGrade: 300.0,
      );
      final errors = input.getValidationErrors();
      expect(errors.length, 3);
    });
  });

  group('WallPaintCalculatorInput', () {
    test('creates with default values', () {
      const input = WallPaintCalculatorInput(area: 50.0);
      expect(input.layers, 2);
      expect(input.consumption, 0.15);
      expect(input.windowsArea, 0.0);
      expect(input.doorsArea, 0.0);
    });

    test('isValid returns true for valid input', () {
      const input = WallPaintCalculatorInput(area: 50.0);
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false when openings exceed area', () {
      const input = WallPaintCalculatorInput(
        area: 50.0,
        windowsArea: 30.0,
        doorsArea: 25.0,
      );
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for too many layers', () {
      const input = WallPaintCalculatorInput(area: 50.0, layers: 6);
      expect(input.isValid(), isFalse);
    });

    test('getValidationErrors detects area exceeded', () {
      const input = WallPaintCalculatorInput(
        area: 50.0,
        windowsArea: 60.0,
      );
      final errors = input.getValidationErrors();
      expect(errors.any((e) => e.contains('превышает')), isTrue);
    });
  });

  group('StripFoundationCalculatorInput', () {
    test('creates with required parameters', () {
      const input = StripFoundationCalculatorInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );
      expect(input.perimeter, 40.0);
      expect(input.width, 0.4);
      expect(input.height, 0.8);
    });

    test('isValid returns true for valid input', () {
      const input = StripFoundationCalculatorInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false for perimeter below minimum', () {
      const input = StripFoundationCalculatorInput(
        perimeter: 2.0,
        width: 0.4,
        height: 0.8,
      );
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for width below minimum', () {
      const input = StripFoundationCalculatorInput(
        perimeter: 40.0,
        width: 0.1,
        height: 0.8,
      );
      expect(input.isValid(), isFalse);
    });

    test('toMap returns all values', () {
      const input = StripFoundationCalculatorInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );
      final map = input.toMap();
      expect(map.length, 3);
      expect(map['perimeter'], 40.0);
    });
  });

  group('WarmFloorCalculatorInput', () {
    test('creates with default values', () {
      const input = WarmFloorCalculatorInput(area: 15.0);
      expect(input.power, 150.0);
      expect(input.type, 2);
      expect(input.thermostats, 1);
    });

    test('isValid returns true for valid input', () {
      const input = WarmFloorCalculatorInput(area: 15.0);
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false for power below minimum', () {
      const input = WarmFloorCalculatorInput(area: 15.0, power: 50.0);
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for invalid type', () {
      const input = WarmFloorCalculatorInput(area: 15.0, type: 3);
      expect(input.isValid(), isFalse);
    });

    test('isValid returns true for cable type', () {
      const input = WarmFloorCalculatorInput(area: 15.0, type: 1);
      expect(input.isValid(), isTrue);
    });

    test('getValidationErrors lists power issues', () {
      const input = WarmFloorCalculatorInput(area: 15.0, power: 300.0);
      final errors = input.getValidationErrors();
      expect(errors.any((e) => e.contains('Мощность')), isTrue);
    });
  });

  group('WallpaperCalculatorInput', () {
    test('creates with default values', () {
      const input = WallpaperCalculatorInput(area: 40.0);
      expect(input.rollWidth, 0.53);
      expect(input.rollLength, 10.05);
      expect(input.rapport, 0.0);
      expect(input.wallHeight, 2.5);
    });

    test('isValid returns true for valid input', () {
      const input = WallpaperCalculatorInput(area: 40.0);
      expect(input.isValid(), isTrue);
    });

    test('isValid returns false when openings exceed area', () {
      const input = WallpaperCalculatorInput(
        area: 40.0,
        windowsArea: 25.0,
        doorsArea: 20.0,
      );
      expect(input.isValid(), isFalse);
    });

    test('isValid returns false for negative rapport', () {
      const input = WallpaperCalculatorInput(area: 40.0, rapport: -1.0);
      expect(input.isValid(), isFalse);
    });

    test('toMap includes all fields', () {
      const input = WallpaperCalculatorInput(area: 40.0);
      final map = input.toMap();
      expect(map.length, 7);
      expect(map.containsKey('rapport'), isTrue);
    });

    test('copyWith updates multiple fields', () {
      const input = WallpaperCalculatorInput(area: 40.0);
      final copied = input.copyWith(
        area: 50.0,
        wallHeight: 3.0,
      );
      expect(copied.area, 50.0);
      expect(copied.wallHeight, 3.0);
      expect(copied.rollWidth, input.rollWidth);
    });
  });
}
