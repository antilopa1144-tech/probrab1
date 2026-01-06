import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/widgets/glassmorphism_container.dart';

void main() {
  group('GlassmorphismContainer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('wraps child in ClipRRect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('contains BackdropFilter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('uses default blur value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('accepts custom blur value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              blur: 20.0,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('accepts custom opacity value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              opacity: 0.5,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('accepts custom borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              borderRadius: BorderRadius.circular(12),
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('accepts custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              color: Colors.blue,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('accepts custom border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              border: Border.all(color: Colors.red, width: 2),
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('works with complex child widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              child: Column(
                children: [
                  Text('Title'),
                  SizedBox(height: 8),
                  Text('Subtitle'),
                  SizedBox(height: 16),
                  Icon(Icons.star),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('works with light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: GlassmorphismContainer(
              child: Text('Light Theme'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('works with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: GlassmorphismContainer(
              child: Text('Dark Theme'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsOneWidget);
    });

    testWidgets('can be nested', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismContainer(
              child: GlassmorphismContainer(
                blur: 5,
                opacity: 0.3,
                child: Text('Nested'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsNWidgets(2));
      expect(find.text('Nested'), findsOneWidget);
    });

    testWidgets('renders in a list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  GlassmorphismContainer(child: Text('Item 1')),
                  SizedBox(height: 8),
                  GlassmorphismContainer(child: Text('Item 2')),
                  SizedBox(height: 8),
                  GlassmorphismContainer(child: Text('Item 3')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassmorphismContainer), findsNWidgets(3));
    });
  });
}
