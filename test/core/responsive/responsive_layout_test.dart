import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/responsive/responsive_layout.dart';

void main() {
  group('ResponsiveBreakpoints', () {
    testWidgets('identifies phone for narrow screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isPhone(context), isTrue);
                expect(ResponsiveBreakpoints.isTablet(context), isFalse);
                expect(ResponsiveBreakpoints.isDesktop(context), isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('identifies tablet for medium screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isPhone(context), isFalse);
                expect(ResponsiveBreakpoints.isTablet(context), isTrue);
                expect(ResponsiveBreakpoints.isDesktop(context), isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('identifies desktop for wide screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isPhone(context), isFalse);
                expect(ResponsiveBreakpoints.isTablet(context), isFalse);
                expect(ResponsiveBreakpoints.isDesktop(context), isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isTabletOrLarger works correctly', (tester) async {
      // Phone
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isTabletOrLarger(context), isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isTabletOrLarger(context), isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('shows phone layout on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              phone: Text('Phone'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);

      addTearDown(tester.view.reset);
    });

    testWidgets('shows tablet layout on medium screens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveLayout(
              phone: Text('Phone'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Phone'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows desktop layout on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              phone: Text('Phone'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Phone'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);

      addTearDown(tester.view.reset);
    });

    testWidgets('falls back to phone when tablet not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveLayout(
              phone: Text('Phone'),
            ),
          ),
        ),
      );

      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('falls back to tablet when desktop not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveLayout(
              phone: Text('Phone'),
              tablet: Text('Tablet'),
            ),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
    });
  });

  group('ResponsiveSizes', () {
    testWidgets('returns phone size for narrow screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final size = ResponsiveSizes.get(
                  context,
                  phone: 16,
                  tablet: 20,
                  desktop: 24,
                );
                expect(size, equals(16));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns tablet size for medium screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                final size = ResponsiveSizes.get(
                  context,
                  phone: 16,
                  tablet: 20,
                  desktop: 24,
                );
                expect(size, equals(20));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('returns scaled size when tablet not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                final size = ResponsiveSizes.get(
                  context,
                  phone: 16,
                );
                // tablet = phone * 1.2 = 19.2
                expect(size, closeTo(19.2, 0.1));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getGridColumns returns correct values', (tester) async {
      // Phone
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveSizes.getGridColumns(context), equals(2));
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveSizes.getGridColumns(context), equals(3));
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveSizes.getGridColumns(context), equals(4));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('ResponsiveContext extension', () {
    testWidgets('provides convenient context extensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(context.isPhone, isTrue);
                expect(context.screenWidth, equals(400));
                expect(context.screenHeight, equals(800));
                expect(context.deviceType, equals(DeviceType.phone));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('detects orientation correctly', (tester) async {
      // Portrait
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                expect(context.isPortrait, isTrue);
                expect(context.isLandscape, isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Landscape
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 400)),
            child: Builder(
              builder: (context) {
                expect(context.isPortrait, isFalse);
                expect(context.isLandscape, isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}
