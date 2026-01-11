import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/putty_calculator_screen.dart';

import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('PuttyCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreen()),
      );
      await tester.pump();

      expect(find.byType(PuttyCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreen()),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input fields', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreen()),
      );
      await tester.pump();

      // Putty calculator uses TextField inputs instead of sliders
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('uses Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreen()),
      );
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreen()),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(child: const PuttyCalculatorScreen()),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(PuttyCalculatorScreen), findsNothing);
    });
  });
}
