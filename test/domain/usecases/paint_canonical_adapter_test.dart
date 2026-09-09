import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/generated/canonical_specs.g.dart';
import 'package:probrab_ai/domain/usecases/paint_canonical_adapter.dart';

void main() {
  group('calculateCanonicalPaint', () {
    test('canonical-контракт требует минимум 1 м² для ручной площади', () {
      final area = (paintSpecData['input_schema'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((field) => field['key'] == 'area');

      expect(area['min'], 1);
    });

    test('добавляет грунтовку только для новой необработанной поверхности', () {
      final primed = calculateCanonicalPaint({'area': 40, 'surfacePrep': 0});
      final raw = calculateCanonicalPaint({'area': 40, 'surfacePrep': 1});
      final repainted = calculateCanonicalPaint({'area': 40, 'surfacePrep': 2});

      expect(
        primed.materials.any((material) => material.name.contains('Грунтовка')),
        isFalse,
      );
      expect(
        raw.materials.any((material) => material.name.contains('Грунтовка')),
        isTrue,
      );
      expect(
        repainted.materials.any(
          (material) => material.name.contains('Грунтовка'),
        ),
        isFalse,
      );
      expect(primed.totals['primerLiters'], 0);
      expect(raw.totals['primerLiters'], closeTo(4.4, 0.01));
      expect(repainted.totals['primerLiters'], 0);
    });

    test('не советует повторно грунтовать уже загрунтованную поверхность', () {
      final primed = calculateCanonicalPaint({
        'area': 35,
        'surfaceType': 2,
        'surfacePrep': 0,
      });
      final raw = calculateCanonicalPaint({
        'area': 35,
        'surfaceType': 2,
        'surfacePrep': 1,
      });

      expect(
        primed.warnings.any((warning) => warning.contains('грунтование')),
        isFalse,
      );
      expect(
        raw.warnings.any((warning) => warning.contains('грунтование')),
        isTrue,
      );
    });
  });
}
