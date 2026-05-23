import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_unified_usecase.dart';

void main() {
  group('WarmFloorUnifiedUseCase.mapToLegacyInputs', () {
    test('V2 type/inputMode маппятся в systemType/inputMode экрана', () {
      final mapped = WarmFloorUnifiedUseCase.mapToLegacyInputs({
        'inputMode': 0,
        'type': 1,
        'area': 20,
      });

      expect(mapped['inputMode'], 1.0);
      expect(mapped['systemType'], 2.0);
    });

    test('экранные поля не перезаписываются', () {
      final mapped = WarmFloorUnifiedUseCase.mapToLegacyInputs({
        'systemType': 3,
        'inputMode': 1,
      });

      expect(mapped['systemType'], 3.0);
      expect(mapped['inputMode'], 1.0);
    });
  });
}
