import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/wood_lining_calculator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    setupMocks();
    testDefinition = getCalculatorDefinition('walls_wood');
  });

  group('WoodLiningCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pump();

      expect(find.byType(WoodLiningCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input fields', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );

      expect(find.byType(WoodLiningCalculatorScreen), findsNothing);
    });

    testWidgets('can enter text in TextField', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.tap(textField);
      await tester.pumpAndSettle();
      await tester.enterText(textField, '15');
      await tester.pumpAndSettle();

      expect(find.byType(WoodLiningCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(WoodLiningCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WoodLiningCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 25.0,
            },
          ),
          overrides: CalculatorMockOverrides.woodLining,
        ),
      );
      await tester.pump();

      expect(find.byType(WoodLiningCalculatorScreen), findsOneWidget);
    });
  });
}
