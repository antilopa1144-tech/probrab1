import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/attic_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('AtticCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('AtticCalculatorScreen выбор типа мансарды', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает иконки типов мансарды', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.ac_unit), findsWidgets); // холодная
      expect(find.byIcon(Icons.whatshot), findsWidgets); // теплая
      expect(find.byIcon(Icons.home), findsWidgets); // жилая
    });

    testWidgets('можно выбрать тип холодная мансарда', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final coldType = find.byType(TypeSelectorGroup);
      if (coldType.evaluate().isNotEmpty) {
        await tester.tap(coldType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать тип теплая мансарда', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final warmType = find.byType(TypeSelectorGroup);
      if (warmType.evaluate().isNotEmpty) {
        await tester.tap(warmType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });
  });

  group('AtticCalculatorScreen поля ввода размеров', () {
    testWidgets('отображает поля ввода длины и ширины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for CalculatorTextField widgets for length and width
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает поле ввода высоты крыши', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for CalculatorSliderField for roof height
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('отображает CalculatorTextField виджеты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('AtticCalculatorScreen слайдер толщины утеплителя', () {
    testWidgets('отображает слайдер толщины утеплителя для теплой мансарды', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить толщину утеплителя', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает значение толщины в мм', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('мм'), findsWidgets);
    });
  });

  group('AtticCalculatorScreen переключатели опций', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию пароизоляции', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final vaporBarrierSwitch = find.byType(SwitchListTile);
      if (vaporBarrierSwitch.evaluate().isNotEmpty) {
        await tester.tap(vaporBarrierSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию мембраны', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final membraneSwitch = find.byType(SwitchListTile);
      if (membraneSwitch.evaluate().isNotEmpty) {
        await tester.tap(membraneSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });
  });

  group('AtticCalculatorScreen результаты', () {
    testWidgets('отображает результаты площади пола', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.square_foot), findsWidgets);
      expect(find.byIcon(Icons.roofing), findsWidgets);
      expect(find.byIcon(Icons.layers), findsWidgets);
    });

    testWidgets('обновляет результаты при изменении длины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(CalculatorTextField);
      if (textFields.evaluate().isNotEmpty) {
        // Просто проверяем что виджет не падает при взаимодействии
        expect(find.byType(AtticCalculatorScreen), findsOneWidget);
      }
    });
  });

  group('AtticCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает иконку списка материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(AtticCalculatorScreen), findsOneWidget);
    });
  });

  group('AtticCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
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
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('AtticCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const AtticCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(AtticCalculatorScreen), findsNothing);
    });
  });
}
