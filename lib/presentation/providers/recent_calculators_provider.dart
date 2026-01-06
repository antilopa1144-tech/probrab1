import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/calculators/calculator_id_migration.dart';
import '../../domain/calculators/calculator_registry.dart';

/// Провайдер для управления недавно использованными калькуляторами.
///
/// Хранит историю последних 10 калькуляторов, которые открывал пользователь.
/// Самый последний калькулятор находится в начале списка.
class RecentCalculatorsNotifier extends StateNotifier<List<String>> {
  RecentCalculatorsNotifier() : super([]) {
    _loadRecent();
  }

  static const String _key = 'recent_calculators';
  static const int _maxRecentCount = 10;

  static bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const <String>[];

    final migrated = CalculatorIdMigration.canonicalizeList(stored);

    // Фильтруем только существующие калькуляторы
    final valid = migrated.where(CalculatorRegistry.exists).toList();

    if (!_listsEqual(stored, valid)) {
      await prefs.setStringList(_key, valid);
    }

    state = valid;
  }

  /// Добавить калькулятор в историю недавних.
  ///
  /// Если калькулятор уже есть в списке, он перемещается в начало.
  /// Если список превышает максимальный размер, старейшие записи удаляются.
  Future<void> addRecent(String calculatorId) async {
    final canonical = CalculatorIdMigration.canonicalize(calculatorId);

    // Проверяем, что калькулятор существует
    if (!CalculatorRegistry.exists(canonical)) return;

    final recent = List<String>.from(state);

    // Удаляем, если уже есть (чтобы переместить в начало)
    recent.remove(canonical);

    // Добавляем в начало
    recent.insert(0, canonical);

    // Ограничиваем размер
    if (recent.length > _maxRecentCount) {
      recent.removeRange(_maxRecentCount, recent.length);
    }

    state = recent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, recent);
  }

  /// Очистить историю недавних калькуляторов
  Future<void> clearRecent() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Удалить конкретный калькулятор из истории
  Future<void> removeRecent(String calculatorId) async {
    final canonical = CalculatorIdMigration.canonicalize(calculatorId);
    final recent = List<String>.from(state);
    recent.remove(canonical);
    state = recent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, recent);
  }
}

final recentCalculatorsProvider =
    StateNotifierProvider<RecentCalculatorsNotifier, List<String>>(
  (ref) => RecentCalculatorsNotifier(),
);
