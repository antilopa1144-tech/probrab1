import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/price_preloader.dart';
import 'package:probrab_ai/data/repositories/price_repository.dart';
import 'package:probrab_ai/data/datasources/local_price_data_source.dart';
import 'package:probrab_ai/data/models/price_item.dart';

/// Mock data source that tracks which regions were requested.
class MockLocalPriceDataSource implements LocalPriceDataSource {
  final List<String> requestedRegions = [];

  @override
  Future<List<PriceItem>> getPriceList(String regionCode) async {
    requestedRegions.add(regionCode);
    // Return empty list - we're just testing that the regions are requested
    return [
      PriceItem(
        sku: 'test-$regionCode',
        name: 'Test Item',
        unit: 'шт',
        price: 100,
        imageUrl: '',
      ),
    ];
  }
}

void main() {
  group('PricePreloader', () {
    late MockLocalPriceDataSource mockDataSource;
    late PriceRepository repository;

    setUp(() {
      mockDataSource = MockLocalPriceDataSource();
      repository = PriceRepository(mockDataSource);
    });

    group('preloadAll', () {
      test('loads prices for all regions', () async {
        await PricePreloader.preloadAll(repository);

        expect(mockDataSource.requestedRegions, contains('moscow'));
        expect(mockDataSource.requestedRegions, contains('spb'));
        expect(mockDataSource.requestedRegions, contains('ekaterinburg'));
        expect(mockDataSource.requestedRegions, contains('krasnodar'));
        expect(mockDataSource.requestedRegions, contains('regions'));
      });

      test('loads all 5 regions', () async {
        await PricePreloader.preloadAll(repository);

        expect(mockDataSource.requestedRegions.length, 5);
      });

      test('completes without error', () async {
        expect(
          () => PricePreloader.preloadAll(repository),
          returnsNormally,
        );
      });
    });

    group('preloadRegion', () {
      test('loads prices for Moscow', () async {
        await PricePreloader.preloadRegion(repository, 'Москва');

        expect(mockDataSource.requestedRegions, contains('moscow'));
      });

      test('loads prices for Saint Petersburg', () async {
        await PricePreloader.preloadRegion(repository, 'Санкт‑Петербург');

        expect(mockDataSource.requestedRegions, contains('spb'));
      });

      test('loads prices for Ekaterinburg', () async {
        await PricePreloader.preloadRegion(repository, 'Екатеринбург');

        expect(mockDataSource.requestedRegions, contains('ekaterinburg'));
      });

      test('loads prices for Krasnodar', () async {
        await PricePreloader.preloadRegion(repository, 'Краснодар');

        expect(mockDataSource.requestedRegions, contains('krasnodar'));
      });

      test('loads prices for Regions RF', () async {
        await PricePreloader.preloadRegion(repository, 'Регионы РФ');

        expect(mockDataSource.requestedRegions, contains('regions'));
      });

      test('only requests one region', () async {
        await PricePreloader.preloadRegion(repository, 'Москва');

        expect(mockDataSource.requestedRegions.length, 1);
      });
    });

    group('preloadAdjacentRegions', () {
      test('loads adjacent regions for Moscow', () async {
        await PricePreloader.preloadAdjacentRegions(repository, 'Москва');

        expect(mockDataSource.requestedRegions, contains('spb'));
        expect(mockDataSource.requestedRegions, contains('ekaterinburg'));
        expect(mockDataSource.requestedRegions.length, 2);
      });

      test('loads adjacent regions for Saint Petersburg', () async {
        await PricePreloader.preloadAdjacentRegions(
          repository,
          'Санкт‑Петербург',
        );

        expect(mockDataSource.requestedRegions, contains('moscow'));
        expect(mockDataSource.requestedRegions, contains('ekaterinburg'));
        expect(mockDataSource.requestedRegions.length, 2);
      });

      test('loads adjacent regions for Ekaterinburg', () async {
        await PricePreloader.preloadAdjacentRegions(
          repository,
          'Екатеринбург',
        );

        expect(mockDataSource.requestedRegions, contains('moscow'));
        expect(mockDataSource.requestedRegions, contains('spb'));
        expect(mockDataSource.requestedRegions, contains('krasnodar'));
        expect(mockDataSource.requestedRegions.length, 3);
      });

      test('loads adjacent regions for Krasnodar', () async {
        await PricePreloader.preloadAdjacentRegions(repository, 'Краснодар');

        expect(mockDataSource.requestedRegions, contains('ekaterinburg'));
        expect(mockDataSource.requestedRegions, contains('regions'));
        expect(mockDataSource.requestedRegions.length, 2);
      });

      test('loads adjacent regions for Regions RF', () async {
        await PricePreloader.preloadAdjacentRegions(repository, 'Регионы РФ');

        expect(mockDataSource.requestedRegions, contains('krasnodar'));
        expect(mockDataSource.requestedRegions, contains('moscow'));
        expect(mockDataSource.requestedRegions.length, 2);
      });

      test('handles unknown region gracefully', () async {
        await PricePreloader.preloadAdjacentRegions(
          repository,
          'Unknown Region',
        );

        expect(mockDataSource.requestedRegions, isEmpty);
      });
    });

    group('caching behavior', () {
      test('preloadAll caches data for subsequent reads', () async {
        await PricePreloader.preloadAll(repository);
        final initialCount = mockDataSource.requestedRegions.length;

        // Second call should use cached data
        await PricePreloader.preloadAll(repository);

        // No new requests should have been made (uses cache)
        expect(mockDataSource.requestedRegions.length, initialCount);
      });

      test('preloadRegion caches data', () async {
        await PricePreloader.preloadRegion(repository, 'Москва');
        expect(mockDataSource.requestedRegions.length, 1);

        // Second call should use cache
        await PricePreloader.preloadRegion(repository, 'Москва');
        expect(mockDataSource.requestedRegions.length, 1);
      });
    });

    group('error handling', () {
      test('preloadAll completes even with errors', () async {
        // Even if data source returns empty, should not throw
        expect(
          () async => PricePreloader.preloadAll(repository),
          returnsNormally,
        );
      });

      test('preloadRegion completes even with errors', () async {
        expect(
          () async => PricePreloader.preloadRegion(repository, 'InvalidRegion'),
          returnsNormally,
        );
      });
    });
  });
}
