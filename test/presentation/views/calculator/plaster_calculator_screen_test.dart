import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/plaster_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  testWidgets(
    'ручной режим объясняет разницу между площадью стен и площадью под штукатурку',
    (tester) async {
      setTestViewportSize(tester);
      final definition = CalculatorRegistry.getById('mixes_plaster')!;

      await tester.pumpWidget(
        createTestApp(
          child: PlasterCalculatorScreen(definition: definition),
        ),
      );
      await tester.pump();

      expect(find.text('ИТОГОВАЯ ПЛОЩАДЬ'), findsOneWidget);
      expect(find.text('Площадь стен'), findsWidgets);
      expect(find.text('Вычесть проемы (окна/двери)'), findsOneWidget);
      expect(find.text('26 м²'), findsOneWidget);
    },
  );
}
