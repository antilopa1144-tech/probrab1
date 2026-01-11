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

  group('ResponsiveGrid', () {
    testWidgets('создаёт сетку с правильным количеством колонок для телефона', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: ResponsiveGrid(
                children: [
                  Text('1'),
                  Text('2'),
                  Text('3'),
                  Text('4'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('создаёт сетку с правильным количеством колонок для планшета', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: Scaffold(
              body: ResponsiveGrid(
                children: [
                  Text('1'),
                  Text('2'),
                  Text('3'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('создаёт сетку с правильным количеством колонок для десктопа', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: Scaffold(
              body: ResponsiveGrid(
                children: [
                  Text('1'),
                  Text('2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('применяет пользовательские отступы', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: ResponsiveGrid(
                spacing: 24,
                runSpacing: 32,
                children: [
                  Text('1'),
                  Text('2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('обрабатывает пустой список children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: ResponsiveGrid(
                children: [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('ResponsivePadding', () {
    testWidgets('применяет padding для телефона', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsivePadding(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('применяет padding для планшета', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsivePadding(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('применяет padding для десктопа', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsivePadding(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('использует пользовательский padding для телефона', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsivePadding(
              phonePadding: EdgeInsets.all(8),
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(8)));
    });

    testWidgets('использует пользовательский padding для планшета', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsivePadding(
              tabletPadding: EdgeInsets.all(12),
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(12)));
    });

    testWidgets('использует пользовательский padding для десктопа', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsivePadding(
              desktopPadding: EdgeInsets.all(16),
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.all(16)));
    });
  });

  group('ResponsiveConstrainedBox', () {
    testWidgets('ограничивает ширину для телефона', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveConstrainedBox(
              phoneMaxWidth: 350,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(ConstrainedBox), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('ограничивает ширину для планшета', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveConstrainedBox(
              tabletMaxWidth: 600,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(ConstrainedBox), findsOneWidget);
      final constrainedBox = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox));
      expect(constrainedBox.constraints.maxWidth, equals(600));
    });

    testWidgets('ограничивает ширину для десктопа', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveConstrainedBox(
              desktopMaxWidth: 800,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(ConstrainedBox), findsOneWidget);
      final constrainedBox = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox));
      expect(constrainedBox.constraints.maxWidth, equals(800));
    });

    testWidgets('использует значения по умолчанию', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveConstrainedBox(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(ConstrainedBox), findsOneWidget);
      final constrainedBox = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox));
      expect(constrainedBox.constraints.maxWidth, equals(700));
    });

    testWidgets('центрирует контент', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveConstrainedBox(
              desktopMaxWidth: 800,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });
  });

  group('ResponsiveText', () {
    testWidgets('отображает текст с размером для телефона', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveText(
              'Hello',
              phoneSize: 14,
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.fontSize, equals(14));
    });

    testWidgets('отображает текст с размером для планшета', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveText(
              'Hello',
              phoneSize: 14,
              tabletSize: 16,
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.fontSize, equals(16));
    });

    testWidgets('отображает текст с размером для десктопа', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveText(
              'Hello',
              phoneSize: 14,
              desktopSize: 18,
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.fontSize, equals(18));
    });

    testWidgets('автоматически масштабирует размер для планшета', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveText(
              'Hello',
              phoneSize: 10,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hello'));
      // Должно быть phoneSize * 1.1 = 11
      expect(text.style?.fontSize, equals(11));
    });

    testWidgets('автоматически масштабирует размер для десктопа', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveText(
              'Hello',
              phoneSize: 10,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hello'));
      // Должно быть phoneSize * 1.2 = 12
      expect(text.style?.fontSize, equals(12));
    });

    testWidgets('применяет пользовательский стиль', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveText(
              'Hello',
              style: TextStyle(fontWeight: FontWeight.bold),
              phoneSize: 14,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('применяет textAlign', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveText(
              'Hello',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.textAlign, equals(TextAlign.center));
    });

    testWidgets('применяет maxLines и overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveText(
              'Hello',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.maxLines, equals(2));
      expect(text.overflow, equals(TextOverflow.ellipsis));
    });
  });

  group('ResponsiveSizes utility methods', () {
    testWidgets('getIconSize возвращает правильные размеры', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final iconSize = ResponsiveSizes.getIconSize(context);
                expect(iconSize, equals(24));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getTitleSize возвращает правильные размеры', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                final titleSize = ResponsiveSizes.getTitleSize(context);
                expect(titleSize, equals(24));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getBorderRadius возвращает правильные размеры', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: Builder(
              builder: (context) {
                final borderRadius = ResponsiveSizes.getBorderRadius(context);
                expect(borderRadius, equals(24));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('get возвращает правильный размер для десктопа без явного значения', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: Builder(
              builder: (context) {
                final size = ResponsiveSizes.get(
                  context,
                  phone: 10,
                );
                // Должно быть phone * 1.4 = 14
                expect(size, equals(14));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('ResponsiveBreakpoints edge cases', () {
    testWidgets('обрабатывает граничные значения для телефона', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(599, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isPhone(context), isTrue);
                expect(ResponsiveBreakpoints.getDeviceType(context), equals(DeviceType.phone));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('обрабатывает граничные значения для планшета', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(600, 1000)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isTablet(context), isTrue);
                expect(ResponsiveBreakpoints.getDeviceType(context), equals(DeviceType.tablet));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('обрабатывает граничные значения для десктопа', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(900, 800)),
            child: Builder(
              builder: (context) {
                expect(ResponsiveBreakpoints.isDesktop(context), isTrue);
                expect(ResponsiveBreakpoints.getDeviceType(context), equals(DeviceType.desktop));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}
