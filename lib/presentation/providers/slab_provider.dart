import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foundation_input.dart';
import '../../domain/usecases/calculate_slab.dart';
import '../../domain/entities/foundation_result.dart';
import 'price_provider.dart';

/// Provider для расчёта монолитной плиты.
final slabResultProvider = FutureProvider.family<FoundationResult, FoundationInput>(
    (ref, input) async {
  final priceList = await ref.watch(priceListProvider.future);
  final usecase = CalculateSlab(priceList: priceList);
  return usecase(input);
});