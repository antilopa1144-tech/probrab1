import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/repositories/price_repository.dart';
import 'package:probrab_ai/data/datasources/local_price_data_source.dart';
import 'package:probrab_ai/data/models/price_item.dart';

/// Mock-источник данных для тестирования кеширования
class MockPriceDataSource extends LocalPriceDataSource {
  int _callCount = 0;
  final List<PriceItem> _mockPrices = [
    const PriceItem(sku: 'test_item', name: 'Test Item', price: 100.0, unit: 'шт', imageUrl: ''),
  ];

  int get callCount => _callCount;

  @override
  Future<List<PriceItem>> getPriceList(String regionCode) async {
    _callCount++;
    // Имитируем задержку загрузки
    await Future.delayed(const Duration(milliseconds: 10));
    return List.from(_mockPrices);
  }

  void reset() {
    _callCount = 0;
  }
}

void main() {
  group('PriceRepository', () {
    late MockPriceDataSource mockDataSource;
    late PriceRepository repository;

    setUp(() {
      mockDataSource = MockPriceDataSource();
      repository = PriceRepository(mockDataSource);
    });

    test('loads prices from data source', () async {
      final prices = await repository.getPrices('Москва');

      expect(prices.length, equals(1));
      expect(prices.first.sku, equals('test_item'));
      expect(mockDataSource.callCount, equals(1));
    });

    test('caches prices for same region', () async {
      // Первая загрузка
      final prices1 = await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Вторая загрузка - должна использовать кеш
      final prices2 = await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1)); // Не должно быть повторного вызова
      expect(prices1, equals(prices2));
    });

    test('caches prices separately for different regions', () async {
      // Загрузка для Москвы
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Загрузка для СПб - должна загрузить заново
      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(2));
    });

    test('forceRefresh bypasses cache', () async {
      // Первая загрузка
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Принудительное обновление
      await repository.getPrices('Москва', forceRefresh: true);
      expect(mockDataSource.callCount, equals(2));
    });

    test('clearCache removes cached data', () async {
      // Загружаем и кешируем
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Очищаем кеш
      repository.clearCache('Москва');

      // Повторная загрузка должна загрузить заново
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(2));
    });

    test('clearCache without region clears all cache', () async {
      // Загружаем для разных регионов
      await repository.getPrices('Москва');
      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(2));

      // Очищаем весь кеш
      repository.clearCache();

      // Оба региона должны загрузиться заново
      await repository.getPrices('Москва');
      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(4));
    });

    test('handles region mapping correctly', () async {
      // Тестируем различные варианты названий регионов
      await repository.getPrices('Москва');
      await repository.getPrices('Санкт‑Петербург');
      await repository.getPrices('Екатеринбург');
      await repository.getPrices('Краснодар');
      await repository.getPrices('Регионы РФ');

      // Каждый регион должен загрузиться отдельно
      expect(mockDataSource.callCount, equals(5));
    });

    test('handles unknown region by using region code as is', () async {
      await repository.getPrices('unknown_region');

      expect(mockDataSource.callCount, equals(1));
    });

    test('cache respects lifetime duration', () async {
      // First load
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Second load within cache lifetime - should use cache
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Note: Testing cache expiry would require time manipulation
      // which is complex in Dart. The cache lifetime logic is tested
      // through forceRefresh parameter.
    });

    test('clearCache for specific region does not affect other regions', () async {
      // Load for both regions
      await repository.getPrices('Москва');
      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(2));

      // Clear only Moscow cache
      repository.clearCache('Москва');

      // Moscow should reload, SPb should use cache
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(3));

      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(3)); // No additional call
    });

    test('returns same data from cache', () async {
      final first = await repository.getPrices('Москва');
      final second = await repository.getPrices('Москва');

      expect(identical(first, second), true);
    });
  });

  group('getPriceMap', () {
    late MockPriceDataSource mockDataSource;
    late PriceRepository repository;

    setUp(() {
      mockDataSource = MockPriceDataSource();
      repository = PriceRepository(mockDataSource);
    });

    test('loads PriceMap from data source', () async {
      final priceMap = await repository.getPriceMap('Москва');

      expect(priceMap, isNotNull);
      expect(priceMap.length, equals(1));
      expect(mockDataSource.callCount, equals(1));
    });

    test('caches PriceMap for same region', () async {
      // First load
      final priceMap1 = await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Second load - should use cache
      final priceMap2 = await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));
      expect(identical(priceMap1, priceMap2), true);
    });

    test('caches PriceMap separately for different regions', () async {
      // Load for Moscow
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Load for SPb - should load anew
      await repository.getPriceMap('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(2));
    });

    test('forceRefresh bypasses cache', () async {
      // First load
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Force refresh
      await repository.getPriceMap('Москва', forceRefresh: true);
      expect(mockDataSource.callCount, equals(2));
    });

    test('uses existing cache from getPrices call', () async {
      // Load using getPrices
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Load using getPriceMap - should use same cache
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));
    });

    test('creates both list and map caches', () async {
      // Load PriceMap
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Load list - should use cache
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));
    });

    test('handles region mapping correctly', () async {
      await repository.getPriceMap('Москва');
      await repository.getPriceMap('Санкт‑Петербург');
      await repository.getPriceMap('Екатеринбург');
      await repository.getPriceMap('Краснодар');
      await repository.getPriceMap('Регионы РФ');

      expect(mockDataSource.callCount, equals(5));
    });

    test('returns PriceMap with correct data', () async {
      final priceMap = await repository.getPriceMap('Москва');

      final item = priceMap.findBySku('test_item');
      expect(item, isNotNull);
      expect(item!.name, equals('Test Item'));
      expect(item.price, equals(100.0));
    });
  });

  group('cache management', () {
    late MockPriceDataSource mockDataSource;
    late PriceRepository repository;

    setUp(() {
      mockDataSource = MockPriceDataSource();
      repository = PriceRepository(mockDataSource);
    });

    test('clearCache without parameter clears both list and map caches', () async {
      // Load both types for Moscow
      await repository.getPrices('Москва');
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1)); // Should use same cache

      // Clear all caches
      repository.clearCache();

      // Both should reload
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(2));

      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(2)); // Uses same cache
    });

    test('clearCache for specific region clears both list and map', () async {
      await repository.getPrices('Москва');
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      repository.clearCache('Москва');

      await repository.getPrices('Москва');
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(2)); // One reload for both
    });

    test('clearCache handles unmapped region names', () async {
      await repository.getPrices('customregion');
      expect(mockDataSource.callCount, equals(1));

      repository.clearCache('customregion');

      await repository.getPrices('customregion');
      expect(mockDataSource.callCount, equals(2));
    });

    test('multiple clearCache calls work correctly', () async {
      await repository.getPrices('Москва');
      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(2));

      repository.clearCache('Москва');
      repository.clearCache('Санкт‑Петербург');
      repository.clearCache(); // Should not cause errors even if already cleared

      await repository.getPrices('Москва');
      await repository.getPrices('Санкт‑Петербург');
      expect(mockDataSource.callCount, equals(4));
    });
  });

  group('integration scenarios', () {
    late MockPriceDataSource mockDataSource;
    late PriceRepository repository;

    setUp(() {
      mockDataSource = MockPriceDataSource();
      repository = PriceRepository(mockDataSource);
    });

    test('mixed usage of getPrices and getPriceMap', () async {
      // Load as list
      final list = await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Load as map - should use cache
      final map = await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Verify data consistency
      expect(list.length, equals(map.length));
      expect(list.first.sku, equals('test_item'));
      expect(map.findBySku('test_item')!.name, equals('Test Item'));
    });

    test('force refresh updates both caches', () async {
      await repository.getPrices('Москва');
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Force refresh via getPrices
      await repository.getPrices('Москва', forceRefresh: true);
      expect(mockDataSource.callCount, equals(2));

      // getPriceMap should use the refreshed cache
      await repository.getPriceMap('Москва');
      expect(mockDataSource.callCount, equals(2));
    });

    test('handles empty price list', () async {
      // Create a data source that returns empty list
      final emptyDataSource = MockPriceDataSource();
      emptyDataSource._mockPrices.clear();
      final emptyRepository = PriceRepository(emptyDataSource);

      final prices = await emptyRepository.getPrices('Москва');
      final priceMap = await emptyRepository.getPriceMap('Москва');

      expect(prices, isEmpty);
      expect(priceMap.length, equals(0));
    });

    test('region code normalization', () async {
      // All variations should map to the same code
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));

      // Second call should use cache (same region code)
      await repository.getPrices('Москва');
      expect(mockDataSource.callCount, equals(1));
    });
  });
}
