import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foundation_input.dart';
import '../../domain/entities/foundation_result.dart';
import '../../domain/usecases/calculate_strip_foundation.dart';
import '../../core/errors/error_handler.dart';
import 'price_provider.dart';

/// Provider для расчёта ленточного фундамента.
final foundationResultProvider =
    FutureProvider.family<FoundationResult, FoundationInput>((ref, input) async {
  try {
    final priceList = await ref.watch(priceListProvider.future);
    final usecase = CalculateStripFoundation();

    final calculatorResult = usecase.call(
      {
        'perimeter': input.perimeter,
        'width': input.width,
        'height': input.height,
      },
      priceList,
    );

    return FoundationResult(
      concreteVolume: calculatorResult.values['concreteVolume'] ?? 0,
      rebarWeight: calculatorResult.values['rebarWeight'] ?? 0,
      cost: calculatorResult.totalPrice ?? 0,
    );
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace, 'foundationResultProvider');
    // Возвращаем пустой результат вместо ошибки для graceful degradation
    return FoundationResult(
      concreteVolume: 0,
      rebarWeight: 0,
      cost: 0,
    );
  }
});