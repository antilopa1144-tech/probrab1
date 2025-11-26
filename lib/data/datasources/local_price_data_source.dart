import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/price_item.dart';

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
    } catch (e) {
      // Если файл не найден или повреждён, возвращаем пустой список
      // с дефолтными ценами (можно улучшить, добавив fallback)
      debugPrint('Ошибка загрузки цен для региона $regionCode: $e');
      return [];
    }
  }
}