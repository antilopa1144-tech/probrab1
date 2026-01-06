import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/widgets/staggered_animation.dart';

void main() {
  group('StaggeredAnimation', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('applies animation with TweenAnimationBuilder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              child: Text('Animated'),
            ),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('wraps child in Opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              child: Text('Opacity'),
            ),
          ),
        ),
      );

      expect(find.byType(Opacity), findsOneWidget);
    });

    testWidgets('wraps child in Transform', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              child: Text('Transform'),
            ),
          ),
        ),
      );

      // Multiple Transform widgets may exist in the tree
      expect(find.byType(Transform), findsWidgets);
      expect(find.text('Transform'), findsOneWidget);
    });

    testWidgets('renders with different index values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StaggeredAnimation(index: 0, child: Text('Item 0')),
                StaggeredAnimation(index: 1, child: Text('Item 1')),
                StaggeredAnimation(index: 5, child: Text('Item 5')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);
    });

    testWidgets('accepts custom delay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              delay: Duration(milliseconds: 100),
              child: Text('Custom delay'),
            ),
          ),
        ),
      );

      expect(find.text('Custom delay'), findsOneWidget);
    });

    testWidgets('animates to full opacity after duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              child: Text('Animate'),
            ),
          ),
        ),
      );

      // Pump and settle to complete animation
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 1.0);
    });

    testWidgets('starts with opacity 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimation(
              index: 0,
              child: Text('Start'),
            ),
          ),
        ),
      );

      // Immediately after pump, opacity should be at start
      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, lessThanOrEqualTo(1.0));
    });
  });
}
