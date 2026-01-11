import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/primer_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('PrimerCalculatorScreen -', () {
    testWidgets('отрисовывается корректно', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PrimerCalculatorScreen), findsOneWidget);
      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('отображает селектор типа поверхности', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть селектор типа поверхности
      expect(find.byType(TypeSelectorGroup), findsOneWidget);

      // Должны быть иконки для типов поверхности
      expect(find.byIcon(Icons.foundation), findsWidgets);
      expect(find.byIcon(Icons.format_paint), findsWidgets);
      expect(find.byIcon(Icons.grid_view), findsWidgets);
    });

    testWidgets('имеет кнопки экспорта и копирования', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
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
          child: const PrimerCalculatorScreen(),
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
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен отображать результаты
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
      expect(find.textContaining('common.sqm'), findsWidgets);
      expect(find.textContaining('common.liters'), findsWidgets);
    });

    testWidgets('имеет селектор типа грунтовки', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть ModeSelector для выбора типа грунтовки
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('имеет селектор режима ввода площади', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть ModeSelector для выбора ручного/комната
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('отображает слайдер количества слоев', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должны быть слайдеры для слоев и размера банки
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
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
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(PrimerCalculatorScreen), findsNothing);
    });

    testWidgets('можно взаимодействовать со слайдером', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
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

      expect(find.byType(PrimerCalculatorScreen), findsOneWidget);
    });

    testWidgets('имеет текстовые поля ввода в режиме комнаты', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const PrimerCalculatorScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Должен быть режим ввода размеров комнаты
      expect(find.byType(ModeSelector), findsWidgets);
    });
  });
}
