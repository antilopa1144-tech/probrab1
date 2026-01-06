import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_details_content.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_info_card.dart';

void main() {
  group('ProjectDetailsContent', () {
    late ProjectV2 testProject;

    setUp(() {
      testProject = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..description = 'Test description'
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20)
        ..isFavorite = false
        ..tags = ['tag1', 'tag2']
        ..status = ProjectStatus.planning
        ..notes = 'Some notes';
    });

    testWidgets('renders project name in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('renders ProjectInfoCard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ProjectInfoCard), findsOneWidget);
    });

    testWidgets('shows empty state when no calculations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Нет расчётов'), findsOneWidget);
      expect(find.text('Добавьте первый расчёт'), findsOneWidget);
    });

    testWidgets('shows "Расчёты" section header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Расчёты'), findsOneWidget);
    });

    testWidgets('shows add calculation button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('calls onAddCalculation when add button is pressed',
        (tester) async {
      bool addCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () => addCalled = true,
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();

      expect(addCalled, isTrue);
    });

    testWidgets('calls onToggleFavorite when star is pressed', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () => toggled = true,
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });

    testWidgets('shows filled star when project is favorite', (tester) async {
      testProject.isFavorite = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is pressed', (tester) async {
      bool editCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () => editCalled = true,
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('shows popup menu with export and status options',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Экспортировать'), findsOneWidget);
      expect(find.text('Изменить статус'), findsOneWidget);
    });

    testWidgets('calls onExport when export menu item is selected',
        (tester) async {
      bool exportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () => exportCalled = true,
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспортировать'));
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
    });

    testWidgets('calls onChangeStatus when status menu item is selected',
        (tester) async {
      bool statusCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () => statusCalled = true,
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Изменить статус'));
      await tester.pumpAndSettle();

      expect(statusCalled, isTrue);
    });

    // Note: Testing calculations list requires Isar database setup
    // which is complex for unit tests. The CalculationItemCard is tested
    // separately in calculation_item_card_test.dart.
    // Here we just verify the widget accepts the project without error.
    testWidgets('widget renders without error when project has no calculations',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      // Empty state is shown
      expect(find.text('Нет расчётов'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
    });

    testWidgets('has edit button with correct tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.edit_rounded),
      );
      expect(iconButton.tooltip, 'Редактировать');
    });

    testWidgets('favorite button has correct tooltip when not favorite',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star_border),
      );
      expect(iconButton.tooltip, 'Добавить в избранное');
    });

    testWidgets('favorite button has correct tooltip when favorite',
        (tester) async {
      testProject.isFavorite = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectDetailsContent(
              project: testProject,
              onToggleFavorite: () {},
              onEdit: () {},
              onAddCalculation: () {},
              onExport: () {},
              onChangeStatus: () {},
              onOpenCalculation: (_) {},
              onDeleteCalculation: (_) {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star),
      );
      expect(iconButton.tooltip, 'Убрать из избранного');
    });
  });
}
