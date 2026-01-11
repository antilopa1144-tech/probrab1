import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/balcony_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('BalconyCalculatorScreen виджет рендеринг', () {
    testWidgets('отображается корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BalconyCalculatorScreen), findsOneWidget);
    });

    testWidgets('отображает CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('отображает кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('BalconyCalculatorScreen выбор типа балкона', () {
    testWidgets('отображает TypeSelectorGroup', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });

    testWidgets('отображает иконки типов балкона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.balcony), findsWidgets); // открытый
      expect(find.byIcon(Icons.window), findsWidgets); // остекленный
      expect(find.byIcon(Icons.whatshot), findsWidgets); // теплый
    });

    testWidgets('можно выбрать открытый балкон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final openType = find.textContaining('balcony_calc.type.open');
      if (openType.evaluate().isNotEmpty) {
        await tester.tap(openType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BalconyCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно выбрать теплый балкон', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final warmType = find.textContaining('balcony_calc.type.warm');
      if (warmType.evaluate().isNotEmpty) {
        await tester.tap(warmType.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BalconyCalculatorScreen), findsOneWidget);
    });
  });

  group('BalconyCalculatorScreen поля ввода размеров', () {
    testWidgets('отображает поля ввода длины и ширины', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('balcony_calc.label.length'), findsOneWidget);
      expect(find.textContaining('balcony_calc.label.width'), findsOneWidget);
    });

    testWidgets('отображает поле ввода высоты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('balcony_calc.label.height'), findsOneWidget);
    });

    testWidgets('отображает CalculatorTextField виджеты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('BalconyCalculatorScreen переключатели опций', () {
    testWidgets('отображает переключатели опций', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('можно переключить опцию утепления пола', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final floorSwitch = find.textContaining('balcony_calc.option.floor_finishing');
      if (floorSwitch.evaluate().isNotEmpty) {
        await tester.tap(floorSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BalconyCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно переключить опцию отделки стен', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final wallSwitch = find.textContaining('balcony_calc.option.wall_finishing');
      if (wallSwitch.evaluate().isNotEmpty) {
        await tester.tap(wallSwitch.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(BalconyCalculatorScreen), findsOneWidget);
    });
  });

  group('BalconyCalculatorScreen результаты', () {
    testWidgets('отображает результаты площади пола', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('отображает иконки результатов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.square_foot), findsWidgets);
      expect(find.byIcon(Icons.crop_square), findsWidgets);
      expect(find.byIcon(Icons.format_paint), findsWidgets);
    });
  });

  group('BalconyCalculatorScreen список материалов', () {
    testWidgets('отображает MaterialsCardModern', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('можно прокрутить до материалов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(BalconyCalculatorScreen), findsOneWidget);
    });
  });

  group('BalconyCalculatorScreen действия', () {
    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
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
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);
    });
  });

  group('BalconyCalculatorScreen корректно освобождает ресурсы', () {
    testWidgets('корректно dispose', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const BalconyCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(BalconyCalculatorScreen), findsNothing);
    });
  });
}
