import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_price_data_source.dart';
import '../../data/repositories/price_repository.dart';
import '../../data/models/price_item.dart';
import 'region_provider.dart';

/// Provider репозитория цен.
final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository(LocalPriceDataSource());
});

/// Provider списка цен для выбранного региона.
final priceListProvider = FutureProvider<List<PriceItem>>((ref) async {
  try {
    final region = ref.watch(regionProvider);
    final repo = ref.watch(priceRepositoryProvider);
    final prices = await repo.getPrices(region);
    
    // Если цены пустые, возвращаем пустой список (не ошибку)
    // Это позволяет приложению работать даже если файл не найден
    return prices;
  } catch (e) {
    // Логируем ошибку, но возвращаем пустой список для graceful degradation
    debugPrint('Ошибка загрузки цен: $e');
    return [];
  }
});