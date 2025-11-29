import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('PriceItem', () {
    test('creates PriceItem with all fields', () {
      final item = PriceItem(
        sku: 'test-sku-1',
        name: 'Test Item',
        price: 100.50,
        unit: 'шт',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(item.sku, equals('test-sku-1'));
      expect(item.name, equals('Test Item'));
      expect(item.price, equals(100.50));
      expect(item.unit, equals('шт'));
      expect(item.imageUrl, equals('https://example.com/image.jpg'));
    });

    test('fromJson creates PriceItem correctly', () {
      final json = {
        'sku': 'json-sku-1',
        'name': 'JSON Item',
        'price': 250.75,
        'unit': 'м²',
        'imageUrl': 'https://example.com/json.jpg',
      };

      final item = PriceItem.fromJson(json);

      expect(item.sku, equals('json-sku-1'));
      expect(item.name, equals('JSON Item'));
      expect(item.price, equals(250.75));
      expect(item.unit, equals('м²'));
      expect(item.imageUrl, equals('https://example.com/json.jpg'));
    });

    test('fromJson handles integer price', () {
      final json = {
        'sku': 'int-price',
        'name': 'Integer Price',
        'price': 100, // int instead of double
        'unit': 'кг',
        'imageUrl': '',
      };

      final item = PriceItem.fromJson(json);

      expect(item.price, equals(100.0));
      expect(item.price, isA<double>());
    });

    test('toJson converts PriceItem to Map correctly', () {
      final item = PriceItem(
        sku: 'to-json-1',
        name: 'To JSON Item',
        price: 99.99,
        unit: 'л',
        imageUrl: 'https://example.com/tojson.jpg',
      );

      final json = item.toJson();

      expect(json['sku'], equals('to-json-1'));
      expect(json['name'], equals('To JSON Item'));
      expect(json['price'], equals(99.99));
      expect(json['unit'], equals('л'));
      expect(json['imageUrl'], equals('https://example.com/tojson.jpg'));
    });

    test('fromJson and toJson are symmetric', () {
      final original = PriceItem(
        sku: 'symmetric-1',
        name: 'Symmetric Item',
        price: 123.45,
        unit: 'м',
        imageUrl: 'https://example.com/symmetric.jpg',
      );

      final json = original.toJson();
      final restored = PriceItem.fromJson(json);

      expect(restored.sku, equals(original.sku));
      expect(restored.name, equals(original.name));
      expect(restored.price, equals(original.price));
      expect(restored.unit, equals(original.unit));
      expect(restored.imageUrl, equals(original.imageUrl));
    });

    test('handles zero price', () {
      final item = PriceItem(
        sku: 'zero-price',
        name: 'Zero Price Item',
        price: 0.0,
        unit: 'шт',
        imageUrl: '',
      );

      expect(item.price, equals(0.0));
    });

    test('handles very large price', () {
      final item = PriceItem(
        sku: 'large-price',
        name: 'Large Price Item',
        price: 999999.99,
        unit: 'шт',
        imageUrl: '',
      );

      expect(item.price, equals(999999.99));
    });

    test('handles empty strings', () {
      final item = PriceItem(
        sku: '',
        name: '',
        unit: '',
        imageUrl: '',
        price: 0.0,
      );

      expect(item.sku, isEmpty);
      expect(item.name, isEmpty);
      expect(item.unit, isEmpty);
      expect(item.imageUrl, isEmpty);
    });
  });
}
