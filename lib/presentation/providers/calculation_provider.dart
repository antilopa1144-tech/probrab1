import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/calculation.dart';
import '../../data/repositories/calculation_repository.dart';

final calculationRepositoryProvider = Provider<CalculationRepository>((ref) {
  return CalculationRepository();
});

final calculationsProvider = FutureProvider<List<Calculation>>((ref) async {
  final repo = ref.watch(calculationRepositoryProvider);
  return await repo.getAllCalculations();
});

final calculationsByCategoryProvider = FutureProvider.family<List<Calculation>, String>(
  (ref, category) async {
    final repo = ref.watch(calculationRepositoryProvider);
    return await repo.getCalculationsByCategory(category);
  },
);

final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(calculationRepositoryProvider);
  return await repo.getStatistics();
});
