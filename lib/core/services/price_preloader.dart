import 'package:probrab_ai/data/repositories/price_repository.dart';

/// Сервис для предзагрузки цен при старте приложения.
///
/// Загружает цены для всех регионов в фоновом режиме,
/// чтобы ускорить последующие запросы.
///
/// ## Пример использования:
///
/// ```dart
/// // В main.dart или при старте приложения
/// await PricePreloader.preloadAll();
/// ```
class PricePreloader {
  /// Предзагрузить цены для всех регионов.
  ///
  /// Выполняется асинхронно в фоне, не блокирует UI.
  static Future<void> preloadAll(PriceRepository repository) async {
    final regions = [
      'Москва',
      'Санкт‑Петербург',
      'Екатеринбург',
      'Краснодар',
      'Регионы РФ',
    ];

    // Загружаем все регионы параллельно
    await Future.wait(regions.map((region) => repository.getPrices(region)));
  }

  /// Предзагрузить цены для текущего региона.
  ///
  /// Используется при смене региона для предзагрузки следующего.
  static Future<void> preloadRegion(
    PriceRepository repository,
    String region,
  ) async {
    await repository.getPrices(region);
  }

  /// Предзагрузить цены для соседних регионов.
  ///
  /// Загружает цены для регионов, которые пользователь может выбрать.
  static Future<void> preloadAdjacentRegions(
    PriceRepository repository,
    String currentRegion,
  ) async {
    final regionMap = {
      'Москва': ['Санкт‑Петербург', 'Екатеринбург'],
      'Санкт‑Петербург': ['Москва', 'Екатеринбург'],
      'Екатеринбург': ['Москва', 'Санкт‑Петербург', 'Краснодар'],
      'Краснодар': ['Екатеринбург', 'Регионы РФ'],
      'Регионы РФ': ['Краснодар', 'Москва'],
    };

    final adjacentRegions = regionMap[currentRegion] ?? [];
    await Future.wait(
      adjacentRegions.map((region) => repository.getPrices(region)),
    );
  }
}
