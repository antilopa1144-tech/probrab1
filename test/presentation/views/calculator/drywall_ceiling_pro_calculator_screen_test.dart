import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('открывает П 113 через реальный ProCalculator flow', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('drywall_ceiling');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build(
      'drywall_ceiling',
      definition!,
      null,
    );
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Геометрия потолка'), findsOneWidget);
    expect(find.text('Комплектная система'), findsOneWidget);
    expect(find.text('Гипсовые плиты'), findsOneWidget);
    expect(find.text('Профили П 113'), findsOneWidget);
    expect(find.text('Крепёж П 113'), findsWidgets);
    expect(find.text('Ленты и заделка швов'), findsOneWidget);
    expect(find.text('Длина помещения'), findsOneWidget);
    expect(find.text('Ширина помещения'), findsOneWidget);
    expect(find.text('Фактическая площадь потолка'), findsNothing);
    expect(find.text('Суммарный периметр примыканий'), findsNothing);
    expect(find.text('Вариант системы'), findsOneWidget);
    expect(find.text('Шурупов TN в упаковке'), findsOneWidget);
    expect(find.text('Шурупов LN в упаковке'), findsOneWidget);
    expect(
      find.textContaining(
        'только к одноуровневой системе',
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
}
