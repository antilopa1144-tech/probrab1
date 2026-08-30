import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('открывает электрический тёплый пол через canonical flow', (
    tester,
  ) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('floors_warm');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build(
      'floors_warm',
      definition!,
      null,
    );
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('План раскладки'), findsOneWidget);
    expect(find.text('Паспорт выбранного комплекта'), findsOneWidget);
    expect(find.text('Электрическая проверка'), findsOneWidget);
    expect(find.text('Закупка по ведомости'), findsOneWidget);
    expect(find.text('Площадь помещения'), findsOneWidget);
    expect(find.text('Зоны без нагрева'), findsOneWidget);
    expect(find.text('Фактическая площадь раскладки'), findsOneWidget);
    expect(find.text('Нагревательный мат'), findsOneWidget);
    expect(find.text('Количество выбранных комплектов'), findsOneWidget);
    expect(find.text('Паспортная мощность одного комплекта'), findsOneWidget);
    expect(find.text('ПЛОЩАДЬ РАСКЛАДКИ, М²'), findsOneWidget);
    expect(find.text('УСТАНОВЛЕННАЯ МОЩНОСТЬ, ВТ'), findsOneWidget);
    expect(find.text('РАСЧЁТНЫЙ ТОК, А'), findsOneWidget);
    expect(
      definition.beforeHints.map((hint) => hint.messageKey),
      contains('hint.warm_floor.v3.factoryKit'),
    );
    expect(
      definition.afterHints.map((hint) => hint.messageKey),
      contains('hint.warm_floor.v3.noElectricalDesign'),
    );
    expect(find.textContaining('водя', skipOffstage: false), findsNothing);
  });
}
