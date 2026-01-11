import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_details_content.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_info_card.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('ProjectDetailsContent', () {
    late ProjectV2 testProject;

    setUp(() {
      setupMocks();
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

    Widget buildTestWidget({
      required ProjectV2 project,
      VoidCallback? onToggleFavorite,
      VoidCallback? onEdit,
      VoidCallback? onAddCalculation,
      VoidCallback? onExport,
      VoidCallback? onShareQR,
      VoidCallback? onChangeStatus,
      void Function(ProjectCalculation)? onOpenCalculation,
      void Function(ProjectCalculation)? onDeleteCalculation,
      VoidCallback? onRefresh,
    }) {
      return createTestApp(
        child: Scaffold(
          body: ProjectDetailsContent(
            project: project,
            onToggleFavorite: onToggleFavorite ?? () {},
            onEdit: onEdit ?? () {},
            onAddCalculation: onAddCalculation ?? () {},
            onExport: onExport ?? () {},
            onShareQR: onShareQR ?? () {},
            onChangeStatus: onChangeStatus ?? () {},
            onOpenCalculation: onOpenCalculation ?? (_) {},
            onDeleteCalculation: onDeleteCalculation ?? (_) {},
            onRefresh: onRefresh ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders project name in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('renders TabBar with three tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('shows calculations tab with count', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Проверяем текст первой вкладки - "Расчёты (0)" для пустого проекта
      expect(find.text('Расчёты (0)'), findsOneWidget);
    });

    testWidgets('shows materials tab with count', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.text('Материалы (0)'), findsOneWidget);
    });

    testWidgets('shows checklists tab', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Вкладка чек-листов (в табе)
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('renders ProjectInfoCard in calculations tab', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectInfoCard), findsOneWidget);
    });

    testWidgets('shows add calculation button in calculations tab',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('calls onAddCalculation when add button is pressed',
        (tester) async {
      bool addCalled = false;

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onAddCalculation: () => addCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Добавить').first);
      await tester.pumpAndSettle();

      expect(addCalled, isTrue);
    });

    testWidgets('calls onToggleFavorite when star is pressed', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onToggleFavorite: () => toggled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });

    testWidgets('shows filled star when project is favorite', (tester) async {
      testProject.isFavorite = true;

      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is pressed', (tester) async {
      bool editCalled = false;

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onEdit: () => editCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('shows popup menu with export, qr and status options',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Ищем PopupMenuButton без generic типа
      final popupFinder = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      expect(find.text('Экспортировать'), findsOneWidget);
      expect(find.text('Изменить статус'), findsOneWidget);
      expect(find.text('Поделиться QR кодом'), findsOneWidget);
    });

    testWidgets('calls onExport when export menu item is selected',
        (tester) async {
      bool exportCalled = false;

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onExport: () => exportCalled = true,
      ));
      await tester.pumpAndSettle();

      final popupFinder = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспортировать'));
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
    });

    testWidgets('calls onChangeStatus when status menu item is selected',
        (tester) async {
      bool statusCalled = false;

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onChangeStatus: () => statusCalled = true,
      ));
      await tester.pumpAndSettle();

      final popupFinder = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Изменить статус'));
      await tester.pumpAndSettle();

      expect(statusCalled, isTrue);
    });

    testWidgets('has edit button with correct tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.edit_rounded),
      );
      expect(iconButton.tooltip, 'Редактировать');
    });

    testWidgets('favorite button has correct tooltip when not favorite',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star_border),
      );
      expect(iconButton.tooltip, 'Добавить в избранное');
    });

    testWidgets('favorite button has correct tooltip when favorite',
        (tester) async {
      testProject.isFavorite = true;

      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star),
      );
      expect(iconButton.tooltip, 'Убрать из избранного');
    });

    testWidgets('can switch to materials tab', (tester) async {
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Нажимаем на вкладку "Материалы" (используем точный текст таба)
      await tester.tap(find.text('Материалы (0)'));
      await tester.pumpAndSettle();

      // После переключения вкладки, ProjectInfoCard не должен быть виден
      // (он только на вкладке расчётов), проверяем что TabBarView работает
      expect(find.byType(TabBarView), findsOneWidget);
    });
  });
}
