import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/price_item.dart';
import '../../core/errors/error_handler.dart';

/// Источник данных цен, загружающий JSON файлы из assets.
class LocalPriceDataSource {
  /// Загрузка прайс‑листа по региону. Файлы хранятся в
  /// `assets/json/prices_<region>.json`. Например: `prices_moscow.json`.
  Future<List<PriceItem>> getPriceList(String regionCode) async {
    try {
      final assetPath = 'assets/json/prices_${regionCode.toLowerCase()}.json';
      final data = await rootBundle.loadString(assetPath);
      final list = json.decode(data) as List<dynamic>;
      return list.map((e) => PriceItem.fromJson(e)).toList();
    } on FormatException catch (e, stackTrace) {
      // Ошибка парсинга JSON
      ErrorHandler.logError(e, stackTrace, 'LocalPriceDataSource.getPriceList');
      return [];
    } on MissingPluginException catch (e, stackTrace) {
      // Файл не найден
      ErrorHandler.logError(e, stackTrace, 'LocalPriceDataSource.getPriceList');
      return [];
    } catch (e, stackTrace) {
      // Другие ошибки
      ErrorHandler.logError(e, stackTrace, 'LocalPriceDataSource.getPriceList');
      return [];
    }
  }
}