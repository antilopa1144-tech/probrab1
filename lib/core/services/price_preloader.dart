import '../../core/constants/region_ids.dart';
import '../../data/repositories/price_repository.dart';

/// Сервис для предзагрузки цен при старте приложения.
class PricePreloader {
  /// Предзагрузить цены для всех регионов.
  static Future<void> preloadAll(PriceRepository repository) async {
    const regions = [
      RegionId.moscow,
      RegionId.spb,
      RegionId.ekaterinburg,
      RegionId.krasnodar,
      RegionId.regions,
    ];

    await Future.wait(regions.map((region) => repository.getPrices(region)));
  }

  /// Предзагрузить цены для текущего региона.
  static Future<void> preloadRegion(
    PriceRepository repository,
    String region,
  ) async {
    await repository.getPrices(region);
  }

  /// Предзагрузить цены для соседних регионов.
  static Future<void> preloadAdjacentRegions(
    PriceRepository repository,
    String currentRegion,
  ) async {
    const regionMap = {
      RegionId.moscow: [RegionId.spb, RegionId.ekaterinburg],
      RegionId.spb: [RegionId.moscow, RegionId.ekaterinburg],
      RegionId.ekaterinburg: [RegionId.moscow, RegionId.spb, RegionId.krasnodar],
      RegionId.krasnodar: [RegionId.ekaterinburg, RegionId.regions],
      RegionId.regions: [RegionId.krasnodar, RegionId.moscow],
    };

    final normalizedRegion = RegionCatalog.normalize(currentRegion);
    final adjacentRegions = regionMap[normalizedRegion] ?? const <String>[];
    await Future.wait(adjacentRegions.map((region) => repository.getPrices(region)));
  }
}
