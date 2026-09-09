import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/sewage_canonical_adapter.dart';

void main() {
  group('calculateCanonicalSewage v2', () {
    test('считает предварительный приток и трёхкратный минимум', () {
      final result = calculateCanonicalSewage({
        'calculationMode': 0,
        'equivalentResidents': 4,
        'wastewaterPerResidentL': 200,
      });

      expect(result.formulaVersion, 'sewage-canonical-v2');
      expect(result.totals['dailyFlowM3'], 0.8);
      expect(result.totals['retentionMultiplier'], 3);
      expect(result.totals['minimumWorkingVolumeM3'], 2.4);
      expect(result.totals['minimumChamberCount'], 1);
      expect(result.scenarios['MIN']!.exactNeed, 2.4);
      expect(result.scenarios['REC']!.exactNeed, 2.4);
      expect(result.scenarios['MAX']!.exactNeed, 2.4);
    });

    test('принимает проектный суточный приток', () {
      final result = calculateCanonicalSewage({
        'calculationMode': 1,
        'equivalentResidents': 6,
        'wastewaterPerResidentL': 999,
        'projectDailyFlowM3': 1.1,
      });

      expect(result.totals['dailyFlowM3'], 1.1);
      expect(result.totals['minimumWorkingVolumeM3'], 3.3);
      expect(result.totals['minimumChamberCount'], 2);
    });

    test('использует коэффициент 2,5 свыше 25 ЭЧЖ', () {
      final result = calculateCanonicalSewage({
        'calculationMode': 1,
        'equivalentResidents': 30,
        'projectDailyFlowM3': 6,
      });

      expect(result.totals['retentionMultiplier'], 2.5);
      expect(result.totals['minimumWorkingVolumeM3'], 15);
    });

    test('предупреждает о недостаточном числе камер', () {
      final result = calculateCanonicalSewage({
        'calculationMode': 1,
        'equivalentResidents': 60,
        'projectDailyFlowM3': 10,
        'selectedChamberCount': 2,
      });

      expect(result.totals['minimumChamberCount'], 3);
      expect(
        result.warnings.any((warning) => warning.contains('не менее 3')),
        isTrue,
      );
    });

    test('показывает дефицит рабочего объёма', () {
      final result = calculateCanonicalSewage({
        'equivalentResidents': 4,
        'wastewaterPerResidentL': 200,
        'selectedWorkingVolumeM3': 2,
      });

      expect(result.totals['volumeShortfallM3'], 0.4);
      expect(result.scenarios['REC']!.purchaseQuantity, 2.4);
      expect(result.materials.single.name, contains('Выбранная система'));
    });

    test('округляет трубу только по явному товарному отрезку', () {
      final result = calculateCanonicalSewage({
        'pipeLengthM': 10.2,
        'pipeSectionLengthM': 3,
        'inspectionWellCount': 1,
        'fittingCount': 4,
      });

      final pipe = result.materials.firstWhere(
        (material) => material.name.contains('Труба наружной канализации'),
      );
      expect(pipe.quantity, 10.2);
      expect(pipe.purchaseQty, 12);
      expect(pipe.packageInfo, {
        'count': 4,
        'size': 3.0,
        'packageUnit': 'отрезк.',
      });
      expect(
        result.materials.any((material) => material.name.contains('Смотровой')),
        isTrue,
      );
      expect(
        result.materials.any((material) => material.name.contains('Фасонные')),
        isTrue,
      );
    });

    test('не добавляет материалы без проектной ведомости', () {
      final result = calculateCanonicalSewage({
        'equivalentResidents': 4,
        'wastewaterPerResidentL': 200,
      });

      expect(result.materials, isEmpty);
      expect(
        result.warnings.any(
          (warning) =>
              warning.contains('Рабочий объём выбранной системы не введён'),
        ),
        isTrue,
      );
    });

    test('не выдаёт условия участка за проверенные', () {
      final result = calculateCanonicalSewage({
        'naturalTreatmentStatus': 2,
        'groundwaterStatus': 2,
      });

      expect(
        result.warnings.any(
          (warning) => warning.contains('инженерное решение'),
        ),
        isTrue,
      );
      expect(
        result.warnings.any(
          (warning) => warning.contains('Высокий или сезонно высокий'),
        ),
        isTrue,
      );
    });
  });
}
