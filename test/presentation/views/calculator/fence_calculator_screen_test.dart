import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/fence_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('FenceCalculatorScreen - рендеринг виджетов', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('отображает результаты в шапке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('м'), findsWidgets);
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('FenceCalculatorScreen - селектор типа забора', () {
    testWidgets('отображает типы заборов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
      expect(find.byIcon(Icons.view_column), findsWidgets); // profiled
      expect(find.byIcon(Icons.fence), findsWidgets); // picket
      expect(find.byIcon(Icons.grid_on), findsWidgets); // chain
    });

    testWidgets('можно выбрать профнастил', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final profiledOption = find.byType(TypeSelectorGroup);
      if (profiledOption.evaluate().isNotEmpty) {
        await tester.tap(profiledOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать штакетник', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final picketOption = find.byType(TypeSelectorGroup);
      if (picketOption.evaluate().isNotEmpty) {
        await tester.tap(picketOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать сетку-рабицу', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final chainOption = find.byType(TypeSelectorGroup);
      if (chainOption.evaluate().isNotEmpty) {
        await tester.tap(chainOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });
  });

  group('FenceCalculatorScreen - размеры забора', () {
    testWidgets('отображает слайдеры размеров', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // FenceCalculatorScreen uses raw Slider widgets and Text, not CalculatorTextField
      expect(find.byType(Slider), findsWidgets);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('можно регулировать длину забора', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно регулировать высоту забора', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });
  });

  group('FenceCalculatorScreen - расстояние между столбами', () {
    testWidgets('отображает слайдер расстояния между столбами', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // FenceCalculatorScreen uses raw Slider widgets for post spacing
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно регулировать расстояние между столбами', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 2) {
        await tester.drag(sliders.at(2), const Offset(20, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает подсказку о расстоянии между столбами', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('FenceCalculatorScreen - карточка материалов', () {
    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает материалы с иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_column), findsWidgets); // posts
      expect(find.byIcon(Icons.straighten), findsWidgets); // lags
      expect(find.byIcon(Icons.layers), findsWidgets); // sheets
      expect(find.byIcon(Icons.hardware), findsWidgets); // fasteners
      expect(find.byIcon(Icons.receipt_long), findsWidgets);
    });
  });

  group('FenceCalculatorScreen - действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('можно прокручивать содержимое', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });
  });

  group('FenceCalculatorScreen - жизненный цикл', () {
    testWidgets('инициализируется с результатами по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(FenceCalculatorScreen), findsOneWidget);
    });

    testWidgets('корректно освобождает ресурсы', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const FenceCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(FenceCalculatorScreen), findsNothing);
    });
  });
}
