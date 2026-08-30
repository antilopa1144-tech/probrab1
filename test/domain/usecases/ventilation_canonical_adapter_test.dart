import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/ventilation_canonical_adapter.dart';

void main() {
  group('Ventilation canonical v2', () {
    test('жилой режим выбирает максимум по людям и 0,35 объёма', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 0,
        'totalArea': 80,
        'ceilingHeight': 2.7,
        'peopleCount': 3,
      });

      expect(result.formulaVersion, 'ventilation-canonical-v2');
      expect(result.totals['roomVolume'], 216);
      expect(result.totals['airByPeople'], 90);
      expect(result.totals['airByVolume'], 75.6);
      expect(result.totals['requiredAirflow'], 90);
    });

    test('на границе 20 м²/чел использует 3 м³/(ч·м²)', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 0,
        'totalArea': 60,
        'ceilingHeight': 2.7,
        'peopleCount': 3,
      });

      expect(result.totals['areaPerPerson'], 20);
      expect(result.totals['airByArea'], 180);
      expect(result.totals['requiredAirflow'], 180);
    });

    test('высоту 2,7 сохраняет в метрах', () {
      final result = calculateCanonicalVentilation(const {
        'totalArea': 100,
        'ceilingHeight': 2.7,
        'peopleCount': 2,
      });

      expect(result.totals['ceilingHeight'], 2.7);
      expect(result.totals['roomVolume'], 270);
      expect(result.totals['airByVolume'], 94.5);
    });

    test('проектный режим принимает готовый расход', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 720,
      });

      expect(result.totals['requiredAirflow'], 720);
      expect(
        result.warnings.any((warning) => warning.contains('готовое исходное')),
        isTrue,
      );
    });

    test('считает скорость в круглом канале', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 360,
        'ductShape': 0,
        'roundDiameterMm': 200,
        'targetVelocityMps': 3,
      });

      expect(result.totals['selectedFreeAreaM2'], closeTo(0.031416, 0.000001));
      expect(result.totals['actualVelocityMps'], closeTo(3.183, 0.001));
      expect(
        result.warnings.any(
          (warning) => warning.contains('выше заданной цели'),
        ),
        isTrue,
      );
    });

    test('считает скорость в прямоугольном канале', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 720,
        'ductShape': 1,
        'rectWidthMm': 300,
        'rectHeightMm': 200,
      });

      expect(result.totals['selectedFreeAreaM2'], 0.06);
      expect(result.totals['actualVelocityMps'], closeTo(3.333, 0.001));
    });

    test('показывает теоретическое сечение для целевой скорости', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 360,
        'targetVelocityMps': 2,
      });

      expect(result.totals['requiredFreeAreaM2'], 0.05);
      expect(result.totals['requiredRoundDiameterMm'], closeTo(252.3, 0.1));
    });

    test('не добавляет вентилятор в закупку автоматически', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 500,
        'selectedFanCapacityM3h': 700,
        'ductLengthM': 6,
      });

      expect(
        result.materials.any(
          (material) => material.name.contains('Вентилятор'),
        ),
        isFalse,
      );
      expect(result.totals['selectedFanMarginM3h'], 200);
      expect(
        result.warnings.any((warning) => warning.contains('рабочей точке')),
        isTrue,
      );
    });

    test('предупреждает о недостаточной паспортной производительности', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 500,
        'selectedFanCapacityM3h': 400,
      });

      expect(result.totals['selectedFanMarginM3h'], -100);
      expect(
        result.warnings.any(
          (warning) => warning.contains('ниже расчётного расхода'),
        ),
        isTrue,
      );
    });

    test('округляет явную длину до покупных отрезков', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 300,
        'ductLengthM': 10,
        'stockLengthM': 3,
        'ductReservePercent': 10,
        'fittingCount': 4,
        'airTerminalCount': 3,
        'clampCount': 8,
      });

      expect(result.scenarios['MIN']?.exactNeed, 10);
      expect(result.scenarios['MIN']?.purchaseQuantity, 12);
      expect(result.scenarios['REC']?.exactNeed, 11);
      expect(result.scenarios['REC']?.purchaseQuantity, 12);
      expect(result.scenarios['REC']?.leftover, 1);
      expect(
        result.scenarios['MAX']?.purchaseQuantity,
        result.scenarios['REC']?.purchaseQuantity,
      );

      final duct = result.materials.first;
      expect(duct.quantity, 10);
      expect(duct.withReserve, 11);
      expect(duct.purchaseQty, 12);
      expect(duct.packageInfo?['count'], 4);
      expect(duct.packageInfo?['size'], 3);
      expect(result.materials[1].purchaseQty, 4);
      expect(result.materials[2].purchaseQty, 3);
      expect(result.materials[3].purchaseQty, 8);
    });

    test('без длины не выдумывает трассу', () {
      final result = calculateCanonicalVentilation(const {});

      expect(result.materials, isEmpty);
      expect(result.totals['mainDuctLength'], 0);
      expect(result.scenarios['REC']?.purchaseQuantity, 0);
      expect(
        result.warnings.any((warning) => warning.contains('длину трассы')),
        isTrue,
      );
    });

    test('legacy area и rooms преобразуются в жилой canonical-ввод', () {
      final result = calculateCanonicalVentilation(const {
        'area': 80,
        'rooms': 4,
        'ceilingHeight': 2.7,
      });

      expect(result.totals['totalArea'], 80);
      expect(result.totals['peopleCount'], 4);
      expect(result.totals['requiredAirflow'], 240);
    });

    test('всегда сообщает профессиональные границы', () {
      final result = calculateCanonicalVentilation(const {
        'calculationMode': 1,
        'projectAirflowM3h': 300,
        'ductLengthM': 3,
      });

      expect(
        result.warnings.any((warning) => warning.contains('потери давления')),
        isTrue,
      );
      expect(
        result.warnings.any((warning) => warning.contains('Противопожарные')),
        isTrue,
      );
    });
  });
}
