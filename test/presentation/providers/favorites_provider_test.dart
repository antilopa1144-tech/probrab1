import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('provider can be created', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final favorites = container.read(favoritesProvider);
      expect(favorites, isList);
    });

    test('notifier can be accessed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      expect(notifier, isA<FavoritesNotifier>());
    });

    test('starts with empty favorites', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final favorites = container.read(favoritesProvider);
      expect(favorites, isEmpty);
    });

    test('isFavorite returns false for non-favorite', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      expect(notifier.isFavorite('mixes_plaster'), false);
    });

    test('toggleFavorite adds existing calculator to favorites', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);

      // 'mixes_plaster' exists in CalculatorRegistry
      await notifier.toggleFavorite('mixes_plaster');

      expect(notifier.isFavorite('mixes_plaster'), true);
      expect(container.read(favoritesProvider), contains('mixes_plaster'));
    });

    test('toggleFavorite removes calculator from favorites', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);

      // Add then remove
      await notifier.toggleFavorite('mixes_plaster');
      expect(notifier.isFavorite('mixes_plaster'), true);

      await notifier.toggleFavorite('mixes_plaster');
      expect(notifier.isFavorite('mixes_plaster'), false);
    });

    test('toggleFavorite does not add non-existing calculator', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);

      // Non-existent calculator should not be added
      await notifier.toggleFavorite('non_existent_calculator_xyz');

      expect(notifier.isFavorite('non_existent_calculator_xyz'), false);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('clearFavorites removes all favorites', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);

      // Add some favorites (using real calculator IDs)
      await notifier.toggleFavorite('mixes_plaster');
      await notifier.toggleFavorite('walls_wallpaper');
      expect(container.read(favoritesProvider).length, 2);

      // Clear all
      await notifier.clearFavorites();
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('favorites persist to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('mixes_plaster');

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('favorite_calculators');

      expect(stored, contains('mixes_plaster'));
    });

    test('clearFavorites removes from SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('mixes_plaster');
      await notifier.clearFavorites();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('favorite_calculators');

      expect(stored, isNull);
    });

    test('handles multiple calculators', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);

      // Add multiple existing calculators
      await notifier.toggleFavorite('mixes_plaster');
      await notifier.toggleFavorite('walls_wallpaper');
      await notifier.toggleFavorite('gypsum_board');

      final favorites = container.read(favoritesProvider);
      expect(favorites.length, 3);
      expect(notifier.isFavorite('mixes_plaster'), true);
      expect(notifier.isFavorite('walls_wallpaper'), true);
      expect(notifier.isFavorite('gypsum_board'), true);
    });
  });
}
