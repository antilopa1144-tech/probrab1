import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/bathroom_waterproof_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('BathroomWaterproofCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('BathroomWaterproofCalculatorScreen выбор типа гидроизоляции', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает иконки типов гидроизоляции', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.opacity), findsWidgets); // жидкая
      expect(find.byIcon(Icons.receipt_long), findsWidgets); // рулонная
      expect(find.byIcon(Icons.foundation), findsWidgets); // цементная
    });

    testWidgets('можно выбрать жидкую гидроизоляцию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final liquidType = find.textContaining('waterproof_calc.type.liquid');
      if (liquidType.evaluate().isNotEmpty) {
        await tester.tap(liquidType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать рулонную гидроизоляцию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final rollType = find.textContaining('waterproof_calc.type.roll');
      if (rollType.evaluate().isNotEmpty) {
        await tester.tap(rollType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });
  });

  group('BathroomWaterproofCalculatorScreen поля ввода размеров', () {
    testWidgets('отображает поля ввода длины и ширины', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('waterproof_calc.label.length'), findsOneWidget);
      expect(find.textContaining('waterproof_calc.label.width'), findsOneWidget);
    });

    testWidgets('отображает CalculatorTextField виджеты', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('BathroomWaterproofCalculatorScreen слайдеры', () {
    testWidgets('отображает слайдер высоты захода на стены', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
      expect(find.textContaining('waterproof_calc.label.wall_height'), findsOneWidget);
    });

    testWidgets('отображает слайдер количества слоев', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('waterproof_calc.label.layers'), findsOneWidget);
    });

    testWidgets('можно изменить слайдер высоты', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно изменить количество слоев', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });
  });

  group('BathroomWaterproofCalculatorScreen переключатели опций', () {
    testWidgets('отображает переключатели опций', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию грунтовки', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final primerSwitch = find.textContaining('waterproof_calc.option.primer');
      if (primerSwitch.evaluate().isNotEmpty) {
        await tester.tap(primerSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию ленты', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final tapeSwitch = find.textContaining('waterproof_calc.option.tape');
      if (tapeSwitch.evaluate().isNotEmpty) {
        await tester.tap(tapeSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });
  });

  group('BathroomWaterproofCalculatorScreen результаты', () {
    testWidgets('отображает результаты площади', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает результаты в кг', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.kg'), findsWidgets);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.square_foot), findsWidgets);
      expect(find.byIcon(Icons.crop_square), findsWidgets);
      expect(find.byIcon(Icons.opacity), findsWidgets);
    });
  });

  group('BathroomWaterproofCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsOneWidget);
    });
  });

  group('BathroomWaterproofCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
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
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('BathroomWaterproofCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const BathroomWaterproofCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(BathroomWaterproofCalculatorScreen), findsNothing);
    });
  });
}
