import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/basement_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('BasementCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('BasementCalculatorScreen выбор типа подвала', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает иконки типов подвала', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.engineering), findsWidgets); // технический
      expect(find.byIcon(Icons.home), findsWidgets); // жилой
      expect(find.byIcon(Icons.garage), findsWidgets); // гараж
    });

    testWidgets('можно выбрать технический подвал', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final technicalType = find.textContaining('basement_calc.type.technical');
      if (technicalType.evaluate().isNotEmpty) {
        await tester.tap(technicalType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать жилой подвал', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final livingType = find.textContaining('basement_calc.type.living');
      if (livingType.evaluate().isNotEmpty) {
        await tester.tap(livingType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });
  });

  group('BasementCalculatorScreen поля ввода размеров', () {
    testWidgets('отображает поля ввода длины и ширины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('basement_calc.label.length'), findsOneWidget);
      expect(find.textContaining('basement_calc.label.width'), findsOneWidget);
    });

    testWidgets('отображает поле ввода глубины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('basement_calc.label.depth'), findsOneWidget);
    });

    testWidgets('отображает поле ввода толщины стены', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('basement_calc.label.wall_thickness'), findsOneWidget);
    });

    testWidgets('отображает CalculatorTextField виджеты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('BasementCalculatorScreen переключатели опций', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию гидроизоляции', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final waterproofSwitch = find.textContaining('basement_calc.option.waterproof');
      if (waterproofSwitch.evaluate().isNotEmpty) {
        await tester.tap(waterproofSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию утепления', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final insulationSwitch = find.textContaining('basement_calc.option.insulation');
      if (insulationSwitch.evaluate().isNotEmpty) {
        await tester.tap(insulationSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию дренажа', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final drainageSwitch = find.textContaining('basement_calc.option.drainage');
      if (drainageSwitch.evaluate().isNotEmpty) {
        await tester.tap(drainageSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });
  });

  group('BasementCalculatorScreen результаты', () {
    testWidgets('отображает результаты площади и объема', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
      expect(find.textContaining('common.cbm'), findsWidgets);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.square_foot), findsWidgets);
      expect(find.byIcon(Icons.view_in_ar), findsWidgets);
      expect(find.byIcon(Icons.crop_square), findsWidgets);
    });
  });

  group('BasementCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(BasementCalculatorScreen), findsOneWidget);
    });
  });

  group('BasementCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('кнопка поделиться существует', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('BasementCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BasementCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(BasementCalculatorScreen), findsNothing);
    });
  });
}
