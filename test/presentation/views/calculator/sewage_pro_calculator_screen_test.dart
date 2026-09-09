import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  testWidgets('септик доступен через реальный canonical flow', (tester) async {
    setTestViewportSize(tester);
    final definition = CalculatorRegistry.getById('sewage');
    expect(definition, isNotNull);

    final routed = CalculatorScreenRegistry.build('sewage', definition!, null);
    expect(routed, isA<ProCalculatorScreen>());

    await tester.pumpWidget(
      createTestApp(child: ProCalculatorScreen(definition: definition)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Суточный приток'), findsOneWidget);
    expect(find.text('Проверка выбранной системы'), findsOneWidget);
    expect(find.text('Условия участка'), findsOneWidget);
    expect(find.text('Проектная ведомость'), findsOneWidget);
    expect(find.text('Предварительно по ЭЧЖ'), findsOneWidget);
    expect(find.text('По суточному притоку проекта'), findsOneWidget);
    expect(find.text('Эквивалентное число жителей, ЭЧЖ'), findsOneWidget);
    expect(find.text('Расчётный сток на одного ЭЧЖ, л/сут'), findsOneWidget);
    expect(find.text('Рабочий объём выбранной системы'), findsOneWidget);
    expect(find.text('СУТОЧНЫЙ ПРИТОК, М³/СУТ'), findsOneWidget);
    expect(find.text('МИНИМАЛЬНЫЙ РАБОЧИЙ ОБЪЁМ, М³'), findsOneWidget);
    expect(
      find.textContaining(
        'предварительную механическую очистку',
        skipOffstage: false,
      ),
      findsWidgets,
    );
    expect(
      definition.afterHints.map((hint) => hint.messageKey),
      contains('hint.sewage.noSitingDesign'),
    );
  });
}
