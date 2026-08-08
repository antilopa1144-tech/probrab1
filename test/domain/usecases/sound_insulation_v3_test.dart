import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/sound_insulation_canonical_adapter.dart';

void main() {
  group('calculateCanonicalSoundInsulation v3', () {
    test('не складывает скрытый запас и округляет плиты по упаковкам', () {
      final result = calculateCanonicalSoundInsulation({
        'area': 30,
        'system': 0,
        'acousticPlatesPerPack': 6,
        'accuracyMode': 0,
      });

      expect(result.formulaVersion, 'sound-insulation-canonical-v3');
      expect(result.totals['primaryQty'], 50);
      expect(result.scenarios['REC']!.exactNeed, 53);
      expect(result.scenarios['REC']!.purchaseQuantity, 54);
      expect(result.scenarios['REC']!.buyPlan.packagesCount, 9);
    });

    test('использует введённый периметр, а без него явно ставит оценку', () {
      final entered = calculateCanonicalSoundInsulation({
        'area': 25,
        'system': 0,
        'perimeter': 100,
      });
      final estimated = calculateCanonicalSoundInsulation({
        'area': 25,
        'system': 0,
        'perimeter': 0,
      });

      expect(entered.totals['perim'], 100);
      expect(entered.totals['perimeterEstimated'], 0);
      expect(entered.totals['sealTape'], 8);
      expect(estimated.totals['perim'], 20);
      expect(estimated.totals['perimeterEstimated'], 1);
    });

    test('плавающий пол считает смесь по выбранной толщине стяжки', () {
      final result = calculateCanonicalSoundInsulation({
        'area': 30,
        'system': 2,
        'screedThicknessMm': 70,
      });
      final screed = result.materials.singleWhere(
        (material) => material.name.contains('Сухая смесь'),
      );

      expect(result.totals['surfaceType'], 1);
      expect(result.totals['screedThicknessMm'], 70);
      expect(screed.purchaseQty, 76);
    });

    test('ЗИПС использует штатный комплект вместо выдуманного дюбеля', () {
      final result = calculateCanonicalSoundInsulation({
        'area': 30,
        'system': 1,
        'accuracyMode': 0,
      });
      final panels = result.materials.first;
      final includedKit = result.materials[1];

      expect(result.totals['surfaceType'], 0);
      expect(result.scenarios['REC']!.purchaseQuantity, 45);
      expect(panels.purchaseQty, 45);
      expect(includedKit.purchaseQty, panels.purchaseQty);
      expect(
        result.materials.any((material) => material.name.contains('Дюбел')),
        isFalse,
      );
    });

    test('акустический потолок содержит крепёж для двух слоёв ГКЛ', () {
      final result = calculateCanonicalSoundInsulation({
        'area': 30,
        'system': 3,
      });

      expect(result.totals['surfaceType'], 2);
      expect(
        result.materials.any(
          (material) => material.name.toLowerCase().contains('саморез'),
        ),
        isTrue,
      );
    });
  });
}
