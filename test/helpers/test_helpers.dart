import 'package:probrab_ai/data/models/price_item.dart';

/// Вспомогательные функции для тестирования калькуляторов

/// Создать тестовый прайс-лист с указанными SKU и ценами
List<PriceItem> createTestPriceList(Map<String, double> prices) {
  return prices.entries.map((entry) => PriceItem(
    sku: entry.key,
    name: 'Test ${entry.key}',
    price: entry.value,
    unit: 'шт',
    imageUrl: '',
  )).toList();
}

/// Создать пустой прайс-лист
List<PriceItem> createEmptyPriceList() {
  return <PriceItem>[];
}

/// Создать стандартный тестовый прайс-лист с общими материалами
List<PriceItem> createStandardTestPriceList() {
  return [
    PriceItem(sku: 'cement_m400', name: 'Цемент М400', price: 300.0, unit: 'мешок', imageUrl: ''),
    PriceItem(sku: 'sand', name: 'Песок', price: 500.0, unit: 'м³', imageUrl: ''),
    PriceItem(sku: 'plaster', name: 'Штукатурка', price: 250.0, unit: 'кг', imageUrl: ''),
    PriceItem(sku: 'paint', name: 'Краска', price: 400.0, unit: 'кг', imageUrl: ''),
    PriceItem(sku: 'tile', name: 'Плитка', price: 800.0, unit: 'м²', imageUrl: ''),
    PriceItem(sku: 'laminate', name: 'Ламинат', price: 600.0, unit: 'упаковка', imageUrl: ''),
    PriceItem(sku: 'wallpaper', name: 'Обои', price: 500.0, unit: 'рулон', imageUrl: ''),
    PriceItem(sku: 'primer', name: 'Грунтовка', price: 200.0, unit: 'л', imageUrl: ''),
  ];
}

/// Проверить, что результат содержит ожидаемые ключи
bool resultContainsKeys(Map<String, double> values, List<String> expectedKeys) {
  return expectedKeys.every((key) => values.containsKey(key));
}

/// Проверить, что результат содержит все значения больше нуля
bool allValuesPositive(Map<String, double> values) {
  return values.values.every((value) => value >= 0);
}

/// Проверить, что результат содержит все значения больше указанного минимума
bool allValuesGreaterThan(Map<String, double> values, double min) {
  return values.values.every((value) => value > min);
}
