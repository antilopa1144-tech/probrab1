import 'region_ids.dart';

/// Константы регионов и ценовые коэффициенты.
class RegionConstants {
  /// Поддерживаемые регионы РФ.
  static const List<String> regions = RegionCatalog.supported;

  /// Ценовые коэффициенты по регионам (относительно Москвы = 1.0)
  static const Map<String, double> priceCoefficients = {
    RegionId.moscow: 1.0,
    RegionId.spb: 0.95,
    RegionId.ekaterinburg: 0.75,
    RegionId.krasnodar: 0.80,
    RegionId.novosibirsk: 0.70,
    RegionId.kazan: 0.72,
    RegionId.nizhnyNovgorod: 0.73,
    RegionId.chelyabinsk: 0.68,
    RegionId.samara: 0.71,
    RegionId.regions: 0.65,
  };

  /// Коэффициенты стоимости работ по регионам.
  static const Map<String, double> laborCoefficients = {
    RegionId.moscow: 1.0,
    RegionId.spb: 0.90,
    RegionId.ekaterinburg: 0.60,
    RegionId.krasnodar: 0.65,
    RegionId.novosibirsk: 0.55,
    RegionId.kazan: 0.58,
    RegionId.nizhnyNovgorod: 0.60,
    RegionId.chelyabinsk: 0.52,
    RegionId.samara: 0.57,
    RegionId.regions: 0.50,
  };

  /// Получить ценовой коэффициент региона.
  static double getPriceCoefficient(String region) {
    return priceCoefficients[RegionCatalog.normalize(region)] ?? 0.65;
  }

  /// Получить коэффициент стоимости работ.
  static double getLaborCoefficient(String region) {
    return laborCoefficients[RegionCatalog.normalize(region)] ?? 0.50;
  }
}
