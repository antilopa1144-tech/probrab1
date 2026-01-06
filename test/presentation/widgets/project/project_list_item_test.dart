import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/project/project_list_item.dart';

void main() {
  group('ProjectListItem', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(title: 'My Project'),
          ),
        ),
      );

      expect(find.text('My Project'), findsOneWidget);
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(
              title: 'House Renovation',
              subtitle: 'Started Jan 2024',
            ),
          ),
        ),
      );

      expect(find.text('House Renovation'), findsOneWidget);
      expect(find.text('Started Jan 2024'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(title: 'Simple Project'),
          ),
        ),
      );

      expect(find.text('Simple Project'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders status badge when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(
              title: 'Active Project',
              statusLabel: 'In Progress',
              statusColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Active Project'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectListItem(
              title: 'Tappable',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders leading widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(
              title: 'With Icon',
              leading: Icon(Icons.home),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('renders trailing widget instead of status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(
              title: 'With Trailing',
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('uses ListTile as base widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectListItem(title: 'Test'),
          ),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
