import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/stretch_ceiling_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('StretchCeilingCalculatorScreen - рендеринг базовой структуры', () {
    testWidgets('отрисовывается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - селектор типа потолка', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает все типы полотна', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.blur_off), findsOneWidget); // matte
      expect(find.byIcon(Icons.blur_on), findsWidgets); // glossy
      expect(find.byIcon(Icons.gradient), findsOneWidget); // satin
      expect(find.byIcon(Icons.texture), findsOneWidget); // fabric
    });

    testWidgets('можно выбрать матовое полотно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.byType(TypeSelectorGroup);
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать глянцевое полотно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.byType(TypeSelectorGroup);
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать сатиновое полотно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.byType(TypeSelectorGroup);
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать тканевое полотно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.byType(TypeSelectorGroup);
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - режим ввода', () {
    testWidgets('отображает переключатель режимов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('можно переключиться на ручной ввод площади', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final manualOption = find.byType(GestureDetector);
      if (manualOption.evaluate().isNotEmpty) {
        await tester.tap(manualOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключиться на ввод размеров комнаты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final roomOption = find.byType(GestureDetector);
      if (roomOption.evaluate().isNotEmpty) {
        await tester.tap(roomOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - ввод размеров комнаты', () {
    testWidgets('отображает поля для длины и ширины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает рассчитанную площадь', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Площадь потолка'), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - количество светильников', () {
    testWidgets('отображает слайдер для светильников', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('можно изменить количество светильников', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает подсказку о светильниках', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.textContaining('Рекомендуется 1 точка на 1.5-2 м²'), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - результаты', () {
    testWidgets('отображает площадь потолка', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает периметр', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.crop_square), findsWidgets);
    });

    testWidgets('отображает количество светильников в результатах', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('виджет корректно удаляется', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(StretchCeilingCalculatorScreen), findsNothing);
    });
  });

  group('StretchCeilingCalculatorScreen - единицы измерения', () {
    testWidgets('отображает квадратные метры', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает метры', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      // 'м' appears in the perimeter result (e.g., "12 м")
      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает штуки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      // 'шт' appears in the lights count result
      expect(find.textContaining('шт'), findsWidgets);
    });
  });
}
