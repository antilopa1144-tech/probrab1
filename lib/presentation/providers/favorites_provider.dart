import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/tracker_service_web.dart'
    if (dart.library.io) '../../core/services/tracker_service.dart';
import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';

/// Провайдер для управления избранными калькуляторами.
class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  static const String _key = 'favorite_calculators';

  static bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const <String>[];

    final migrated = CalculatorIdMigration.canonicalizeList(stored);

    // Keep unknown IDs to avoid silently losing user's favorites if a calculator
    // gets removed/renamed; the UI will show them as unavailable with an option
    // to remove.
    if (!_listsEqual(stored, migrated)) {
      await prefs.setStringList(_key, migrated);
    }

    state = migrated;
  }

  Future<void> toggleFavorite(String calculatorId) async {
    final canonical = CalculatorIdMigration.canonicalize(calculatorId);
    final favorites = List<String>.from(state);
    if (favorites.contains(canonical)) {
      favorites.remove(canonical);
      TrackerService.trackFavorite(calculatorId: canonical, added: false);
    } else {
      // Only allow adding favorites for calculators that currently exist.
      if (!CalculatorRegistry.exists(canonical)) return;
      favorites.add(canonical);
      TrackerService.trackFavorite(calculatorId: canonical, added: true);
    }
    state = favorites;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, favorites);
  }

  bool isFavorite(String calculatorId) {
    final canonical = CalculatorIdMigration.canonicalize(calculatorId);
    return state.contains(canonical);
  }

  Future<void> clearFavorites() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>(
  (ref) => FavoritesNotifier(),
);
