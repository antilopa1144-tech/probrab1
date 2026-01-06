import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_hint.dart';
import 'package:probrab_ai/presentation/widgets/existing/hint_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('HintCard', () {
    testWidgets('renders with info type', (tester) async {
      const hint = CalculatorHint(
        type: HintType.info,
        message: 'Test info message',
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintCard(hint: hint),
          ),
        ),
      );

      expect(find.text('Test info message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('renders with warning type', (tester) async {
      const hint = CalculatorHint(
        type: HintType.warning,
        message: 'Test warning message',
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintCard(hint: hint),
          ),
        ),
      );

      expect(find.text('Test warning message'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders with tip type', (tester) async {
      const hint = CalculatorHint(
        type: HintType.tip,
        message: 'Test tip message',
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintCard(hint: hint),
          ),
        ),
      );

      expect(find.text('Test tip message'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });

    testWidgets('renders with important type', (tester) async {
      const hint = CalculatorHint(
        type: HintType.important,
        message: 'Test important message',
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintCard(hint: hint),
          ),
        ),
      );

      expect(find.text('Test important message'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    });

    testWidgets('shows close button when onDismiss provided', (tester) async {
      bool dismissed = false;
      const hint = CalculatorHint(
        type: HintType.info,
        message: 'Dismissible hint',
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: HintCard(
              hint: hint,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, true);
    });

    testWidgets('hides close button when onDismiss is null', (tester) async {
      const hint = CalculatorHint(
        type: HintType.info,
        message: 'Non-dismissible hint',
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintCard(hint: hint),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('renders in Card', (tester) async {
      const hint = CalculatorHint(
        type: HintType.info,
        message: 'Card hint',
      );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintCard(hint: hint),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('HintsList', () {
    testWidgets('renders nothing when hints is empty', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintsList(hints: []),
          ),
        ),
      );

      expect(find.byType(HintCard), findsNothing);
    });

    testWidgets('renders all hints', (tester) async {
      const hints = [
        CalculatorHint(type: HintType.info, message: 'Info 1'),
        CalculatorHint(type: HintType.warning, message: 'Warning 1'),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintsList(hints: hints),
          ),
        ),
      );

      expect(find.text('Info 1'), findsOneWidget);
      expect(find.text('Warning 1'), findsOneWidget);
    });

    testWidgets('shows dismiss buttons when dismissible', (tester) async {
      const hints = [
        CalculatorHint(type: HintType.info, message: 'Dismissible hint'),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintsList(hints: hints, dismissible: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides hint when dismissed', (tester) async {
      const hints = [
        CalculatorHint(type: HintType.info, message: 'First hint'),
        CalculatorHint(type: HintType.warning, message: 'Second hint'),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintsList(hints: hints, dismissible: true),
          ),
        ),
      );

      expect(find.text('First hint'), findsOneWidget);
      expect(find.text('Second hint'), findsOneWidget);

      // Dismiss first hint
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(find.text('First hint'), findsNothing);
      expect(find.text('Second hint'), findsOneWidget);
    });

    testWidgets('hides close buttons when not dismissible', (tester) async {
      const hints = [
        CalculatorHint(type: HintType.info, message: 'Non-dismissible'),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: HintsList(hints: hints, dismissible: false),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
