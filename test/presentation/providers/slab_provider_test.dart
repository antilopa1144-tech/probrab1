import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/slab_provider.dart';
import 'package:probrab_ai/presentation/providers/price_provider.dart';
import 'package:probrab_ai/data/models/foundation_input.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/entities/foundation_result.dart';

void main() {
  group('SlabProvider', () {
    test('slabResultProvider calculates slab foundation', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [
                PriceItem(
                  sku: 'concrete',
                  name: 'Бетон',
                  unit: 'м³',
                  price: 5000,
                  imageUrl: '',
                ),
                PriceItem(
                  sku: 'rebar',
                  name: 'Арматура',
                  unit: 'кг',
                  price: 50,
                  imageUrl: '',
                ),
              ])),
        ],
      );
      addTearDown(container.dispose);

      final input = FoundationInput(
        perimeter: 0,
        width: 10,
        height: 8,
        thickness: 0.2,
      );

      final result = await container.read(slabResultProvider(input).future);

      expect(result, isA<FoundationResult>());
      expect(result.concreteVolume, greaterThan(0));
    });

    test('slabResultProvider returns zero values on error', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.error('Test error')),
        ],
      );
      addTearDown(container.dispose);

      final input = FoundationInput(
        perimeter: 0,
        width: 10,
        height: 8,
        thickness: 0.2,
      );

      final result = await container.read(slabResultProvider(input).future);

      expect(result.concreteVolume, 0);
      expect(result.rebarWeight, 0);
      expect(result.cost, 0);
    });

    test('slabResultProvider handles different areas', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [
                PriceItem(
                  sku: 'concrete',
                  name: 'Бетон',
                  unit: 'м³',
                  price: 5000,
                  imageUrl: '',
                ),
              ])),
        ],
      );
      addTearDown(container.dispose);

      final areas = [
        [5.0, 5.0],  // 25 м²
        [10.0, 8.0], // 80 м²
        [12.0, 10.0], // 120 м²
      ];

      for (final area in areas) {
        final input = FoundationInput(
          perimeter: 0,
          width: area[0],
          height: area[1],
          thickness: 0.2,
        );

        final result = await container.read(slabResultProvider(input).future);

        expect(result, isA<FoundationResult>());
        expect(result.concreteVolume, greaterThan(0));
      }
    });

    test('slabResultProvider handles different thicknesses', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [
                PriceItem(
                  sku: 'concrete',
                  name: 'Бетон',
                  unit: 'м³',
                  price: 5000,
                  imageUrl: '',
                ),
              ])),
        ],
      );
      addTearDown(container.dispose);

      final thicknesses = [0.15, 0.2, 0.25, 0.3];

      for (final thickness in thicknesses) {
        final input = FoundationInput(
          perimeter: 0,
          width: 10,
          height: 8,
          thickness: thickness,
        );

        final result = await container.read(slabResultProvider(input).future);

        expect(result, isA<FoundationResult>());
        expect(result.concreteVolume, greaterThan(0));
      }
    });

    test('slabResultProvider with empty price list returns zero cost', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      final input = FoundationInput(
        perimeter: 0,
        width: 10,
        height: 8,
        thickness: 0.2,
      );

      final result = await container.read(slabResultProvider(input).future);

      expect(result, isA<FoundationResult>());
      expect(result.cost, 0);
    });

    test('slabResultProvider calculates rebar weight', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [
                PriceItem(
                  sku: 'concrete',
                  name: 'Бетон',
                  unit: 'м³',
                  price: 5000,
                  imageUrl: '',
                ),
                PriceItem(
                  sku: 'rebar',
                  name: 'Арматура',
                  unit: 'кг',
                  price: 50,
                  imageUrl: '',
                ),
              ])),
        ],
      );
      addTearDown(container.dispose);

      final input = FoundationInput(
        perimeter: 0,
        width: 10,
        height: 8,
        thickness: 0.2,
      );

      final result = await container.read(slabResultProvider(input).future);

      expect(result, isA<FoundationResult>());
      expect(result.rebarWeight, greaterThanOrEqualTo(0));
    });

    test('slabResultProvider volume increases with area', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [
                PriceItem(
                  sku: 'concrete',
                  name: 'Бетон',
                  unit: 'м³',
                  price: 5000,
                  imageUrl: '',
                ),
              ])),
        ],
      );
      addTearDown(container.dispose);

      final smallInput = FoundationInput(
        perimeter: 0,
        width: 5,
        height: 5,
        thickness: 0.2,
      );

      final largeInput = FoundationInput(
        perimeter: 0,
        width: 10,
        height: 10,
        thickness: 0.2,
      );

      final smallResult = await container.read(slabResultProvider(smallInput).future);
      final largeResult = await container.read(slabResultProvider(largeInput).future);

      expect(largeResult.concreteVolume, greaterThan(smallResult.concreteVolume));
    });
  });
}
