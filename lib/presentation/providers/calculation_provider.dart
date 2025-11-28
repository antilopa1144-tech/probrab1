import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/calculation.dart';
import '../../data/repositories/calculation_repository.dart';
import '../../core/errors/error_handler.dart';

final calculationRepositoryProvider = Provider<CalculationRepository>((ref) {
  return CalculationRepository();
});

final calculationsProvider = FutureProvider<List<Calculation>>((ref) async {
  try {
    final repo = ref.watch(calculationRepositoryProvider);
    return await repo.getAllCalculations();
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'calculationsProvider');
    return []; // Возвращаем пустой список вместо ошибки
  }
});

final calculationsByCategoryProvider = FutureProvider.family<List<Calculation>, String>(
  (ref, category) async {
    try {
      final repo = ref.watch(calculationRepositoryProvider);
      return await repo.getCalculationsByCategory(category);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace, 'calculationsByCategoryProvider');
      return []; // Возвращаем пустой список вместо ошибки
    }
  },
);

final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final repo = ref.watch(calculationRepositoryProvider);
    return await repo.getStatistics();
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'statisticsProvider');
    return {}; // Возвращаем пустую карту вместо ошибки
  }
});
