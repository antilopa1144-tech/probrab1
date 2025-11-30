import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foundation_input.dart';
import '../../domain/usecases/calculate_slab.dart';
import '../../domain/entities/foundation_result.dart';
import '../../core/errors/error_handler.dart';
import 'price_provider.dart';

/// Provider для расчёта монолитной плиты.
final slabResultProvider = FutureProvider.family<FoundationResult, FoundationInput>(
    (ref, input) async {
  try {
    final priceList = await ref.watch(priceListProvider.future);
    final usecase = CalculateSlab();
    final inputs = {
      'area': input.width * input.height,
      'thickness': input.thickness,
    };
    final result = usecase.calculate(inputs, priceList);
    
    return FoundationResult(
      concreteVolume: result.values['concreteVolume'] ?? 0.0,
      rebarWeight: result.values['rebarWeight'] ?? 0.0,
      cost: result.totalPrice ?? 0.0,
    );
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'slabResultProvider');
    // Возвращаем пустой результат вместо ошибки для graceful degradation
    return FoundationResult(
      concreteVolume: 0,
      rebarWeight: 0,
      cost: 0,
    );
  }
});