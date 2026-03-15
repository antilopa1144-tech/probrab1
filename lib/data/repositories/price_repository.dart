import '../../core/constants/region_ids.dart';
import '../datasources/local_price_data_source.dart';
import '../models/price_item.dart';
import '../models/price_map.dart';

/// Репозиторий цен, который оборачивает источник данных и предоставляет
/// абстракцию для получения прайса по региону с кешированием.
class PriceRepository {
  final LocalPriceDataSource _localDataSource;

  // Кеш для загруженных цен по регионам (списки)
  final Map<String, List<PriceItem>> _cache = {};

  // Кеш для оптимизированного поиска (Map структуры)
  final Map<String, PriceMap> _priceMapCache = {};

  // Время последней загрузки для каждого региона
  final Map<String, DateTime> _cacheTimestamps = {};

  // Время жизни кеша: 1 час
  static const Duration _cacheLifetime = Duration(hours: 1);

  PriceRepository(this._localDataSource);

  /// Получить цены для региона с кешированием.
  Future<List<PriceItem>> getPrices(String region, {bool forceRefresh = false}) async {
    final code = RegionCatalog.priceCode(region);

    if (!forceRefresh && _cache.containsKey(code)) {
      final timestamp = _cacheTimestamps[code];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheLifetime) {
        return _cache[code]!;
      }
    }

    final prices = await _localDataSource.getPriceList(code);

    _cache[code] = prices;
    _priceMapCache[code] = PriceMap.fromList(prices);
    _cacheTimestamps[code] = DateTime.now();

    return prices;
  }

  /// Получить оптимизированный PriceMap для региона (O(1) поиск).
  Future<PriceMap> getPriceMap(String region, {bool forceRefresh = false}) async {
    final code = RegionCatalog.priceCode(region);

    if (!forceRefresh && _priceMapCache.containsKey(code)) {
      final timestamp = _cacheTimestamps[code];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheLifetime) {
        return _priceMapCache[code]!;
      }
    }

    await getPrices(region, forceRefresh: forceRefresh);
    return _priceMapCache[code]!;
  }

  /// Очистить кеш для конкретного региона или всего кеша.
  void clearCache([String? region]) {
    if (region != null) {
      final code = RegionCatalog.priceCode(region);
      _cache.remove(code);
      _priceMapCache.remove(code);
      _cacheTimestamps.remove(code);
    } else {
      _cache.clear();
      _priceMapCache.clear();
      _cacheTimestamps.clear();
    }
  }
}
