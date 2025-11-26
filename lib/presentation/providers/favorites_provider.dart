import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления избранными калькуляторами.
class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  static const String _key = 'favorite_calculators';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    state = favorites;
  }

  Future<void> toggleFavorite(String calculatorId) async {
    final favorites = List<String>.from(state);
    if (favorites.contains(calculatorId)) {
      favorites.remove(calculatorId);
    } else {
      favorites.add(calculatorId);
    }
    state = favorites;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, favorites);
  }

  bool isFavorite(String calculatorId) {
    return state.contains(calculatorId);
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

