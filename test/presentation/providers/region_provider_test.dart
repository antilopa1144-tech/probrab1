import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/region_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with default region Москва', () {
      final region = container.read(regionProvider);
      expect(region, 'Москва');
    });

    test('setRegion updates state immediately', () async {
      await container.read(regionProvider.notifier).setRegion('Краснодар');

      final region = container.read(regionProvider);
      expect(region, 'Краснодар');
    });

    test('setRegion saves to SharedPreferences', () async {
      await container.read(regionProvider.notifier).setRegion('Екатеринбург');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('region'), 'Екатеринбург');
    });

    test('handles various region names', () async {
      final regions = ['Москва', 'СПб', 'Краснодар', 'Екатеринбург', 'Регионы'];

      for (final regionName in regions) {
        await container.read(regionProvider.notifier).setRegion(regionName);
        expect(container.read(regionProvider), regionName);
      }
    });

    test('handles Cyrillic names correctly', () async {
      await container.read(regionProvider.notifier).setRegion('Санкт-Петербург');
      expect(container.read(regionProvider), 'Санкт-Петербург');
    });
  });
}
