import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/foundation_provider.dart';
import 'package:probrab_ai/presentation/providers/price_provider.dart';
import 'package:probrab_ai/data/models/foundation_input.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/entities/foundation_result.dart';

void main() {
  group('FoundationProvider', () {
    test('foundationResultProvider calculates strip foundation', () async {
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
        perimeter: 40,
        width: 0.4,
        height: 0.8,
      );

      final result = await container.read(foundationResultProvider(input).future);

      expect(result, isA<FoundationResult>());
      expect(result.concreteVolume, greaterThan(0));
    });

    test('foundationResultProvider returns zero values on error', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.error('Test error')),
        ],
      );
      addTearDown(container.dispose);

      final input = FoundationInput(
        perimeter: 40,
        width: 0.4,
        height: 0.8,
      );

      final result = await container.read(foundationResultProvider(input).future);

      expect(result.concreteVolume, 0);
      expect(result.rebarWeight, 0);
      expect(result.cost, 0);
    });

    test('foundationResultProvider handles different perimeter values', () async {
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

      final perimeters = [20.0, 40.0, 60.0, 100.0];

      for (final perimeter in perimeters) {
        final input = FoundationInput(
          perimeter: perimeter,
          width: 0.4,
          height: 0.8,
        );

        final result = await container.read(foundationResultProvider(input).future);

        expect(result, isA<FoundationResult>());
        expect(result.concreteVolume, greaterThanOrEqualTo(0));
      }
    });

    test('foundationResultProvider handles different dimensions', () async {
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

      final inputs = [
        FoundationInput(perimeter: 40, width: 0.3, height: 0.6),
        FoundationInput(perimeter: 40, width: 0.4, height: 0.8),
        FoundationInput(perimeter: 40, width: 0.5, height: 1.0),
      ];

      for (final input in inputs) {
        final result = await container.read(foundationResultProvider(input).future);

        expect(result, isA<FoundationResult>());
        expect(result.concreteVolume, greaterThan(0));
      }
    });

    test('foundationResultProvider with empty price list returns zero cost', () async {
      final container = ProviderContainer(
        overrides: [
          priceListProvider.overrideWith((ref) => Future.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      final input = FoundationInput(
        perimeter: 40,
        width: 0.4,
        height: 0.8,
      );

      final result = await container.read(foundationResultProvider(input).future);

      expect(result, isA<FoundationResult>());
      expect(result.cost, 0);
    });

    test('foundationResultProvider calculates with rebar parameters', () async {
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
        perimeter: 40,
        width: 0.4,
        height: 0.8,
        diameter: 12,
        rebarCount: 4,
      );

      final result = await container.read(foundationResultProvider(input).future);

      expect(result, isA<FoundationResult>());
      expect(result.rebarWeight, greaterThanOrEqualTo(0));
    });
  });
}
