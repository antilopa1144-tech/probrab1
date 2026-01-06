import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_result.dart';

void main() {
  group('TileCalculatorResult', () {
    test('creates with required parameters', () {
      const result = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
      );
      expect(result.area, 20.0);
      expect(result.tilesNeeded, 250);
    });

    test('fromMap creates instance correctly', () {
      final result = TileCalculatorResult.fromMap({
        'area': 20.0,
        'tilesNeeded': 250.0,
        'groutNeeded': 5.0,
        'glueNeeded': 40.0,
        'crossesNeeded': 500.0,
      });
      expect(result.area, 20.0);
      expect(result.tilesNeeded, 250);
    });

    test('fromMap handles missing values', () {
      final result = TileCalculatorResult.fromMap({});
      expect(result.area, 0.0);
      expect(result.tilesNeeded, 0);
    });

    test('toMap returns correct values', () {
      const result = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
      );
      final map = result.toMap();
      expect(map['area'], 20.0);
      expect(map['tilesNeeded'], 250.0);
    });

    test('toFormattedMap includes all fields', () {
      const result = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
      );
      final formatted = result.toFormattedMap();
      expect(formatted.containsKey('Площадь'), isTrue);
      expect(formatted.containsKey('Плитки'), isTrue);
      expect(formatted['Плитки'], '250 шт.');
    });

    test('toFormattedMap includes price when set', () {
      const result = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
        totalPrice: 15000,
      );
      final formatted = result.toFormattedMap();
      expect(formatted.containsKey('Стоимость'), isTrue);
    });
  });

  group('LaminateCalculatorResult', () {
    test('creates with required parameters', () {
      const result = LaminateCalculatorResult(
        area: 25.0,
        packsNeeded: 13,
        underlayArea: 27.5,
        plinthLength: 20.0,
        wedgesNeeded: 40,
      );
      expect(result.packsNeeded, 13);
      expect(result.underlayArea, 27.5);
    });

    test('fromMap creates instance correctly', () {
      final result = LaminateCalculatorResult.fromMap({
        'area': 25.0,
        'packsNeeded': 13.0,
        'underlayArea': 27.5,
        'plinthLength': 20.0,
        'wedgesNeeded': 40.0,
      });
      expect(result.packsNeeded, 13);
    });

    test('toFormattedMap formats values correctly', () {
      const result = LaminateCalculatorResult(
        area: 25.0,
        packsNeeded: 13,
        underlayArea: 27.5,
        plinthLength: 20.0,
        wedgesNeeded: 40,
      );
      final formatted = result.toFormattedMap();
      expect(formatted['Упаковки'], '13 шт.');
      expect(formatted['Подложка'], '27.5 м²');
    });
  });

  group('ScreedCalculatorResult', () {
    test('creates with required parameters', () {
      const result = ScreedCalculatorResult(
        area: 30.0,
        volume: 1.5,
        cementBags: 10,
        sandVolume: 1.2,
        thickness: 50.0,
      );
      expect(result.cementBags, 10);
      expect(result.sandVolume, 1.2);
    });

    test('fromMap creates instance correctly', () {
      final result = ScreedCalculatorResult.fromMap({
        'area': 30.0,
        'volume': 1.5,
        'cementBags': 10.0,
        'sandVolume': 1.2,
        'thickness': 50.0,
      });
      expect(result.cementBags, 10);
    });

    test('toFormattedMap formats cement correctly', () {
      const result = ScreedCalculatorResult(
        area: 30.0,
        volume: 1.5,
        cementBags: 10,
        sandVolume: 1.2,
        thickness: 50.0,
      );
      final formatted = result.toFormattedMap();
      expect(formatted['Цемент'], contains('10'));
      expect(formatted['Цемент'], contains('мешков'));
    });
  });

  group('WallPaintCalculatorResult', () {
    test('creates with required parameters', () {
      const result = WallPaintCalculatorResult(
        usefulArea: 45.0,
        paintNeeded: 6.75,
        primerNeeded: 4.5,
        layers: 2,
      );
      expect(result.paintNeeded, 6.75);
      expect(result.layers, 2);
    });

    test('fromMap creates instance correctly', () {
      final result = WallPaintCalculatorResult.fromMap({
        'usefulArea': 45.0,
        'paintNeeded': 6.75,
        'primerNeeded': 4.5,
        'layers': 2.0,
      });
      expect(result.layers, 2);
    });

    test('toFormattedMap includes layers', () {
      const result = WallPaintCalculatorResult(
        usefulArea: 45.0,
        paintNeeded: 6.75,
        primerNeeded: 4.5,
        layers: 2,
      );
      final formatted = result.toFormattedMap();
      expect(formatted['Слоёв'], '2');
    });
  });

  group('StripFoundationCalculatorResult', () {
    test('creates with required parameters', () {
      const result = StripFoundationCalculatorResult(
        concreteVolume: 12.8,
        rebarWeight: 450,
        bagsCement: 64,
      );
      expect(result.concreteVolume, 12.8);
      expect(result.rebarWeight, 450);
    });

    test('fromMap creates instance correctly', () {
      final result = StripFoundationCalculatorResult.fromMap({
        'concreteVolume': 12.8,
        'rebarWeight': 450.0,
        'bagsCement': 64.0,
      });
      expect(result.bagsCement, 64);
    });

    test('toFormattedMap formats values correctly', () {
      const result = StripFoundationCalculatorResult(
        concreteVolume: 12.8,
        rebarWeight: 450,
        bagsCement: 64,
      );
      final formatted = result.toFormattedMap();
      expect(formatted['Объём бетона'], '12.80 м³');
      expect(formatted['Арматура'], '450 кг');
    });
  });

  group('WarmFloorCalculatorResult', () {
    test('creates with required parameters', () {
      const result = WarmFloorCalculatorResult(
        area: 15.0,
        usefulArea: 12.0,
        totalPower: 1800,
        cableLength: 60.0,
        matArea: 0.0,
        thermostats: 1,
        insulationArea: 15.0,
      );
      expect(result.totalPower, 1800);
      expect(result.thermostats, 1);
    });

    test('fromMap creates instance correctly', () {
      final result = WarmFloorCalculatorResult.fromMap({
        'area': 15.0,
        'usefulArea': 12.0,
        'totalPower': 1800.0,
        'cableLength': 60.0,
        'matArea': 0.0,
        'thermostats': 1.0,
        'insulationArea': 15.0,
      });
      expect(result.thermostats, 1);
    });

    test('toFormattedMap includes cable for cable type', () {
      const result = WarmFloorCalculatorResult(
        area: 15.0,
        usefulArea: 12.0,
        totalPower: 1800,
        cableLength: 60.0,
        matArea: 0.0,
        thermostats: 1,
        insulationArea: 15.0,
      );
      final formatted = result.toFormattedMap();
      expect(formatted.containsKey('Кабель'), isTrue);
      expect(formatted.containsKey('Нагревательный мат'), isFalse);
    });

    test('toFormattedMap includes mat for mat type', () {
      const result = WarmFloorCalculatorResult(
        area: 15.0,
        usefulArea: 12.0,
        totalPower: 1800,
        cableLength: 0.0,
        matArea: 12.0,
        thermostats: 1,
        insulationArea: 15.0,
      );
      final formatted = result.toFormattedMap();
      expect(formatted.containsKey('Кабель'), isFalse);
      expect(formatted.containsKey('Нагревательный мат'), isTrue);
    });

    test('toMap returns all values', () {
      const result = WarmFloorCalculatorResult(
        area: 15.0,
        usefulArea: 12.0,
        totalPower: 1800,
        cableLength: 60.0,
        matArea: 0.0,
        thermostats: 1,
        insulationArea: 15.0,
      );
      final map = result.toMap();
      expect(map.length, 7);
      expect(map['totalPower'], 1800.0);
    });
  });

  group('CalculatorResultModel interface', () {
    test('TileCalculatorResult implements interface', () {
      const result = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
      );
      expect(result, isA<CalculatorResultModel>());
    });

    test('all results have toMap method', () {
      const tileResult = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
      );
      const laminateResult = LaminateCalculatorResult(
        area: 25.0,
        packsNeeded: 13,
        underlayArea: 27.5,
        plinthLength: 20.0,
        wedgesNeeded: 40,
      );

      expect(tileResult.toMap(), isA<Map<String, double>>());
      expect(laminateResult.toMap(), isA<Map<String, double>>());
    });

    test('all results have toFormattedMap method', () {
      const tileResult = TileCalculatorResult(
        area: 20.0,
        tilesNeeded: 250,
        groutNeeded: 5.0,
        glueNeeded: 40.0,
        crossesNeeded: 500,
      );

      final formatted = tileResult.toFormattedMap();
      expect(formatted, isA<Map<String, String>>());
      expect(formatted.values.every((v) => v.isNotEmpty), isTrue);
    });
  });
}
