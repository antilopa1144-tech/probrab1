import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_insulation_mineral_wool.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateInsulationMineralWool', () {
    test('calculates volume correctly', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0, // 20 м²
        'thickness': 100.0, // 100 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 20 * 0.1 = 2 м³
      expect(result.values['volume'], equals(2.0));
      expect(result.values['area'], closeTo(20.0, 1.0));
    });

    test('calculates sheets needed', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плиты: 0.72 м²
      // Количество: 20 / 0.72 * 1.05 = 29.17 → 30 плит
      expect(result.values['sheetsNeeded'], closeTo(30.0, 1.5));
    });

    test('calculates weight', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
        'density': 50.0, // 50 кг/м³
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Вес: 2 м³ * 50 = 100 кг
      expect(result.values['weight'], closeTo(100.0, 5.0));
    });

    test('calculates vapor barrier area', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Пароизоляция: 20 * 1.1 = 22 м²
      expect(result.values['vaporBarrierArea'], closeTo(22.0, 1.1));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 20 * 5 = 100 шт (толщина 100мм → 5 дюбелей/м², стена по умолчанию)
      expect(result.values['fastenersNeeded'], equals(100.0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 100 мм
      expect(result.values['thickness'], closeTo(100.0, 5.0));
      expect(result.values['volume'], equals(2.0)); // 20 * 0.1
    });

    test('uses default density when missing', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50 кг/м³
      // Вес: 2 * 50 = 100 кг
      expect(result.values['weight'], closeTo(100.0, 5.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('outputs applicationSurface and fastenersPerSqm', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
        'applicationSurface': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['applicationSurface'], equals(1.0));
      expect(result.values['fastenersPerSqm'], equals(5.0));
    });

    group('Крепёж по толщине', () {
      test('Тонкий утеплитель 50мм → 4 шт/м²', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 50.0,
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 4 * 1.0 = 40
        expect(result.values['fastenersNeeded'], equals(40.0));
        expect(result.values['fastenersPerSqm'], equals(4.0));
      });

      test('Стандартный 100мм → 5 шт/м²', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 5 * 1.0 = 50
        expect(result.values['fastenersNeeded'], equals(50.0));
        expect(result.values['fastenersPerSqm'], equals(5.0));
      });

      test('Толстый 150мм → 6 шт/м²', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 150.0,
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 6 * 1.0 = 60
        expect(result.values['fastenersNeeded'], equals(60.0));
        expect(result.values['fastenersPerSqm'], equals(6.0));
      });

      test('Очень толстый 200мм → 8 шт/м²', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 200.0,
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 8 * 1.0 = 80
        expect(result.values['fastenersNeeded'], equals(80.0));
        expect(result.values['fastenersPerSqm'], equals(8.0));
      });

      test('Максимальный 300мм → 10 шт/м²', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 300.0,
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 10 * 1.0 = 100
        expect(result.values['fastenersNeeded'], equals(100.0));
        expect(result.values['fastenersPerSqm'], equals(10.0));
      });
    });

    group('Поверхность утепления', () {
      test('Стена (по умолчанию) → стандартные крепежи', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          // applicationSurface не указан → default 1 (стена)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 5 * 1.0 = 50
        expect(result.values['fastenersNeeded'], equals(50.0));
        expect(result.values['applicationSurface'], equals(1.0));
      });

      test('Пол → 0 крепежей (гравитация)', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'applicationSurface': 2.0, // пол
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 5 * 0.0 = 0
        expect(result.values['fastenersNeeded'], equals(0.0));
        expect(result.values['applicationSurface'], equals(2.0));
      });

      test('Потолок → ×1.5 крепежей', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'applicationSurface': 3.0, // потолок
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 5 * 1.5 = 75
        expect(result.values['fastenersNeeded'], equals(75.0));
        expect(result.values['applicationSurface'], equals(3.0));
      });

      test('Скат крыши → ×1.2 крепежей', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'applicationSurface': 4.0, // скат крыши
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 * 5 * 1.2 = 60
        expect(result.values['fastenersNeeded'], equals(60.0));
        expect(result.values['applicationSurface'], equals(4.0));
      });
    });

    group('Корректировка крепежа по плотности', () {
      test('Лёгкая плита (<50 кг/м³) → ×0.8 крепежа', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'density': 30.0, // лёгкая
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // base=5 (100мм), densityFactor=0.8 → fastenersPerSqm = ceil(5*0.8)=4
        // 10 * 4 * 1.0 = 40
        expect(result.values['fastenersNeeded'], equals(40.0));
        expect(result.values['fastenersPerSqm'], equals(4.0));
      });

      test('Тяжёлая плита (>100 кг/м³) → ×1.3 крепежа', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'density': 120.0, // тяжёлая
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // base=5 (100мм), densityFactor=1.3 → fastenersPerSqm = ceil(5*1.3)=7
        // 10 * 7 * 1.0 = 70
        expect(result.values['fastenersNeeded'], equals(70.0));
        expect(result.values['fastenersPerSqm'], equals(7.0));
      });

      test('Стандартная плотность (50-100 кг/м³) → ×1.0 (без изменений)', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'density': 75.0,
          'applicationSurface': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // base=5 (100мм), densityFactor=1.0 → 5
        // 10 * 5 * 1.0 = 50
        expect(result.values['fastenersNeeded'], equals(50.0));
        expect(result.values['fastenersPerSqm'], equals(5.0));
      });

      test('Тяжёлая плита на потолке → density×1.3 + ceiling×1.5', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'density': 120.0,
          'applicationSurface': 3.0, // потолок
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // base=5, densityFactor=1.3 → ceil(6.5)=7, ceiling ×1.5
        // 10 * 7 * 1.5 = 105
        expect(result.values['fastenersNeeded'], equals(105.0));
      });
    });

    group('Предупреждения', () {
      test('Тонкий утеплитель <100мм на стену → предупреждение warningThinExterior', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 50.0,
          'applicationSurface': 1.0, // стена
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['warningThinExterior'], equals(1.0));
      });

      test('Толщина 100мм на стену → нет предупреждения', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'applicationSurface': 1.0, // стена
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values.containsKey('warningThinExterior'), isFalse);
      });

      test('Пол → предупреждение warningFloorNoFasteners', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'applicationSurface': 2.0, // пол
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['warningFloorNoFasteners'], equals(1.0));
      });

      test('Тонкий утеплитель на пол → нет предупреждения (только для стен)', () {
        final calculator = CalculateInsulationMineralWool();
        final inputs = {
          'area': 10.0,
          'thickness': 50.0,
          'applicationSurface': 2.0, // пол
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values.containsKey('warningThinExterior'), isFalse);
      });
    });
  });
}
