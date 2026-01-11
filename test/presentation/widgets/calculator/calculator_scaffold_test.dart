import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_scaffold.dart';

void main() {
  group('CalculatorScaffold', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Test Calculator',
            accentColor: Colors.blue,
            children: [
              Text('Content'),
            ],
          ),
        ),
      );

      expect(find.text('Test Calculator'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('has AppBar with accent color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.green,
            children: [],
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.green);
    });

    testWidgets('shows back button by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            children: [],
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, true);
    });

    testWidgets('hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            showBackButton: false,
            children: [],
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, false);
    });

    testWidgets('renders with result header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            resultHeader: Container(
              key: const Key('header'),
              color: Colors.red,
              height: 50,
            ),
            children: const [],
          ),
        ),
      );

      expect(find.byKey(const Key('header')), findsOneWidget);
    });

    testWidgets('renders children in scrollable area', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            children: [
              Text('Item 1'),
              Text('Item 2'),
              Text('Item 3'),
            ],
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders actions in AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {},
              ),
            ],
            children: const [],
          ),
        ),
      );

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('renders floating action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            children: const [],
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            bottomNavigationBar: BottomAppBar(
              child: Text('Bottom'),
            ),
            children: [],
          ),
        ),
      );

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
    });

    testWidgets('accepts custom body padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffold(
            title: 'Title',
            accentColor: Colors.blue,
            bodyPadding: EdgeInsets.all(32),
            children: [
              Text('Content'),
            ],
          ),
        ),
      );

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });
  });

  group('CalculatorScaffoldSimple', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffoldSimple(
            title: 'Simple Calculator',
            accentColor: Colors.orange,
            children: [
              Text('Simple Content'),
            ],
          ),
        ),
      );

      expect(find.text('Simple Calculator'), findsOneWidget);
      expect(find.text('Simple Content'), findsOneWidget);
    });

    testWidgets('renders actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorScaffoldSimple(
            title: 'Title',
            accentColor: Colors.purple,
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {},
              ),
            ],
            children: const [],
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('accepts custom body padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalculatorScaffoldSimple(
            title: 'Title',
            accentColor: Colors.teal,
            bodyPadding: EdgeInsets.symmetric(horizontal: 24),
            children: [
              Text('Content'),
            ],
          ),
        ),
      );

      expect(find.byType(CalculatorScaffoldSimple), findsOneWidget);
    });
  });
}
