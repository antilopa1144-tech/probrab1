import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_text_field.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;
  late CalculatorDefinitionV2 electricDefinition;
  late CalculatorDefinitionV2 concreteDefinition;
  late CalculatorDefinitionV2 stripFoundationDefinition;
  late CalculatorDefinitionV2 rebarDefinition;

  setUpAll(() {
    setupMocks();

    final realDefinition = CalculatorRegistry.getById('gypsum_board');
    if (realDefinition == null) {
      throw StateError('gypsum_board calculator not found in registry');
    }
    testDefinition = realDefinition;
    final realElectricDefinition = CalculatorRegistry.getById(
      'engineering_electrics',
    );
    if (realElectricDefinition == null) {
      throw StateError(
        'engineering_electrics calculator not found in registry',
      );
    }
    electricDefinition = realElectricDefinition;
    final realConcreteDefinition = CalculatorRegistry.getById(
      'concrete_universal',
    );
    if (realConcreteDefinition == null) {
      throw StateError('concrete_universal calculator not found in registry');
    }
    concreteDefinition = realConcreteDefinition;
    final realStripFoundationDefinition = CalculatorRegistry.getById(
      'foundation_strip',
    );
    if (realStripFoundationDefinition == null) {
      throw StateError('foundation_strip calculator not found in registry');
    }
    stripFoundationDefinition = realStripFoundationDefinition;
    final realRebarDefinition = CalculatorRegistry.getById('foundation_rebar');
    if (realRebarDefinition == null) {
      throw StateError('foundation_rebar calculator not found in registry');
    }
    rebarDefinition = realRebarDefinition;
  });

  group('ProCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pump();

      expect(find.byType(ProCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Card widgets', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pump();

      await tester.pumpWidget(createTestApp(child: const SizedBox.shrink()));

      expect(find.byType(ProCalculatorScreen), findsNothing);
    });
  });

  group('ProCalculatorScreen slider+textfield', () {
    testWidgets('slider fields show both Slider and CalculatorTextField', (
      tester,
    ) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pumpAndSettle();

      // gypsum_board has slider fields — both Slider and CalculatorTextField should be present
      expect(find.byType(Slider), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('can interact with slider', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(ProCalculatorScreen), findsOneWidget);
    });

    testWidgets('no input mode toggle present', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: testDefinition)),
      );
      await tester.pumpAndSettle();

      // The SegmentedButton toggle was removed — sliders and text fields are always shown together
      expect(find.byType(SegmentedButton<bool>), findsNothing);
    });
  });

  group('ProCalculatorScreen canonical electric flow', () {
    testWidgets('показывает v3 поля и переключает покупку метров на бухты', (
      tester,
    ) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: electricDefinition),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Площадь квартиры / дома'), findsWidgets);
      expect(find.text('Как продаётся кабель'), findsOneWidget);
      expect(find.text('Отрез по метрам'), findsOneWidget);
      expect(find.text('89 м'), findsOneWidget);
      expect(find.text('134 м'), findsOneWidget);
      expect(find.text('Важно'), findsOneWidget);
      expect(
        find.textContaining('площадь сама по себе этого не определяет'),
        findsOneWidget,
      );

      final spoolMode = find.text('Бухты по 50 м');
      await tester.ensureVisible(spoolMode);
      await tester.tap(spoolMode);
      await tester.pumpAndSettle();

      expect(find.text('100 м'), findsOneWidget);
      expect(find.text('150 м'), findsOneWidget);
    });
  });

  group('ProCalculatorScreen canonical concrete flow', () {
    testWidgets('показывает v3 режимы и предупреждает о ручном составе', (
      tester,
    ) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: concreteDefinition),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Как задать объём'), findsOneWidget);
      expect(find.text('Знаю объём', skipOffstage: false), findsOneWidget);
      expect(find.text('Объём бетона'), findsOneWidget);
      expect(find.text('Шаг заказа готовой смеси'), findsOneWidget);
      expect(find.text('В15 (М200)'), findsOneWidget);

      final byArea = find.text('По площади и толщине', skipOffstage: false);
      await tester.ensureVisible(byArea);
      await tester.tap(byArea);
      await tester.pumpAndSettle();

      expect(find.text('Площадь заливки'), findsOneWidget);
      expect(find.text('Толщина слоя'), findsOneWidget);
      expect(find.text('Объём бетона'), findsNothing);

      final manualMix = find.byType(Switch);
      expect(manualMix, findsOneWidget);
      await tester.ensureVisible(manualMix);
      await tester.tap(manualMix);
      await tester.pumpAndSettle();

      expect(find.text('Важно'), findsOneWidget);
      expect(
        find.textContaining('не рецепт', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Арматура', skipOffstage: false),
        findsNothing,
      );
      expect(find.textContaining('Опалуб', skipOffstage: false), findsNothing);
    });
  });

  group('ProCalculatorScreen canonical strip foundation flow', () {
    testWidgets('показывает проектные параметры и покупку в прутках', (
      tester,
    ) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: stripFoundationDefinition),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Геометрия из проекта'), findsOneWidget);
      expect(find.text('Заказ бетона'), findsOneWidget);
      expect(find.text('Армирование из проекта'), findsOneWidget);
      expect(find.text('Общая длина всех лент'), findsOneWidget);
      expect(find.text('Остаток в линии подачи'), findsOneWidget);
      expect(find.text('Длина покупного прутка'), findsOneWidget);
      expect(find.textContaining('прутков', skipOffstage: false), findsWidgets);
      expect(find.textContaining('ФБС', skipOffstage: false), findsNothing);
      expect(find.textContaining('Песок', skipOffstage: false), findsNothing);
    });
  });

  group('ProCalculatorScreen canonical rebar flow', () {
    testWidgets('показывает проектную сетку и переключает её на каркас', (
      tester,
    ) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(child: ProCalculatorScreen(definition: rebarDefinition)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Схема из проекта'), findsWidgets);
      expect(find.text('Сетка из проекта'), findsWidgets);
      expect(find.text('Закупка арматуры'), findsWidgets);
      expect(find.text('Вязальная проволока'), findsWidgets);
      expect(find.text('Длина сетки'), findsOneWidget);
      expect(
        find.textContaining('153 прутка', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Фиксатор', skipOffstage: false),
        findsNothing,
      );

      final frameMode = find.text(
        'Продольный каркас с хомутами',
        skipOffstage: false,
      );
      await tester.ensureVisible(frameMode);
      await tester.tap(frameMode);
      await tester.pumpAndSettle();

      expect(find.text('Каркас из проекта'), findsWidgets);
      expect(find.text('Суммарная длина каркаса'), findsOneWidget);
      expect(find.text('Длина сетки'), findsNothing);
      expect(find.textContaining('Хомуты', skipOffstage: false), findsWidgets);
    });
  });
}
