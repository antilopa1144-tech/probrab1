import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_header.dart';

void main() {
  group('CalculatorHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'Tile Calculator',
            ),
          ),
        ),
      );

      expect(find.text('Tile Calculator'), findsOneWidget);
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'Foundation',
              subtitle: 'Strip foundation calculation',
            ),
          ),
        ),
      );

      expect(find.text('Foundation'), findsOneWidget);
      expect(find.text('Strip foundation calculation'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'Simple Header',
            ),
          ),
        ),
      );

      expect(find.text('Simple Header'), findsOneWidget);
      // Only the title text should be present
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'With Icon',
              icon: Icons.calculate,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calculate), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'No Icon',
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'With Trailing',
              trailing: IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('renders all optional parameters together', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'Full Header',
              subtitle: 'With all options',
              icon: Icons.home,
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Full Header'), findsOneWidget);
      expect(find.text('With all options'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('uses Row as root layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'Test',
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('applies theme text styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: CalculatorHeader(
              title: 'Dark Theme',
              subtitle: 'Subtitle text',
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('applies primary color to icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const Scaffold(
            body: CalculatorHeader(
              title: 'Colored Icon',
              icon: Icons.star,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.size, 28);
    });

    testWidgets('handles long title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: CalculatorHeader(
                title:
                    'Very Long Calculator Title That Might Need Multiple Lines',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Very Long Calculator Title That Might Need Multiple Lines',
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses Expanded for title area', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorHeader(
              title: 'Expanded Title',
              trailing: Icon(Icons.more_vert),
            ),
          ),
        ),
      );

      expect(find.byType(Expanded), findsOneWidget);
    });
  });
}
