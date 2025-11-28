import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/foundation_result.dart';

void main() {
  group('FoundationResult', () {
    test('creates FoundationResult with all fields', () {
      final result = FoundationResult(
        concreteVolume: 10.5,
        rebarWeight: 500.0,
        cost: 50000.0,
      );

      expect(result.concreteVolume, equals(10.5));
      expect(result.rebarWeight, equals(500.0));
      expect(result.cost, equals(50000.0));
    });

    test('handles zero values', () {
      final result = FoundationResult(
        concreteVolume: 0.0,
        rebarWeight: 0.0,
        cost: 0.0,
      );

      expect(result.concreteVolume, equals(0.0));
      expect(result.rebarWeight, equals(0.0));
      expect(result.cost, equals(0.0));
    });

    test('handles large values', () {
      final result = FoundationResult(
        concreteVolume: 1000.0,
        rebarWeight: 50000.0,
        cost: 5000000.0,
      );

      expect(result.concreteVolume, equals(1000.0));
      expect(result.rebarWeight, equals(50000.0));
      expect(result.cost, equals(5000000.0));
    });

    test('handles decimal precision', () {
      final result = FoundationResult(
        concreteVolume: 12.345,
        rebarWeight: 123.456,
        cost: 12345.67,
      );

      expect(result.concreteVolume, equals(12.345));
      expect(result.rebarWeight, equals(123.456));
      expect(result.cost, equals(12345.67));
    });
  });
}
