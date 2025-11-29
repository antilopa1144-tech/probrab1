import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/repositories/price_repository.dart';
import 'package:probrab_ai/data/datasources/local_price_data_source.dart';
import 'package:probrab_ai/data/models/price_item.dart';

/// Mock-источник данных для тестирования кеширования
class MockPriceDataSource extends LocalPriceDataSource {
  int _callCount = 0;
  final List<PriceItem> _mockPrices = [
    PriceItem(sku: 'test_item', name: 'Test Item', price: 100.0, unit: 'шт', imageUrl: ''),
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
  });
}
