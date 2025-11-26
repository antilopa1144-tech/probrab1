import '../datasources/local_price_data_source.dart';
import '../models/price_item.dart';

/// Репозиторий цен, который оборачивает источник данных и предоставляет
/// абстракцию для получения прайса по региону.
class PriceRepository {
  final LocalPriceDataSource _localDataSource;

  PriceRepository(this._localDataSource);

  Future<List<PriceItem>> getPrices(String region) async {
    // Сопоставление регионов с кодами файлов
    final Map<String, String> mapping = {
      'Москва': 'moscow',
      'Санкт‑Петербург': 'spb',
      'Екатеринбург': 'ekaterinburg',
      'Краснодар': 'krasnodar',
      'Регионы РФ': 'regions',
    };
    final code = mapping[region] ?? region.toLowerCase().replaceAll(' ', '');
    return _localDataSource.getPriceList(code);
  }
}