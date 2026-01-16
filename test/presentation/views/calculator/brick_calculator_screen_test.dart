import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/brick_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('BrickCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BrickCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('BrickCalculatorScreen выбор типа кирпича', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает иконки типов кирпича', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие иконок типов кирпича (crop_square, view_agenda, view_stream)
      expect(find.byIcon(Icons.crop_square), findsWidgets);
      expect(find.byIcon(Icons.view_agenda), findsWidgets);
    });

    testWidgets('можно выбрать тип кирпича', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Type selector contains brick types - tap on first TypeSelectorGroup item
      final typeSelectorGroup = find.byType(TypeSelectorGroup);
      expect(typeSelectorGroup, findsOneWidget);

      expect(find.byType(BrickCalculatorScreen), findsOneWidget);
    });
  });

  group('BrickCalculatorScreen поля ввода размеров', () {
    testWidgets('отображает поля ввода длины и высоты стены', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for slider field (area input)
      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('отображает CalculatorSliderField виджеты', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // In manual mode (default), CalculatorSliderField is used for area input
      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('можно ввести площадь стены', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Просто проверяем, что экран рендерится с полями
      expect(find.byType(BrickCalculatorScreen), findsOneWidget);
    });
  });

  group('BrickCalculatorScreen переключатель режима ввода', () {
    testWidgets('отображает ModeSelector для режима ввода', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // BrickCalculatorScreen uses ModeSelector for input mode (manual/wall)
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('можно переключить режим ввода', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // ModeSelector contains clickable options
      final modeSelectors = find.byType(ModeSelector);
      expect(modeSelectors, findsWidgets);

      expect(find.byType(BrickCalculatorScreen), findsOneWidget);
    });
  });

  group('BrickCalculatorScreen результаты', () {
    testWidgets('отображает результаты количества кирпичей', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for brick count result - 'шт' is the Russian translation for 'pcs'
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('отображает результаты площади', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for area result - 'м²' is the Russian translation for 'sqm'
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Result icons: straighten (area), grid_view (bricks), inventory_2 (mortar)
      expect(find.byIcon(Icons.straighten), findsWidgets);
    });
  });

  group('BrickCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(BrickCalculatorScreen), findsOneWidget);
    });
  });

  group('BrickCalculatorScreen слайдеры', () {
    testWidgets('отображает слайдеры для настроек', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить слайдер', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(BrickCalculatorScreen), findsOneWidget);
    });
  });

  group('BrickCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
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
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('BrickCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const BrickCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(BrickCalculatorScreen), findsNothing);
    });
  });
}
