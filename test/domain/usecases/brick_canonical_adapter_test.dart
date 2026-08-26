import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/brick_canonical_adapter.dart';

void main() {
  group('calculateCanonicalBrick v3', () {
    test('разделяет чистую потребность, выбранный запас и покупку', () {
      final result = calculateCanonicalBrick({
        'inputMode': 0,
        'wallWidth': 5,
        'wallHeight': 3,
        'brickType': 0,
        'wallThickness': 1,
        'workingConditions': 1,
        'wasteMode': 0,
        'mortarAdditive': 0,
      });
      final brick = result.materials.first;

      expect(result.formulaVersion, 'brick-canonical-v3');
      expect(result.totals['bricksNet'], 1530);
      expect(result.scenarios['MIN']!.exactNeed, 1530);
      expect(result.scenarios['REC']!.exactNeed, 1606.5);
      expect(result.scenarios['MAX']!.exactNeed, 1683);
      expect(brick.quantity, 1530);
      expect(brick.withReserve, 1606.5);
      expect(brick.purchaseQty, 1607);
    });

    test('режим точности не добавляет скрытый запас', () {
      final basic = calculateCanonicalBrick({'accuracyMode': 0});
      final professional = calculateCanonicalBrick({'accuracyMode': 2});

      expect(
        professional.scenarios['REC']!.exactNeed,
        basic.scenarios['REC']!.exactNeed,
      );
      expect(professional.scenarios['REC']!.purchaseQuantity, 1607);
    });

    test('режим площади восстанавливает ширину из площади и высоты', () {
      final result = calculateCanonicalBrick({
        'inputMode': 1,
        'area': 20,
        'wallHeight': 2.5,
      });

      expect(result.totals['wallWidth'], 8);
      expect(result.totals['area'], 20);
    });
  });
}
