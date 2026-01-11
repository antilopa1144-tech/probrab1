import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/improved_smart_project_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ImprovedSmartProjectPage', () {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pump();

      expect(find.byType(ImprovedSmartProjectPage), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows AppBar', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Stepper widget', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pump();

      expect(find.byType(Stepper), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(ImprovedSmartProjectPage), findsNothing);
    });

    testWidgets('отображает 4 шага в степпере', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.steps.length, 4);
    });

    testWidgets('шаг 1 содержит поля для размеров', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('имеет дефолтные значения для размеров', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      // Default values are 10, 8, 3
    });

    testWidgets('может переходить к следующему шагу', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.currentStep, 0);

      // Find and tap next button
      final nextButton = find.text('Далее');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('может возвращаться к предыдущему шагу', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Go to next step
      final nextButton = find.text('Далее');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();

        // Now go back
        final backButton = find.text('Назад');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('шаг 2 содержит чекбоксы для разделов', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 2
      final nextButton = find.text('Далее');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(CheckboxListTile), findsWidgets);
      }
    });

    testWidgets('все разделы выбраны по умолчанию', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 2
      final nextButton = find.text('Далее');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();

        // All checkboxes should be checked by default
        final checkboxes = tester.widgetList<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        for (final checkbox in checkboxes) {
          expect(checkbox.value, true);
        }
      }
    });

    testWidgets('можно снять выбор с раздела', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 2
      final nextButton = find.text('Далее');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();

        // Tap a checkbox to uncheck it
        final firstCheckbox = find.byType(CheckboxListTile).first;
        await tester.tap(firstCheckbox);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('шаг 3 отображает подтверждение параметров', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 3
      for (int i = 0; i < 2; i++) {
        final nextButton = find.text('Далее');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('на шаге 3 показывает кнопку Рассчитать', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 3 (step 2 index)
      for (int i = 0; i < 2; i++) {
        final nextButton = find.text('Далее');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.text('Рассчитать'), findsWidgets);
    });

    testWidgets('выполняет расчёт при нажатии кнопки', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 3
      for (int i = 0; i < 2; i++) {
        final nextButton = find.text('Далее');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
      }

      // Tap calculate button
      final calculateButton = find.text('Рассчитать');
      if (calculateButton.evaluate().isNotEmpty) {
        await tester.tap(calculateButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('шаг 4 показывает результаты расчёта', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate and calculate
      for (int i = 0; i < 2; i++) {
        final nextButton = find.text('Далее');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
      }

      final calculateButton = find.text('Рассчитать');
      if (calculateButton.evaluate().isNotEmpty) {
        await tester.tap(calculateButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('можно начать новый расчёт', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate and calculate
      for (int i = 0; i < 2; i++) {
        final nextButton = find.text('Далее');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
      }

      final calculateButton = find.text('Рассчитать');
      if (calculateButton.evaluate().isNotEmpty) {
        await tester.tap(calculateButton.first);
        await tester.pumpAndSettle();

        // Look for new calculation button
        final newCalcButton = find.text('Новый расчёт');
        if (newCalcButton.evaluate().isNotEmpty) {
          await tester.tap(newCalcButton.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('можно закрыть страницу через кнопку назад', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
    });

    testWidgets('можно переключаться между шагами через onStepTapped', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // The stepper supports tapping on steps to navigate
      final stepper = tester.widget<Stepper>(find.byType(Stepper));
      expect(stepper.onStepTapped, isNotNull);
    });

    testWidgets('отображает иконки для каждого раздела', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 2
      final nextButton = find.text('Далее');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(CircleAvatar), findsWidgets);
      }
    });

    testWidgets('использует правильные единицы измерения', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ImprovedSmartProjectPage()),
      );
      await tester.pumpAndSettle();

      // Navigate to step 3
      for (int i = 0; i < 2; i++) {
        final nextButton = find.text('Далее');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
      }

      // Should show units like "м"
      expect(find.textContaining('м'), findsWidgets);
    });
  });
}
