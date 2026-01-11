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
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('renders TabBar with three tabs', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('shows calculations tab with count', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Проверяем текст первой вкладки - "Расчёты (0)" для пустого проекта
      expect(find.text('Расчёты (0)'), findsOneWidget);
    });

    testWidgets('shows materials tab with count', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.text('Материалы (0)'), findsOneWidget);
    });

    testWidgets('shows checklists tab', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Вкладка чек-листов (в табе)
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('renders ProjectInfoCard in calculations tab', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectInfoCard), findsOneWidget);
    });

    testWidgets('shows add calculation button in calculations tab',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('calls onAddCalculation when add button is pressed',
        (tester) async {
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
      testProject.isFavorite = true;

      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is pressed', (tester) async {
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
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
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.edit_rounded),
      );
      expect(iconButton.tooltip, 'Редактировать');
    });

    testWidgets('favorite button has correct tooltip when not favorite',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star_border),
      );
      expect(iconButton.tooltip, 'Добавить в избранное');
    });

    testWidgets('favorite button has correct tooltip when favorite',
        (tester) async {
      setTestViewportSize(tester);
      testProject.isFavorite = true;

      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star),
      );
      expect(iconButton.tooltip, 'Убрать из избранного');
    });

    testWidgets('can switch to materials tab', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Нажимаем на вкладку "Материалы" (используем точный текст таба)
      await tester.tap(find.text('Материалы (0)'));
      await tester.pumpAndSettle();

      // После переключения вкладки, ProjectInfoCard не должен быть виден
      // (он только на вкладке расчётов), проверяем что TabBarView работает
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('вызывает onShareQR при выборе QR в меню', (tester) async {
      setTestViewportSize(tester);
      bool qrCalled = false;

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onShareQR: () => qrCalled = true,
      ));
      await tester.pumpAndSettle();

      final popupFinder = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Поделиться QR кодом'));
      await tester.pumpAndSettle();

      expect(qrCalled, isTrue);
    });

    testWidgets('отображает empty state когда нет расчётов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Проверяем наличие empty state
      expect(find.text('Нет расчётов'), findsOneWidget);
      expect(find.text('Добавьте первый расчёт'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_outlined), findsWidgets);
    });

    testWidgets('отображает расчёты когда они есть', (tester) async {
      setTestViewportSize(tester);
      final projectWithCalcs = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..description = 'Test description'
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20)
        ..isFavorite = false
        ..tags = ['tag1']
        ..status = ProjectStatus.planning
        ..notes = 'Notes';

      final calc = ProjectCalculation()
        ..id = 1
        ..calculatorId = 'test_calc'
        ..name = 'Test Calculator'
        ..inputs = []
        ..results = []
        ..materials = []
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 15);

      projectWithCalcs.calculations.add(calc);

      await tester.pumpWidget(buildTestWidget(project: projectWithCalcs));
      await tester.pumpAndSettle();

      // Проверяем что empty state не отображается
      expect(find.text('Нет расчётов'), findsNothing);
      // Проверяем что показывается счётчик расчётов
      expect(find.text('Расчёты (1)'), findsOneWidget);
    });

    testWidgets('вызывает onOpenCalculation при нажатии на расчёт', (tester) async {
      setTestViewportSize(tester);
      ProjectCalculation? openedCalc;

      final projectWithCalcs = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20);

      final calc = ProjectCalculation()
        ..id = 1
        ..calculatorId = 'test_calc'
        ..name = 'Test Calculator'
        ..inputs = []
        ..results = []
        ..materials = []
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 15);

      projectWithCalcs.calculations.add(calc);

      await tester.pumpWidget(buildTestWidget(
        project: projectWithCalcs,
        onOpenCalculation: (c) => openedCalc = c,
      ));
      await tester.pumpAndSettle();

      // Нажимаем на карточку расчёта (ищем по тексту названия)
      await tester.tap(find.text('Test Calculator'));
      await tester.pumpAndSettle();

      expect(openedCalc, isNotNull);
      expect(openedCalc?.id, equals(1));
    });

    testWidgets('передаёт правильный проект в дочерние виджеты', (tester) async {
      setTestViewportSize(tester);

      final projectWithCalcs = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20);

      final calc = ProjectCalculation()
        ..id = 1
        ..calculatorId = 'test_calc'
        ..name = 'Test Calculator'
        ..inputs = []
        ..results = []
        ..materials = []
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 15);

      projectWithCalcs.calculations.add(calc);

      await tester.pumpWidget(buildTestWidget(
        project: projectWithCalcs,
      ));
      await tester.pumpAndSettle();

      // Проверяем что проект передан в ProjectInfoCard
      expect(find.byType(ProjectInfoCard), findsOneWidget);
    });

    testWidgets('переключается на вкладку чек-листов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Нажимаем на вкладку чек-листов
      await tester.tap(find.text('Чек-листы'));
      await tester.pumpAndSettle();

      // Проверяем что TabBarView работает
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('отображает NestedScrollView с заголовком', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byType(NestedScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('SliverAppBar является закреплённым', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.pinned, isTrue);
      expect(appBar.floating, isTrue);
    });

    testWidgets('TabController имеет 3 вкладки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final tabs = tester.widgetList<Tab>(find.byType(Tab));
      expect(tabs.length, equals(3));
    });

    testWidgets('передаёт onRefresh в дочерние виджеты', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(buildTestWidget(
        project: testProject,
        onRefresh: () {},
      ));
      await tester.pumpAndSettle();

      // Переключаемся на вкладку материалов
      await tester.tap(find.text('Материалы (0)'));
      await tester.pumpAndSettle();

      // onRefresh должен быть передан в _MaterialsTab
      // Проверяем что вкладка материалов отображается
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('отображает количество расчётов в заголовке вкладки', (tester) async {
      setTestViewportSize(tester);
      final projectWithCalcs = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20);

      for (int i = 0; i < 5; i++) {
        final calc = ProjectCalculation()
          ..id = i
          ..calculatorId = 'test_calc_$i'
          ..name = 'Test Calculator $i'
          ..inputs = []
          ..results = []
          ..materials = []
          ..createdAt = DateTime(2024, 1, 15)
          ..updatedAt = DateTime(2024, 1, 15);
        projectWithCalcs.calculations.add(calc);
      }

      await tester.pumpWidget(buildTestWidget(project: projectWithCalcs));
      await tester.pumpAndSettle();

      expect(find.text('Расчёты (5)'), findsOneWidget);
    });

    testWidgets('отображает количество материалов в заголовке вкладки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Используем allMaterials для подсчёта
      expect(find.text('Материалы (${testProject.allMaterials.length})'), findsOneWidget);
    });

    testWidgets('цвет звезды жёлтый когда проект в избранном', (tester) async {
      setTestViewportSize(tester);
      testProject.isFavorite = true;

      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.star),
      );
      final icon = iconButton.icon as Icon;
      expect(icon.color, equals(Colors.amber));
    });

    testWidgets('отображает иконки в табах', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calculate_outlined), findsWidgets);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
      expect(find.byIcon(Icons.checklist_rounded), findsWidgets);
    });

    testWidgets('создаёт и освобождает TabController', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Виджет должен создать TabController
      expect(find.byType(TabBar), findsOneWidget);

      // Удаляем виджет
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // TabController должен быть корректно освобождён
    });

    testWidgets('кнопка редактирования имеет правильную иконку', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });

    testWidgets('PopupMenu отображается при нажатии', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final popupFinder = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );

      expect(popupFinder, findsOneWidget);

      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      // Меню должно отображаться с 3 пунктами
      expect(find.byType(PopupMenuItem), findsNWidgets(3));
    });

    testWidgets('все пункты PopupMenu имеют иконки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final popupFinder = find.byWidgetPredicate(
        (widget) => widget is PopupMenuButton,
      );
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.qr_code_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
    });

    testWidgets('название проекта отображается в SliverAppBar', (tester) async {
      setTestViewportSize(tester);
      final project = ProjectV2()
        ..id = 1
        ..name = 'Ремонт квартиры'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(buildTestWidget(project: project));
      await tester.pumpAndSettle();

      expect(find.text('Ремонт квартиры'), findsOneWidget);
    });

    testWidgets('действия доступны через SliverAppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, greaterThan(0));
    });

    testWidgets('TabBar находится внизу SliverAppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.bottom, isA<TabBar>());
    });

    testWidgets('SingleTickerProviderStateMixin используется для TabController', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // TabController должен работать правильно с анимациями
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller, isNotNull);
    });

    testWidgets('вкладка расчётов содержит ProjectInfoCard', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // По умолчанию открыта первая вкладка (расчёты)
      expect(find.byType(ProjectInfoCard), findsOneWidget);
    });

    testWidgets('вкладка расчётов содержит CustomScrollView', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // CustomScrollView используется внутри первой вкладки
      expect(find.byType(CustomScrollView), findsWidgets);
    });

    testWidgets('empty state для расчётов использует SliverFillRemaining', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(buildTestWidget(project: testProject));
      await tester.pumpAndSettle();

      // Когда нет расчётов, должен использоваться SliverFillRemaining
      expect(find.byType(SliverFillRemaining), findsWidgets);
    });
  });
}
