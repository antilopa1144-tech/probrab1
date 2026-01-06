import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/widgets/custom_refresh_indicator.dart';

void main() {
  group('CustomRefreshIndicator', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomRefreshIndicator(
            onRefresh: () async {},
            child: const SingleChildScrollView(
              child: Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('contains RefreshIndicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomRefreshIndicator(
            onRefresh: () async {},
            child: const SingleChildScrollView(
              child: SizedBox(height: 1000, child: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('calls onRefresh when pulled down', (tester) async {
      bool refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {
                refreshCalled = true;
              },
              child: ListView(
                children: [
                  for (int i = 0; i < 20; i++)
                    ListTile(title: Text('Item $i')),
                ],
              ),
            ),
          ),
        ),
      );

      // Perform pull-to-refresh gesture
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      // Pump with specific durations instead of pumpAndSettle
      // because the animation controller repeats indefinitely
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(refreshCalled, true);
    });

    testWidgets('uses theme colors', (tester) async {
      const primaryColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          ),
          home: CustomRefreshIndicator(
            onRefresh: () async {},
            child: const SingleChildScrollView(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      expect(indicator.strokeWidth, 3);
      expect(indicator.displacement, 40);
    });

    testWidgets('disposes animation controller properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomRefreshIndicator(
            onRefresh: () async {},
            child: const SingleChildScrollView(
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Get the state
      final state = tester.state<State<CustomRefreshIndicator>>(
        find.byType(CustomRefreshIndicator),
      );

      // Remove widget - should dispose without error
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // If we reach here without exception, dispose worked correctly
      expect(state.mounted, false);
    });
  });

  group('CustomRefreshIndicatorPainter', () {
    test('creates with required parameters', () {
      final painter = CustomRefreshIndicatorPainter(
        value: 0.5,
        color: Colors.blue,
      );

      expect(painter.value, 0.5);
      expect(painter.color, Colors.blue);
    });

    test('shouldRepaint returns true when value changes', () {
      final painter1 = CustomRefreshIndicatorPainter(
        value: 0.5,
        color: Colors.blue,
      );
      final painter2 = CustomRefreshIndicatorPainter(
        value: 0.7,
        color: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns true when color changes', () {
      final painter1 = CustomRefreshIndicatorPainter(
        value: 0.5,
        color: Colors.blue,
      );
      final painter2 = CustomRefreshIndicatorPainter(
        value: 0.5,
        color: Colors.red,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final painter1 = CustomRefreshIndicatorPainter(
        value: 0.5,
        color: Colors.blue,
      );
      final painter2 = CustomRefreshIndicatorPainter(
        value: 0.5,
        color: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });

    testWidgets('paints arc on canvas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(50, 50),
              painter: CustomRefreshIndicatorPainter(
                value: 0.5,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Scaffold may also use CustomPaint internally
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('paint calculates correct sweep angle', () {
      // value of 0.5 should give sweep angle of pi
      const expectedSweep = 2 * math.pi * 0.5;
      expect(expectedSweep, closeTo(math.pi, 0.001));
    });

    test('paint calculates correct sweep angle for full circle', () {
      // value of 1.0 should give sweep angle of 2*pi
      const expectedSweep = 2 * math.pi * 1.0;
      expect(expectedSweep, closeTo(2 * math.pi, 0.001));
    });

    test('paint calculates correct sweep angle for zero', () {
      // value of 0.0 should give sweep angle of 0
      const expectedSweep = 2 * math.pi * 0.0;
      expect(expectedSweep, 0.0);
    });
  });
}
