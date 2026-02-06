import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/theme.dart';

void main() {
  group('AppTheme', () {
    const testAccent = Colors.blue;
    const testAccentOrange = Colors.orange;

    group('darkTheme', () {
      late ThemeData darkTheme;

      setUp(() {
        darkTheme = AppTheme.darkTheme(testAccent);
      });

      test('creates theme with dark brightness', () {
        expect(darkTheme.brightness, Brightness.dark);
      });

      test('uses Material 3', () {
        expect(darkTheme.useMaterial3, true);
      });

      test('has correct scaffold background color', () {
        expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF1E1A18));
      });

      test('color scheme uses accent as primary', () {
        expect(darkTheme.colorScheme.primary, testAccent);
      });

      test('color scheme has dark surface', () {
        expect(darkTheme.colorScheme.surface, const Color(0xFF1E1A18));
      });

      test('AppBar theme has transparent surface tint', () {
        expect(darkTheme.appBarTheme.surfaceTintColor, Colors.transparent);
      });

      test('AppBar theme has no elevation', () {
        expect(darkTheme.appBarTheme.elevation, 0);
        expect(darkTheme.appBarTheme.scrolledUnderElevation, 0);
      });

      test('card theme has no elevation', () {
        expect(darkTheme.cardTheme.elevation, 0);
      });

      test('card has rounded shape', () {
        final shape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(24));
      });

      test('input decoration has rounded borders', () {
        final border = darkTheme.inputDecorationTheme.border as OutlineInputBorder;
        expect(border.borderRadius, BorderRadius.circular(20));
      });

      test('elevated button has no elevation', () {
        final style = darkTheme.elevatedButtonTheme.style;
        expect(style?.elevation?.resolve({}), 0);
      });

      test('FAB uses accent color', () {
        expect(darkTheme.floatingActionButtonTheme.backgroundColor, testAccent);
      });

      test('FAB has rounded shape', () {
        final shape = darkTheme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      });

      test('dialog has rounded shape', () {
        final shape = darkTheme.dialogTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(24));
      });

      test('bottom sheet has rounded top corners', () {
        final shape = darkTheme.bottomSheetTheme.shape as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(24)),
        );
      });

      test('snackbar has floating behavior', () {
        expect(darkTheme.snackBarTheme.behavior, SnackBarBehavior.floating);
      });
    });

    group('lightTheme', () {
      late ThemeData lightTheme;

      setUp(() {
        lightTheme = AppTheme.lightTheme(testAccent);
      });

      test('creates theme with light brightness', () {
        expect(lightTheme.brightness, Brightness.light);
      });

      test('uses Material 3', () {
        expect(lightTheme.useMaterial3, true);
      });

      test('has correct scaffold background color', () {
        expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFFAFAFA));
      });

      test('color scheme uses accent as primary', () {
        expect(lightTheme.colorScheme.primary, testAccent);
      });

      test('color scheme has white surface', () {
        expect(lightTheme.colorScheme.surface, Colors.white);
      });

      test('AppBar theme has transparent surface tint', () {
        expect(lightTheme.appBarTheme.surfaceTintColor, Colors.transparent);
      });

      test('FAB uses accent color', () {
        expect(lightTheme.floatingActionButtonTheme.backgroundColor, testAccent);
      });

      test('FAB foreground is white for light theme', () {
        expect(lightTheme.floatingActionButtonTheme.foregroundColor, Colors.white);
      });
    });

    group('different accent colors', () {
      test('darkTheme adapts to different accent colors', () {
        final orangeTheme = AppTheme.darkTheme(testAccentOrange);
        expect(orangeTheme.colorScheme.primary, testAccentOrange);
        expect(orangeTheme.floatingActionButtonTheme.backgroundColor, testAccentOrange);
      });

      test('lightTheme adapts to different accent colors', () {
        final orangeTheme = AppTheme.lightTheme(testAccentOrange);
        expect(orangeTheme.colorScheme.primary, testAccentOrange);
        expect(orangeTheme.floatingActionButtonTheme.backgroundColor, testAccentOrange);
      });
    });

    group('typography', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.darkTheme(testAccent);
      });

      test('displayLarge has correct properties', () {
        expect(theme.textTheme.displayLarge?.fontSize, 57);
        expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w400);
      });

      test('headlineLarge has correct properties', () {
        expect(theme.textTheme.headlineLarge?.fontSize, 32);
        expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w600);
      });

      test('titleLarge has correct properties', () {
        expect(theme.textTheme.titleLarge?.fontSize, 22);
        expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
      });

      test('bodyLarge has correct properties', () {
        expect(theme.textTheme.bodyLarge?.fontSize, 16);
        expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
      });

      test('labelLarge has correct properties', () {
        expect(theme.textTheme.labelLarge?.fontSize, 14);
        expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w600);
      });
    });

    group('button themes', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.darkTheme(testAccent);
      });

      test('filled button has correct minimum size', () {
        final style = theme.filledButtonTheme.style;
        expect(style?.minimumSize?.resolve({}), const Size(0, 56));
      });

      test('outlined button has correct minimum size', () {
        final style = theme.outlinedButtonTheme.style;
        expect(style?.minimumSize?.resolve({}), const Size(0, 56));
      });

      test('text button has correct minimum size', () {
        final style = theme.textButtonTheme.style;
        expect(style?.minimumSize?.resolve({}), const Size(0, 48));
      });

      test('elevated button has pill shape', () {
        final style = theme.elevatedButtonTheme.style;
        final shape = style?.shape?.resolve({}) as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(100));
      });
    });

    group('chip theme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.darkTheme(testAccent);
      });

      test('chip has correct padding', () {
        expect(
          theme.chipTheme.padding,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      });

      test('chip has correct shape', () {
        final shape = theme.chipTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(8));
      });
    });

    group('list tile theme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.darkTheme(testAccent);
      });

      test('list tile has correct content padding', () {
        expect(
          theme.listTileTheme.contentPadding,
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        );
      });

      test('list tile has rounded shape', () {
        final shape = theme.listTileTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(12));
      });
    });

    group('divider theme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.darkTheme(testAccent);
      });

      test('divider has correct thickness', () {
        expect(theme.dividerTheme.thickness, 1);
      });

      test('divider has correct space', () {
        expect(theme.dividerTheme.space, 1);
      });
    });

    group('widget integration', () {
      testWidgets('dark theme renders correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(testAccent),
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const Center(child: Text('Dark Theme')),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Dark Theme'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('light theme renders correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme(testAccent),
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const Center(child: Text('Light Theme')),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Light Theme'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('buttons render with correct style', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(testAccent),
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                  TextButton(onPressed: () {}, child: const Text('Text')),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Elevated'), findsOneWidget);
        expect(find.text('Filled'), findsOneWidget);
        expect(find.text('Outlined'), findsOneWidget);
        expect(find.text('Text'), findsOneWidget);
      });

      testWidgets('input field renders with correct style', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(testAccent),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(labelText: 'Test Input'),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Test Input'), findsOneWidget);
      });

      testWidgets('card renders with correct style', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(testAccent),
            home: const Scaffold(
              body: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Card Content'),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Card Content'), findsOneWidget);
      });

      testWidgets('chip renders with correct style', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(testAccent),
            home: const Scaffold(
              body: Chip(label: Text('Test Chip')),
            ),
          ),
        );

        expect(find.byType(Chip), findsOneWidget);
        expect(find.text('Test Chip'), findsOneWidget);
      });
    });
  });
}
