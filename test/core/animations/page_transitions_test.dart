import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/animations/page_transitions.dart';

void main() {
  group('ModernPageTransitions', () {
    testWidgets('slideUp creates PageRouteBuilder', (tester) async {
      final route = ModernPageTransitions.slideUp(
        const Text('Test Page'),
      );

      expect(route, isA<PageRouteBuilder>());
      expect(route.transitionDuration, const Duration(milliseconds: 300));
    });

    testWidgets('slideRight creates PageRouteBuilder', (tester) async {
      final route = ModernPageTransitions.slideRight(
        const Text('Test Page'),
      );

      expect(route, isA<PageRouteBuilder>());
      expect(route.transitionDuration, const Duration(milliseconds: 250));
    });

    testWidgets('scale creates PageRouteBuilder', (tester) async {
      final route = ModernPageTransitions.scale(
        const Text('Test Page'),
      );

      expect(route, isA<PageRouteBuilder>());
      expect(route.transitionDuration, const Duration(milliseconds: 200));
    });

    testWidgets('fade creates PageRouteBuilder', (tester) async {
      final route = ModernPageTransitions.fade(
        const Text('Test Page'),
      );

      expect(route, isA<PageRouteBuilder>());
      expect(route.transitionDuration, const Duration(milliseconds: 200));
    });

    testWidgets('slideUp transition works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.slideUp(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('New Page'), findsOneWidget);
    });

    testWidgets('slideRight transition works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.slideRight(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('New Page'), findsOneWidget);
    });

    testWidgets('scale transition works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.scale(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('New Page'), findsOneWidget);
    });

    testWidgets('fade transition works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.fade(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('New Page'), findsOneWidget);
    });

    testWidgets('slideUp uses SlideTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.slideUp(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('scale uses ScaleTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.scale(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('fade uses FadeTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  ModernPageTransitions.fade(
                    const Scaffold(body: Text('New Page')),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(FadeTransition), findsWidgets);
    });

    test('generic types work correctly', () {
      final stringRoute = ModernPageTransitions.slideUp<String>(
        const Text('Test'),
      );
      final intRoute = ModernPageTransitions.fade<int>(
        const Text('Test'),
      );

      expect(stringRoute, isA<PageRouteBuilder<String>>());
      expect(intRoute, isA<PageRouteBuilder<int>>());
    });
  });
}
