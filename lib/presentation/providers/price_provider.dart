import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_price_data_source.dart';
import '../../data/repositories/price_repository.dart';
import '../../data/models/price_item.dart';
import '../../core/errors/error_handler.dart';
import 'region_provider.dart';

/// Provider репозитория цен.
final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository(LocalPriceDataSource());
});

/// Provider списка цен для выбранного региона.
/// Использует кеширование для оптимизации производительности.
final priceListProvider = FutureProvider<List<PriceItem>>((ref) async {
  try {
    final region = ref.watch(regionProvider);
    final repo = ref.watch(priceRepositoryProvider);
    final prices = await repo.getPrices(region);
    
    // Если цены пустые, возвращаем пустой список (не ошибку)
    // Это позволяет приложению работать даже если файл не найден
    return prices;
  } catch (e, stackTrace) {
    // Используем улучшенный ErrorHandler
    ErrorHandler.logError(e, stackTrace, 'PriceProvider');
    
    // Возвращаем пустой список для graceful degradation
    return [];
  }
});