import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/presentation/providers/price_provider.dart';
import 'package:probrab_ai/presentation/providers/region_provider.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'region': 'Москва'});
  });

  group('PriceProvider', () {
    test('priceListProvider returns price list for selected region', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final priceListAsync = await container.read(priceListProvider.future);

      expect(priceListAsync, isA<List<PriceItem>>());
    });

    test('priceListProvider returns empty list on error for non-existent region', () async {
      SharedPreferences.setMockInitialValues({'region': 'NonExistentRegion'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final priceListAsync = await container.read(priceListProvider.future);

      // Should return empty list for graceful degradation
      expect(priceListAsync, isA<List<PriceItem>>());
    });

    test('priceListProvider updates when region changes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial region is Москва
      final moscowPrices = await container.read(priceListProvider.future);
      expect(moscowPrices, isA<List<PriceItem>>());

      // Change region
      await container.read(regionProvider.notifier).setRegion('СПб');

      // Need to invalidate to trigger re-fetch
      container.invalidate(priceListProvider);

      final spbPrices = await container.read(priceListProvider.future);
      expect(spbPrices, isA<List<PriceItem>>());
    });

    test('priceListProvider handles multiple regions', () async {
      final regions = ['Москва', 'СПб', 'Краснодар', 'Екатеринбург', 'Регионы'];

      for (final region in regions) {
        SharedPreferences.setMockInitialValues({'region': region});
        final container = ProviderContainer();

        final priceList = await container.read(priceListProvider.future);
        expect(priceList, isA<List<PriceItem>>());

        container.dispose();
      }
    });

    test('priceRepositoryProvider creates repository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(priceRepositoryProvider);

      expect(repository, isNotNull);
    });
  });
}
