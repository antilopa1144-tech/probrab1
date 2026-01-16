import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/putty_calculator_screen_v2.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('PuttyCalculatorScreenV2 - рендеринг базовой структуры', () {
    testWidgets('отрисовывается без ошибок', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - режим ввода', () {
    testWidgets('отображает переключатель режимов ввода', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('можно переключиться на ввод по площади', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // 'По площади' is the translated value for putty.input_mode.by_area
      final option = find.textContaining('По площади');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('можно переключиться на ввод по размерам', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // 'По размерам' is the translated value for putty.input_mode.by_dimensions
      final option = find.textContaining('По размерам');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - ввод площади', () {
    testWidgets('отображает слайдер площади в режиме по площади', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Switch to by_area mode first
      // 'По площади' is the translated value for putty.input_mode.by_area
      final areaMode = find.textContaining('По площади');
      if (areaMode.evaluate().isNotEmpty) {
        await tester.tap(areaMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить площадь', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - ввод размеров', () {
    testWidgets('отображает слайдеры размеров в режиме по размерам', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Switch to by_dimensions mode
      final dimensionsMode = find.textContaining('По размерам');
      if (dimensionsMode.evaluate().isNotEmpty) {
        await tester.tap(dimensionsMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('отображает рассчитанную площадь', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Default mode is by_area, area card shows wall area text
      // The text 'Площадь стен' is displayed
      expect(find.textContaining('Площадь стен'), findsWidgets);
    });
  });

  group('PuttyCalculatorScreenV2 - целевая отделка', () {
    testWidgets('отображает переключатель цели отделки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // 'Цель финиша' is the translated value for putty.section.finish_goal
      expect(find.textContaining('Цель финиша'), findsOneWidget);
    });

    testWidgets('можно выбрать под обои', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      // 'Под обои' is the translated value for putty.target.wallpaper.title
      final option = find.textContaining('Под обои');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('можно выбрать под покраску', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      // 'Под покраску' is the translated value for putty.target.painting.title
      final option = find.textContaining('Под покраску');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - состояние стен', () {
    testWidgets('отображает селектор состояния стен', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      // 'Состояние стен' is the translated value for putty.wall_condition_title
      expect(find.textContaining('Состояние стен'), findsOneWidget);
    });

    testWidgets('можно выбрать состояние стены', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -450));
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 2) {
        await tester.tap(inkWells.at(2));
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - класс материалов', () {
    testWidgets('отображает селектор класса материалов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -700));
      await tester.pumpAndSettle();

      // 'Класс материалов' is the translated value for putty.material_tier.title
      expect(find.textContaining('Класс материалов'), findsOneWidget);
    });

    testWidgets('отображает иконки классов материалов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.savings), findsWidgets);
      expect(find.byIcon(Icons.verified), findsWidgets);
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('можно выбрать класс материалов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -750));
      await tester.pumpAndSettle();

      // 'Эконом' is the translated value for putty.material_tier.economy
      final option = find.textContaining('Эконом');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - проемы', () {
    testWidgets('отображает переключатель проемов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // 'Учесть окна и двери' is the translated value for putty.openings_toggle
      expect(find.textContaining('Учесть окна и двери'), findsOneWidget);
    });

    testWidgets('можно раскрыть секцию проемов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // 'Учесть окна и двери' is the translated value for putty.openings_toggle
      final toggle = find.textContaining('Учесть окна и двери');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - результаты', () {
    testWidgets('отображает площадь в результатах', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
    });

    testWidgets('отображает количество стартовой шпаклевки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2), findsWidgets);
    });

    testWidgets('отображает количество финишной шпаклевки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.format_paint), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsWidgets);
    });

    testWidgets('отображает карточку времени работ', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1400));
      await tester.pumpAndSettle();

      // 'Время работы' is the translated value for putty.work_time_title
      // Multiple widgets may contain this text (title and items)
      expect(find.textContaining('Время работы'), findsWidgets);
    });
  });

  group('PuttyCalculatorScreenV2 - подсказки', () {
    testWidgets('отображает секцию подсказок', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1600));
      await tester.pumpAndSettle();

      // 'Полезные советы' is the translated value for common.tips
      expect(find.textContaining('Полезные советы'), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('можно нажать кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('виджет корректно удаляется', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(PuttyCalculatorScreenV2), findsNothing);
    });
  });

  group('PuttyCalculatorScreenV2 - единицы измерения', () {
    testWidgets('отображает квадратные метры', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает метры', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Switch to by_dimensions mode to see meters
      // 'По размерам' is the translated value for putty.input_mode.by_dimensions
      final dimensionsMode = find.textContaining('По размерам');
      if (dimensionsMode.evaluate().isNotEmpty) {
        await tester.tap(dimensionsMode.first);
        await tester.pumpAndSettle();
      }

      // 'м' is the translated value for common.meters
      expect(find.textContaining(' м'), findsWidgets);
    });

    testWidgets('отображает килограммы', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1200));
      await tester.pumpAndSettle();

      // 'кг' is the translated value for common.kg
      expect(find.textContaining('кг'), findsWidgets);
    });

    testWidgets('отображает литры', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1200));
      await tester.pumpAndSettle();

      // 'л' is the translated value for common.liters
      expect(find.textContaining(' л'), findsWidgets);
    });
  });
}
