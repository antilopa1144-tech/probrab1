import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/existing/draggable_project_list.dart';

void main() {
  group('ProjectItem', () {
    test('creates with required parameters', () {
      final item = ProjectItem(
        id: '1',
        name: 'Project 1',
        description: 'Description 1',
      );

      expect(item.id, '1');
      expect(item.name, 'Project 1');
      expect(item.description, 'Description 1');
    });

    test('equality is based on id', () {
      final item1 = ProjectItem(
        id: '1',
        name: 'Project 1',
        description: 'Description 1',
      );
      final item2 = ProjectItem(
        id: '1',
        name: 'Different Name',
        description: 'Different Description',
      );
      final item3 = ProjectItem(
        id: '2',
        name: 'Project 1',
        description: 'Description 1',
      );

      expect(item1 == item2, isTrue);
      expect(item1 == item3, isFalse);
    });

    test('hashCode is based on id', () {
      final item1 = ProjectItem(
        id: '1',
        name: 'Project 1',
        description: 'Description 1',
      );
      final item2 = ProjectItem(
        id: '1',
        name: 'Different Name',
        description: 'Different Description',
      );

      expect(item1.hashCode, item2.hashCode);
    });
  });

  group('DraggableProjectList', () {
    testWidgets('renders list of items', (tester) async {
      final items = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
        ProjectItem(id: '2', name: 'Project 2', description: 'Desc 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Project 1'), findsOneWidget);
      expect(find.text('Project 2'), findsOneWidget);
      expect(find.text('Desc 1'), findsOneWidget);
      expect(find.text('Desc 2'), findsOneWidget);
    });

    testWidgets('renders empty list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: const [],
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('uses ReorderableListView', (tester) async {
      final items = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('shows drag handle icon', (tester) async {
      final items = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('shows chevron right icon', (tester) async {
      final items = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('uses Card for each item', (tester) async {
      final items = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
        ProjectItem(id: '2', name: 'Project 2', description: 'Desc 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('uses ListTile for each item', (tester) async {
      final items = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('updates when items change', (tester) async {
      final items1 = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
      ];
      final items2 = [
        ProjectItem(id: '1', name: 'Project 1', description: 'Desc 1'),
        ProjectItem(id: '2', name: 'Project 2', description: 'Desc 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items1,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Project 1'), findsOneWidget);
      expect(find.text('Project 2'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableProjectList(
              items: items2,
              onReorder: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Project 1'), findsOneWidget);
      expect(find.text('Project 2'), findsOneWidget);
    });
  });
}
