import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/datasources/local_price_data_source.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalPriceDataSource', () {
    late LocalPriceDataSource dataSource;

    setUp(() {
      dataSource = LocalPriceDataSource();
    });

    group('getPriceList', () {
      test('returns list of PriceItems for moscow region', () async {
        final prices = await dataSource.getPriceList('moscow');

        expect(prices, isNotEmpty);
        expect(prices, isA<List<PriceItem>>());
      });

      test('returns list of PriceItems for spb region', () async {
        final prices = await dataSource.getPriceList('spb');

        expect(prices, isNotEmpty);
        expect(prices, isA<List<PriceItem>>());
      });

      test('returns list of PriceItems for ekaterinburg region', () async {
        final prices = await dataSource.getPriceList('ekaterinburg');

        expect(prices, isNotEmpty);
        expect(prices, isA<List<PriceItem>>());
      });

      test('returns list of PriceItems for krasnodar region', () async {
        final prices = await dataSource.getPriceList('krasnodar');

        expect(prices, isNotEmpty);
        expect(prices, isA<List<PriceItem>>());
      });

      test('returns list of PriceItems for regions', () async {
        final prices = await dataSource.getPriceList('regions');

        expect(prices, isNotEmpty);
        expect(prices, isA<List<PriceItem>>());
      });

      test('returns empty list for non-existent region', () async {
        final prices = await dataSource.getPriceList('nonexistent_region');

        expect(prices, isEmpty);
      });

      test('handles case insensitivity in region code', () async {
        final prices1 = await dataSource.getPriceList('MOSCOW');
        final prices2 = await dataSource.getPriceList('Moscow');
        final prices3 = await dataSource.getPriceList('moscow');

        expect(prices1, isNotEmpty);
        expect(prices2, isNotEmpty);
        expect(prices3, isNotEmpty);
        expect(prices1.length, prices3.length);
      });

      test('price items have required fields', () async {
        final prices = await dataSource.getPriceList('moscow');

        expect(prices, isNotEmpty);

        final firstItem = prices.first;
        expect(firstItem.sku, isNotEmpty);
        expect(firstItem.name, isNotEmpty);
        expect(firstItem.price, greaterThanOrEqualTo(0));
      });

      test('prices contain various material types', () async {
        final prices = await dataSource.getPriceList('moscow');

        // Should contain various types of materials
        expect(prices.length, greaterThan(10));
      });
    });

    group('multiple region comparison', () {
      test('different regions may have different prices', () async {
        final moscowPrices = await dataSource.getPriceList('moscow');
        final regionsPrices = await dataSource.getPriceList('regions');

        expect(moscowPrices, isNotEmpty);
        expect(regionsPrices, isNotEmpty);

        // Prices might differ between regions (or be the same)
        // Just verify both loaded correctly
        expect(moscowPrices.first.sku, isNotEmpty);
        expect(regionsPrices.first.sku, isNotEmpty);
      });
    });
  });
}
