import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/errors/error_handler.dart';
import '../../core/migrations/migration_flag_store_provider.dart';
import '../../data/models/calculation.dart';
import '../../data/repositories/calculation_repository.dart';

final calculationRepositoryProvider = Provider<CalculationRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw StateError('Isar не инициализирован');
  }
  final flagStore = ref.watch(migrationFlagStoreProvider);
  return CalculationRepository(isar, flagStore: flagStore);
});

/// Провайдер для всех расчётов с кэшированием
final calculationsProvider =
    FutureProvider.autoDispose<List<Calculation>>((ref) async {
  try {
    final repo = ref.watch(calculationRepositoryProvider);
    final calculations = await repo.getAllCalculations();
    // Сортируем по дате (новые первые)
    calculations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return calculations;
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'calculationsProvider');
    // Возвращаем пустой список вместо ошибки
    return [];
  }
});

/// Провайдер для расчётов по категории с кэшированием
final calculationsByCategoryProvider = FutureProvider.autoDispose
    .family<List<Calculation>, String>((ref, category) async {
  try {
    final repo = ref.watch(calculationRepositoryProvider);
    final calculations = await repo.getCalculationsByCategory(category);
    calculations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return calculations;
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'calculationsByCategoryProvider');
    // Возвращаем пустой список вместо ошибки
    return [];
  }
});

/// Провайдер для статистики с кэшированием
final statisticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final repo = ref.watch(calculationRepositoryProvider);
    return await repo.getStatistics();
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'statisticsProvider');
    // Возвращаем пустую карту вместо ошибки
    return {};
  }
});

/// Провайдер для пагинации расчётов
class PaginatedCalculationsNotifier
    extends StateNotifier<AsyncValue<List<Calculation>>> {
  PaginatedCalculationsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _loadMore();
  }

  final CalculationRepository _repository;
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;

  Future<void> _loadMore() async {
    if (!_hasMore) return;

    try {
      final allCalculations = await _repository.getAllCalculations();
      allCalculations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final startIndex = _currentPage * _pageSize;
      final endIndex =
          (startIndex + _pageSize).clamp(0, allCalculations.length);

      if (startIndex >= allCalculations.length) {
        _hasMore = false;
        return;
      }

      final currentData = state.valueOrNull ?? [];
      final newData = allCalculations.sublist(startIndex, endIndex);

      state = AsyncValue.data([...currentData, ...newData]);
      _currentPage++;
      _hasMore = endIndex < allCalculations.length;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() => _loadMore();

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _loadMore();
  }
}

final paginatedCalculationsProvider = StateNotifierProvider.autoDispose<
    PaginatedCalculationsNotifier, AsyncValue<List<Calculation>>>((ref) {
  final repo = ref.watch(calculationRepositoryProvider);
  return PaginatedCalculationsNotifier(repo);
});
