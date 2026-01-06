import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/existing/calculator_tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CalculatorTutorial', () {
    testWidgets('renders child widget', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorTutorial(
            tutorialId: 'test_tutorial',
            child: Text('Test Child'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('renders with Scaffold child', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorTutorial(
            tutorialId: 'test_tutorial',
            child: Scaffold(body: Center(child: Text('Content'))),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorTutorial(
            tutorialId: 'test_tutorial',
            child: Text('Test'),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(child: const SizedBox.shrink()),
      );

      expect(find.byType(CalculatorTutorial), findsNothing);
    });
  });

  group('CalculatorTutorial static methods', () {
    test('shouldShow returns true for new tutorial', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await CalculatorTutorial.shouldShow('new_tutorial');

      expect(result, isTrue);
    });

    test('shouldShow returns false for viewed tutorial', () async {
      SharedPreferences.setMockInitialValues({
        'tutorial_viewed_tutorial': true,
      });

      final result = await CalculatorTutorial.shouldShow('viewed_tutorial');

      expect(result, isFalse);
    });

    test('complete marks tutorial as viewed', () async {
      SharedPreferences.setMockInitialValues({});

      await CalculatorTutorial.complete('complete_tutorial');

      final prefs = await SharedPreferences.getInstance();
      final viewed = prefs.getBool('tutorial_complete_tutorial');
      expect(viewed, isTrue);
    });
  });
}
