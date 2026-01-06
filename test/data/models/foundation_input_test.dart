import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/foundation_input.dart';

void main() {
  group('FoundationInput', () {
    test('creates with required parameters', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      expect(input.perimeter, 40.0);
      expect(input.width, 0.4);
      expect(input.height, 0.8);
    });

    test('uses default values for optional parameters', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      expect(input.thickness, 0.0);
      expect(input.diameter, 12.0);
      expect(input.rebarCount, 4);
    });

    test('creates with all parameters', () {
      final input = FoundationInput(
        perimeter: 50.0,
        width: 0.5,
        height: 1.0,
        thickness: 0.1,
        diameter: 14.0,
        rebarCount: 6,
      );

      expect(input.perimeter, 50.0);
      expect(input.width, 0.5);
      expect(input.height, 1.0);
      expect(input.thickness, 0.1);
      expect(input.diameter, 14.0);
      expect(input.rebarCount, 6);
    });

    test('allows modification of perimeter', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      input.perimeter = 60.0;
      expect(input.perimeter, 60.0);
    });

    test('allows modification of width', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      input.width = 0.5;
      expect(input.width, 0.5);
    });

    test('allows modification of height', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      input.height = 1.2;
      expect(input.height, 1.2);
    });

    test('allows modification of thickness', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      input.thickness = 0.15;
      expect(input.thickness, 0.15);
    });

    test('allows modification of diameter', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      input.diameter = 16.0;
      expect(input.diameter, 16.0);
    });

    test('allows modification of rebarCount', () {
      final input = FoundationInput(
        perimeter: 40.0,
        width: 0.4,
        height: 0.8,
      );

      input.rebarCount = 8;
      expect(input.rebarCount, 8);
    });

    test('handles zero values', () {
      final input = FoundationInput(
        perimeter: 0.0,
        width: 0.0,
        height: 0.0,
        thickness: 0.0,
        diameter: 0.0,
        rebarCount: 0,
      );

      expect(input.perimeter, 0.0);
      expect(input.width, 0.0);
      expect(input.height, 0.0);
      expect(input.thickness, 0.0);
      expect(input.diameter, 0.0);
      expect(input.rebarCount, 0);
    });

    test('handles large values', () {
      final input = FoundationInput(
        perimeter: 1000.0,
        width: 2.0,
        height: 3.0,
        thickness: 0.5,
        diameter: 32.0,
        rebarCount: 20,
      );

      expect(input.perimeter, 1000.0);
      expect(input.width, 2.0);
      expect(input.height, 3.0);
      expect(input.thickness, 0.5);
      expect(input.diameter, 32.0);
      expect(input.rebarCount, 20);
    });

    test('handles decimal precision', () {
      final input = FoundationInput(
        perimeter: 40.123,
        width: 0.456,
        height: 0.789,
        thickness: 0.111,
        diameter: 12.5,
        rebarCount: 4,
      );

      expect(input.perimeter, closeTo(40.123, 0.001));
      expect(input.width, closeTo(0.456, 0.001));
      expect(input.height, closeTo(0.789, 0.001));
      expect(input.thickness, closeTo(0.111, 0.001));
      expect(input.diameter, closeTo(12.5, 0.001));
    });
  });
}
