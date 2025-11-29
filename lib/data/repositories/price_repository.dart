import '../datasources/local_price_data_source.dart';
import '../models/price_item.dart';

/// Репозиторий цен, который оборачивает источник данных и предоставляет
/// абстракцию для получения прайса по региону с кешированием.
class PriceRepository {
  final LocalPriceDataSource _localDataSource;
  
  // Кеш для загруженных цен по регионам
  final Map<String, List<PriceItem>> _cache = {};
  
  // Время последней загрузки для каждого региона
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Время жизни кеша: 1 час
  static const Duration _cacheLifetime = Duration(hours: 1);

  PriceRepository(this._localDataSource);

  /// Получить цены для региона с кешированием.
  Future<List<PriceItem>> getPrices(String region, {bool forceRefresh = false}) async {
    // Сопоставление регионов с кодами файлов
    final Map<String, String> mapping = {
      'Москва': 'moscow',
      'Санкт‑Петербург': 'spb',
      'Екатеринбург': 'ekaterinburg',
      'Краснодар': 'krasnodar',
      'Регионы РФ': 'regions',
    };
    final code = mapping[region] ?? region.toLowerCase().replaceAll(' ', '');
    
    // Проверяем кеш, если не требуется принудительное обновление
    if (!forceRefresh && _cache.containsKey(code)) {
      final timestamp = _cacheTimestamps[code];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheLifetime) {
        return _cache[code]!;
      }
    }
    
    // Загружаем данные
    final prices = await _localDataSource.getPriceList(code);
    
    // Сохраняем в кеш
    _cache[code] = prices;
    _cacheTimestamps[code] = DateTime.now();
    
    return prices;
  }
  
  /// Очистить кеш для конкретного региона или всего кеша.
  void clearCache([String? region]) {
    if (region != null) {
      final Map<String, String> mapping = {
        'Москва': 'moscow',
        'Санкт‑Петербург': 'spb',
        'Екатеринбург': 'ekaterinburg',
        'Краснодар': 'krasnodar',
        'Регионы РФ': 'regions',
      };
      final code = mapping[region] ?? region.toLowerCase().replaceAll(' ', '');
      _cache.remove(code);
      _cacheTimestamps.remove(code);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
}