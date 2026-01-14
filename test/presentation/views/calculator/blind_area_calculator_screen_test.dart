import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/blind_area_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('BlindAreaCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BlindAreaCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('BlindAreaCalculatorScreen выбор типа отмостки', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает иконки типов отмостки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_agenda), findsWidgets); // бетонная
      expect(find.byIcon(Icons.grid_on), findsWidgets); // брусчатка
      expect(find.byIcon(Icons.grass), findsWidgets); // мягкая
    });

    testWidgets('можно выбрать бетонную отмостку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final concreteType = find.textContaining('blind_area_calc.type.concrete');
      if (concreteType.evaluate().isNotEmpty) {
        await tester.tap(concreteType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BlindAreaCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать брусчатку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final pavingType = find.textContaining('blind_area_calc.type.paving');
      if (pavingType.evaluate().isNotEmpty) {
        await tester.tap(pavingType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BlindAreaCalculatorScreen), findsOneWidget);
    });
  });

  group('BlindAreaCalculatorScreen поля ввода размеров', () {
    testWidgets('отображает поля ввода длины и ширины дома', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('blind_area_calc.label.house_length'), findsOneWidget);
      expect(find.textContaining('blind_area_calc.label.house_width'), findsOneWidget);
    });

    testWidgets('отображает поле ввода ширины отмостки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('blind_area_calc.label.blind_width'), findsOneWidget);
    });

    testWidgets('отображает поле ввода толщины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('blind_area_calc.label.thickness'), findsOneWidget);
    });

    testWidgets('отображает CalculatorTextField виджеты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('BlindAreaCalculatorScreen переключатели опций', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию утепления', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final insulationSwitch = find.textContaining('blind_area_calc.option.insulation');
      if (insulationSwitch.evaluate().isNotEmpty) {
        await tester.tap(insulationSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BlindAreaCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию дренажа', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final drainageSwitch = find.textContaining('blind_area_calc.option.drainage');
      if (drainageSwitch.evaluate().isNotEmpty) {
        await tester.tap(drainageSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BlindAreaCalculatorScreen), findsOneWidget);
    });
  });

  group('BlindAreaCalculatorScreen результаты', () {
    testWidgets('отображает результаты периметра', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.meters'), findsWidgets);
    });

    testWidgets('отображает результаты площади и объема', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
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
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.crop_square), findsWidgets);
      expect(find.byIcon(Icons.square_foot), findsWidgets);
      expect(find.byIcon(Icons.view_in_ar), findsWidgets);
    });
  });

  group('BlindAreaCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает карточку советов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Должна быть иконка лампочки для советов
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      // Должны быть иконки галочек для элементов советов
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(BlindAreaCalculatorScreen), findsOneWidget);
    });
  });

  group('BlindAreaCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
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
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('BlindAreaCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BlindAreaCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(BlindAreaCalculatorScreen), findsNothing);
    });
  });
}
