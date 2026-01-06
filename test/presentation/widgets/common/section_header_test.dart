import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/section_header.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Section Title'),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Title',
              subtitle: 'Subtitle text',
            ),
          ),
        ),
      );

      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('hides subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Only Title'),
          ),
        ),
      );

      expect(find.text('Only Title'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'With Trailing',
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('trailing button is tappable', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Title',
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      expect(tapped, isTrue);
    });

    testWidgets('hides trailing when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'No Trailing'),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders with all properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Complete Section',
              subtitle: 'With all properties',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Complete Section'), findsOneWidget);
      expect(find.text('With all properties'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
    });

    testWidgets('uses Row layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Row Layout'),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('title is expanded to fill available space', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Expanded Title',
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('title and subtitle are in Column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders with TextButton trailing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Projects',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });
  });
}
