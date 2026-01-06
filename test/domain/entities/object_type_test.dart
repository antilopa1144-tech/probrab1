import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';

void main() {
  group('ObjectType', () {
    test('has house value', () {
      expect(ObjectType.house, isNotNull);
      expect(ObjectType.house.name, 'house');
    });

    test('has flat value', () {
      expect(ObjectType.flat, isNotNull);
      expect(ObjectType.flat.name, 'flat');
    });

    test('has garage value', () {
      expect(ObjectType.garage, isNotNull);
      expect(ObjectType.garage.name, 'garage');
    });

    test('has exactly 3 values', () {
      expect(ObjectType.values.length, 3);
    });

    test('values are in expected order', () {
      expect(ObjectType.values[0], ObjectType.house);
      expect(ObjectType.values[1], ObjectType.flat);
      expect(ObjectType.values[2], ObjectType.garage);
    });
  });
}
