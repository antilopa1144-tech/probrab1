import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/plumbing_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('PlumbingCalculatorScreen -', () {
    testWidgets('отрисовывается корректно', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlumbingCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает селектор типа сантехники', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть селектор типа сантехники
      expect(find.byType(TypeSelectorGroup), findsOneWidget);

      // Должны быть иконки для типов сантехники
      expect(find.byIcon(Icons.water_drop), findsWidgets);
      expect(find.byIcon(Icons.spa), findsWidgets);
      expect(find.byIcon(Icons.savings), findsWidgets);
    });

    testWidgets('имеет кнопки экспорта и копирования', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('отображает слайдер для настройки', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('показывает результаты в заголовке', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен отображать результаты
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.pcs'), findsWidgets);
      expect(find.textContaining('common.meters'), findsWidgets);
    });

    testWidgets('имеет счетчики для помещений', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должны быть кнопки увеличения/уменьшения количества
      expect(find.byIcon(Icons.remove_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
    });

    testWidgets('отображает переключатель горячей воды', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть переключатель для горячей воды
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('корректно уничтожается', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(PlumbingCalculatorScreen), findsNothing);
    });

    testWidgets('можно взаимодействовать со слайдером длины труб', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final sliders = find.byType(Slider);
      expect(sliders, findsOneWidget);

      await tester.tap(sliders.first);
      await tester.pump();

      expect(find.byType(PlumbingCalculatorScreen), findsOneWidget);
    });

    testWidgets('можно увеличить количество ванных', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PlumbingCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Находим кнопки добавления
      final addButtons = find.byIcon(Icons.add_circle_outline);
      expect(addButtons, findsWidgets);

      // Нажимаем на первую кнопку добавления
      await tester.tap(addButtons.first);
      await tester.pump();

      expect(find.byType(PlumbingCalculatorScreen), findsOneWidget);
    });
  });
}
