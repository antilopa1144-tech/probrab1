import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/components/modern_card.dart';

void main() {
  group('ModernCard', () {
    testWidgets('renders child widget', (tester) async {
      const testText = 'Test Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(32);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernCard(
              padding: customPadding,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ModernCard),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.padding, customPadding);
    });

    testWidgets('applies custom margin', (tester) async {
      const customMargin = EdgeInsets.all(16);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernCard(
              margin: customMargin,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ModernCard),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.margin, customMargin);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernCard(
              onTap: () => tapped = true,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('animates on tap when animation enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernCard(
              enableAnimation: true,
              onTap: () {},
              child: const Text('Test'),
            ),
          ),
        ),
      );

      // Find the GestureDetector
      final gesture = find.byType(GestureDetector);
      expect(gesture, findsOneWidget);

      // Verify ScaleTransition exists within ModernCard
      final scaleTransition = find.descendant(
        of: find.byType(ModernCard),
        matching: find.byType(ScaleTransition),
      );
      expect(scaleTransition, findsOneWidget);
    });

    testWidgets('does not animate when animation disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernCard(
              enableAnimation: false,
              onTap: () {},
              child: const Text('Test'),
            ),
          ),
        ),
      );

      // Should not have ScaleTransition within ModernCard when animation is disabled
      final scaleTransition = find.descendant(
        of: find.byType(ModernCard),
        matching: find.byType(ScaleTransition),
      );
      expect(scaleTransition, findsNothing);
    });

    testWidgets('uses custom background color', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernCard(
              backgroundColor: customColor,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ModernCard),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, customColor);
    });

    testWidgets('uses custom border radius', (tester) async {
      const customRadius = 30.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernCard(
              borderRadius: customRadius,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ModernCard),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(customRadius));
    });

    testWidgets('has no GestureDetector when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('ModernGradientButton', () {
    testWidgets('renders label', (tester) async {
      const testLabel = 'Click Me';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: testLabel,
            ),
          ),
        ),
      );

      expect(find.text(testLabel), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernGradientButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernGradientButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows icon when provided', (tester) async {
      const testIcon = Icons.add;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              icon: testIcon,
            ),
          ),
        ),
      );

      final iconFinder = find.descendant(
        of: find.byType(ModernGradientButton),
        matching: find.byIcon(testIcon),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('does not show icon when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              icon: Icons.add,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses custom gradient when provided', (tester) async {
      const customGradient = LinearGradient(
        colors: [Colors.red, Colors.blue],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              gradient: customGradient,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ModernGradientButton),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, customGradient);
    });

    testWidgets('animates on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernGradientButton(
              label: 'Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Verify ScaleTransition exists within ModernGradientButton
      final scaleTransition = find.descendant(
        of: find.byType(ModernGradientButton),
        matching: find.byType(ScaleTransition),
      );
      expect(scaleTransition, findsOneWidget);

      // Tap and verify animation still exists
      await tester.tap(find.byType(ModernGradientButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(scaleTransition, findsOneWidget);
    });
  });
}
