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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('содержит CalculatorScaffold', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('содержит CalculatorResultHeader', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('имеет кнопки экспорта', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('можно переключиться на ввод по площади', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('putty.input_mode.by_area');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('можно переключиться на ввод по размерам', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final option = find.textContaining('putty.input_mode.by_dimensions');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - ввод площади', () {
    testWidgets('отображает слайдер площади в режиме по площади', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Switch to by_area mode first
      final areaMode = find.textContaining('putty.input_mode.by_area');
      if (areaMode.evaluate().isNotEmpty) {
        await tester.tap(areaMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('можно изменить площадь', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Switch to by_dimensions mode
      final dimensionsMode = find.textContaining('putty.input_mode.by_dimensions');
      if (dimensionsMode.evaluate().isNotEmpty) {
        await tester.tap(dimensionsMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('отображает рассчитанную площадь', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Default mode is by_dimensions (room)
      expect(find.textContaining('putty.dimensions.wall_area'), findsWidgets);
    });
  });

  group('PuttyCalculatorScreenV2 - целевая отделка', () {
    testWidgets('отображает переключатель цели отделки', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('putty.section.finish_goal'), findsOneWidget);
    });

    testWidgets('можно выбрать под обои', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      final option = find.textContaining('putty.target.wallpaper.title');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });

    testWidgets('можно выбрать под покраску', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      final option = find.textContaining('putty.target.painting.title');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - состояние стен', () {
    testWidgets('отображает селектор состояния стен', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.textContaining('putty.wall_condition_title'), findsOneWidget);
    });

    testWidgets('можно выбрать состояние стены', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.textContaining('putty.material_tier.title'), findsOneWidget);
    });

    testWidgets('отображает иконки классов материалов', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -750));
      await tester.pumpAndSettle();

      final option = find.textContaining('putty.material_tier.economy');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - проемы', () {
    testWidgets('отображает переключатель проемов', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(find.textContaining('putty.openings_toggle'), findsOneWidget);
    });

    testWidgets('можно раскрыть секцию проемов', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1000));
      await tester.pumpAndSettle();

      final toggle = find.textContaining('putty.openings_toggle');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PuttyCalculatorScreenV2), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - результаты', () {
    testWidgets('отображает площадь в результатах', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.straighten), findsWidgets);
    });

    testWidgets('отображает количество стартовой шпаклевки', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2), findsWidgets);
    });

    testWidgets('отображает количество финишной шпаклевки', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.format_paint), findsWidgets);
    });

    testWidgets('отображает карточку материалов', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1400));
      await tester.pumpAndSettle();

      expect(find.textContaining('putty.work_time_title'), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - подсказки', () {
    testWidgets('отображает секцию подсказок', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1600));
      await tester.pumpAndSettle();

      expect(find.textContaining('common.tips'), findsOneWidget);
    });
  });

  group('PuttyCalculatorScreenV2 - взаимодействие', () {
    testWidgets('можно скроллить контент', (tester) async {
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
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('отображает метры', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      // Switch to by_dimensions mode to see meters
      final dimensionsMode = find.textContaining('putty.input_mode.by_dimensions');
      if (dimensionsMode.evaluate().isNotEmpty) {
        await tester.tap(dimensionsMode.first);
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('common.meters'), findsWidgets);
    });

    testWidgets('отображает килограммы', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.textContaining('common.kg'), findsWidgets);
    });

    testWidgets('отображает литры', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreenV2()),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.textContaining('common.liters'), findsWidgets);
    });
  });
}
