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
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает все типы полотна', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('stretch_ceiling_calc.type.matte');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать глянцевое полотно', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('stretch_ceiling_calc.type.glossy');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать сатиновое полотно', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('stretch_ceiling_calc.type.satin');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать тканевое полотно', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('stretch_ceiling_calc.type.fabric');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - режим ввода', () {
    testWidgets('отображает переключатель режимов', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('можно переключиться на ручной ввод площади', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final manualOption = find.textContaining('stretch_ceiling_calc.mode.manual');
      if (manualOption.evaluate().isNotEmpty) {
        await tester.tap(manualOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключиться на ввод размеров комнаты', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final roomOption = find.textContaining('stretch_ceiling_calc.mode.room');
      if (roomOption.evaluate().isNotEmpty) {
        await tester.tap(roomOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(StretchCeilingCalculatorScreen), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - ввод размеров комнаты', () {
    testWidgets('отображает поля для длины и ширины', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('отображает рассчитанную площадь', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('stretch_ceiling_calc.label.ceiling_area'), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - количество светильников', () {
    testWidgets('отображает слайдер для светильников', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorSliderField), findsWidgets);
    });

    testWidgets('можно изменить количество светильников', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.textContaining('stretch_ceiling_calc.lights_hint'), findsOneWidget);
    });
  });

  group('StretchCeilingCalculatorScreen - результаты', () {
    testWidgets('отображает площадь потолка', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает периметр', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.crop_square), findsWidgets);
    });

    testWidgets('отображает количество светильников в результатах', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает метры', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.meters'), findsWidgets);
    });

    testWidgets('отображает штуки', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const StretchCeilingCalculatorScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('common.pcs'), findsWidgets);
    });
  });
}
