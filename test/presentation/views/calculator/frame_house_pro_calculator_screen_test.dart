import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('показывает проектные группы и скрывает неприменимые фасовки', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('frame_house');
    expect(definition, isNotNull);

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition!)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Площадь стен'), findsOneWidget);
    expect(find.text('Пиломатериал из проекта'), findsOneWidget);
    expect(find.text('Наружная обшивка'), findsOneWidget);
    expect(find.text('Утеплитель'), findsWidgets);
    expect(find.text('Крепёж по проекту'), findsOneWidget);
    expect(find.text('Общая длина рассчитываемых стен'), findsOneWidget);
    expect(
      find.text('Длина одной позиции пиломатериала из ведомости'),
      findsOneWidget,
    );
    expect(find.text('Площадь одного наружного листа'), findsOneWidget);
    expect(find.text('Запас этой позиции на раскрой'), findsNothing);
    expect(find.text('Площадь утеплителя в одной упаковке'), findsNothing);
    expect(find.text('Крепежа обшивки в упаковке'), findsNothing);
    expect(
      find.textContaining('не проектирует несущую схему', skipOffstage: false),
      findsWidgets,
    );
    expect(find.textContaining('Шаг стоек', skipOffstage: false), findsNothing);
  });
}
