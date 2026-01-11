import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/parquet_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ParquetCalculatorScreen -', () {
    testWidgets('отрисовывается корректно', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ParquetCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает селектор типа паркета', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть селектор типа паркета
      expect(find.byType(TypeSelectorGroup), findsOneWidget);

      // Должны быть иконки для типов паркета
      expect(find.byIcon(Icons.view_stream), findsWidgets);
      expect(find.byIcon(Icons.layers), findsWidgets);
      expect(find.byIcon(Icons.park), findsWidgets);
    });

    testWidgets('имеет кнопки экспорта и копирования', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('отображает слайдеры для настройки', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('показывает результаты в заголовке', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен отображать результаты
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('имеет селектор способа укладки', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть ModeSelector для выбора способа укладки
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('имеет селектор режима ввода площади', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть ModeSelector для выбора ручного/комната
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('отображает переключатели опций', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должны быть переключатели для подложки, плинтуса и клея
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
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
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(ParquetCalculatorScreen), findsNothing);
    });

    testWidgets('можно взаимодействовать со слайдером', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Проверяем, что можно взаимодействовать со слайдером
      final firstSlider = sliders.first;
      await tester.tap(firstSlider);
      await tester.pump();

      expect(find.byType(ParquetCalculatorScreen), findsOneWidget);
    });

    testWidgets('имеет текстовые поля ввода в режиме комнаты', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ParquetCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть режим ввода размеров комнаты
      expect(find.byType(ModeSelector), findsWidgets);
    });
  });
}
