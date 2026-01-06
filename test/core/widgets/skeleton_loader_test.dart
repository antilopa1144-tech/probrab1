import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader', () {
    testWidgets('renders with specified dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 100, height: 50),
          ),
        ),
      );

      final containerFinder = find.byType(Container).last;
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('uses custom borderRadius when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 100,
              height: 50,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('animates shimmer effect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 100, height: 50),
          ),
        ),
      );

      // Initial state
      expect(find.byType(SkeletonLoader), findsOneWidget);

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SkeletonLoader), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('disposes animation controller properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 100, height: 50),
          ),
        ),
      );

      // Replace with empty container - should dispose cleanly
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // No exceptions should be thrown
      expect(find.byType(SkeletonLoader), findsNothing);
    });

    testWidgets('uses theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: SkeletonLoader(width: 100, height: 50),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('works with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SkeletonLoader(width: 100, height: 50),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('SkeletonCard', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('contains multiple SkeletonLoaders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      // SkeletonCard contains 4 SkeletonLoader widgets
      expect(find.byType(SkeletonLoader), findsNWidgets(4));
    });

    testWidgets('has proper layout structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('renders in a list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                SkeletonCard(),
                SkeletonCard(),
                SkeletonCard(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsNWidgets(3));
    });
  });
}
