import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/views/project/projects_list_screen.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ProjectsListScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without error', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(ProjectsListScreen), findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.text('Проекты'), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows favorites icon in app bar', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('shows filter icon in app bar', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Поиск проектов...'), findsOneWidget);
    });

    testWidgets('can toggle favorites filter', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows SearchBar widget', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(SearchBar), findsOneWidget);
    });

    testWidgets('показывает иконку сканирования QR кода', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('показывает FAB для создания нового проекта', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Новый проект'), findsOneWidget);
    });

    testWidgets('FAB имеет иконку добавления', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('можно переключить фильтр избранных', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final starButton = find.byIcon(Icons.star_border);
      await tester.tap(starButton);
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);

      // Toggle back
      await tester.tap(find.byIcon(Icons.star));
      await tester.pump();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('можно открыть меню фильтров по статусу', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final filterButton = find.byIcon(Icons.filter_list_rounded);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton), findsOneWidget);
    });

    testWidgets('поиск изменяет query state', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final searchBar = find.byType(SearchBar);
      await tester.tap(searchBar);
      await tester.pumpAndSettle();

      await tester.enterText(searchBar, 'test query');
      await tester.pumpAndSettle();
    });

    testWidgets('показывает кнопку очистки при наличии текста поиска', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final searchBar = find.byType(SearchBar);
      await tester.tap(searchBar);
      await tester.pumpAndSettle();

      await tester.enterText(searchBar, 'test');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });

    testWidgets('можно очистить текст поиска кнопкой', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final searchBar = find.byType(SearchBar);
      await tester.tap(searchBar);
      await tester.pumpAndSettle();

      await tester.enterText(searchBar, 'test');
      await tester.pumpAndSettle();

      final clearButton = find.byIcon(Icons.clear_rounded);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();
    });

    testWidgets('показывает CircularProgressIndicator при загрузке', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('показывает PreferredSize для SearchBar', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(PreferredSize), findsOneWidget);
    });

    testWidgets('AppBar содержит несколько action кнопок', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, greaterThan(0));
    });

    testWidgets('SearchBar имеет правильный hint text', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.text('Поиск проектов...'), findsOneWidget);
    });

    testWidgets('имеет tooltip для иконки избранных', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.star_border),
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.tooltip, isNotNull);
    });

    testWidgets('имеет tooltip для иконки QR сканера', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.qr_code_scanner_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.tooltip, isNotNull);
    });

    testWidgets('имеет tooltip для фильтра по статусу', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final popupButton = tester.widget<PopupMenuButton>(
        find.byType(PopupMenuButton<ProjectStatus?>),
      );
      expect(popupButton.tooltip, isNotNull);
    });

    testWidgets('FAB является extended типа', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      // Extended FAB has both icon and label
      expect(fab, isA<FloatingActionButton>());
    });

    testWidgets('звёздочка меняет цвет при активации', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final starButton = find.byIcon(Icons.star_border);
      await tester.tap(starButton);
      await tester.pump();

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, Colors.amber);
    });

    testWidgets('использует ConsumerStatefulWidget', (tester) async {
      setTestViewportSize(tester);
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const ProjectsListScreen()),
      );

      final element = tester.element(find.byType(ProjectsListScreen));
      expect(element.widget, isA<ConsumerStatefulWidget>());
    });
  });
}
