import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/data/models/price_map.dart';

void main() {
  group('PriceMap', () {
    late List<PriceItem> testPriceList;
    late PriceMap priceMap;

    setUp(() {
      testPriceList = [
        PriceItem(
          sku: 'concrete_m300',
          name: 'Бетон М300',
          price: 4500.0,
          unit: 'м³',
          imageUrl: '',
        ),
        PriceItem(
          sku: 'concrete_m200',
          name: 'Бетон М200',
          price: 4000.0,
          unit: 'м³',
          imageUrl: '',
        ),
        PriceItem(
          sku: 'rebar_12mm',
          name: 'Арматура 12мм',
          price: 55.0,
          unit: 'кг',
          imageUrl: '',
        ),
        PriceItem(
          sku: 'tile_ceramic',
          name: 'Плитка керамическая',
          price: 800.0,
          unit: 'м²',
          imageUrl: '',
        ),
      ];
      priceMap = PriceMap.fromList(testPriceList);
    });

    test('создаётся из списка PriceItem', () {
      expect(priceMap.length, equals(4));
    });

    test('findBySku возвращает правильный элемент (O(1))', () {
      final result = priceMap.findBySku('concrete_m300');

      expect(result, isNotNull);
      expect(result!.sku, equals('concrete_m300'));
      expect(result.name, equals('Бетон М300'));
      expect(result.price, equals(4500.0));
    });

    test('findBySku возвращает null для несуществующего SKU', () {
      final result = priceMap.findBySku('nonexistent_sku');
      expect(result, isNull);
    });

    test('findBySkus возвращает первый найденный элемент', () {
      final result = priceMap.findBySkus([
        'nonexistent1',
        'concrete_m200',
        'concrete_m300',
      ]);

      expect(result, isNotNull);
      expect(result!.sku, equals('concrete_m200'));
    });

    test('findBySkus возвращает null если ничего не найдено', () {
      final result = priceMap.findBySkus([
        'nonexistent1',
        'nonexistent2',
      ]);

      expect(result, isNull);
    });

    test('findAllBySkus возвращает все найденные элементы', () {
      final results = priceMap.findAllBySkus([
        'concrete_m300',
        'nonexistent',
        'rebar_12mm',
      ]);

      expect(results.length, equals(2));
      expect(results[0].sku, equals('concrete_m300'));
      expect(results[1].sku, equals('rebar_12mm'));
    });

    test('contains проверяет наличие SKU', () {
      expect(priceMap.contains('concrete_m300'), isTrue);
      expect(priceMap.contains('nonexistent'), isFalse);
    });

    test('searchByName находит элементы (регистронезависимый)', () {
      final results = priceMap.searchByName('бетон');

      expect(results.length, equals(2));
      expect(results.every((item) => item.name.toLowerCase().contains('бетон')), isTrue);
    });

    test('searchByName работает с английским', () {
      final priceMapEn = PriceMap.fromList([
        PriceItem(sku: 'brick', name: 'Red Brick', price: 10, unit: 'pcs', imageUrl: ''),
        PriceItem(sku: 'tile', name: 'Ceramic Tile', price: 20, unit: 'm²', imageUrl: ''),
      ]);

      final results = priceMapEn.searchByName('brick');
      expect(results.length, equals(1));
      expect(results[0].sku, equals('brick'));
    });

    test('filterByPriceRange фильтрует по диапазону цен', () {
      final results = priceMap.filterByPriceRange(1000, 5000);

      expect(results.length, equals(2)); // concrete_m300 и concrete_m200
      expect(results.every((item) => item.price >= 1000 && item.price <= 5000), isTrue);
    });

    test('toList возвращает все элементы', () {
      final list = priceMap.toList();

      expect(list.length, equals(4));
      expect(list, containsAll(testPriceList));
    });

    test('производительность: O(1) vs O(n)', () {
      // Создаём большой прайс-лист
      final largePriceList = List.generate(
        1000,
        (i) => PriceItem(
          sku: 'item_$i',
          name: 'Item $i',
          price: i * 10.0,
          unit: 'шт',
          imageUrl: '',
        ),
      );

      final largePriceMap = PriceMap.fromList(largePriceList);

      // Измеряем время поиска через Map (O(1))
      final stopwatch1 = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        largePriceMap.findBySku('item_${i % 1000}');
      }
      stopwatch1.stop();

      // Измеряем время линейного поиска (O(n))
      final stopwatch2 = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        largePriceList.firstWhere(
          (item) => item.sku == 'item_${i % 1000}',
          orElse: () => largePriceList[0],
        );
      }
      stopwatch2.stop();

      // PriceMap должен быть НАМНОГО быстрее
      expect(
        stopwatch1.elapsedMilliseconds < stopwatch2.elapsedMilliseconds,
        isTrue,
        reason: 'PriceMap (${stopwatch1.elapsedMilliseconds}ms) должен быть '
            'быстрее List (${stopwatch2.elapsedMilliseconds}ms)',
      );

      print('📊 Benchmark результаты:');
      print('  PriceMap O(1): ${stopwatch1.elapsedMilliseconds}ms');
      print('  List O(n):     ${stopwatch2.elapsedMilliseconds}ms');
      print('  Ускорение:     ${(stopwatch2.elapsedMilliseconds / stopwatch1.elapsedMilliseconds).toStringAsFixed(1)}x');
    });
  });
}
