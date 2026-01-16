import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';
import 'package:probrab_ai/presentation/views/checklist/checklist_details_screen.dart';
import 'package:probrab_ai/presentation/providers/checklist_provider.dart';

import '../../../helpers/test_helpers.dart';

/// Создает ProviderScope для тестирования ChecklistDetailsScreen
/// с синхронными mock-провайдерами для надежных тестов.
///
/// Ключевой момент: используем Stream.value() для синхронного ответа,
/// избегая проблем с Isar watch() + asyncMap() в тестовом окружении.
ProviderScope createChecklistTestScope({
  required int checklistId,
  required RenovationChecklist? checklist,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      // Переопределяем только checklistProvider с синхронным Stream.value()
      checklistProvider(checklistId).overrideWith((ref) => Stream.value(checklist)),
    ],
    child: child,
  );
}

/// Создаёт тестовый чек-лист в памяти из шаблона (без записи в БД)
RenovationChecklist createTestChecklistFromTemplate(
  ChecklistTemplate template, {
  int id = 1,
}) {
  final checklist = template.toChecklist()..id = id;
  final items = template.createItems();
  // Эмулируем loaded items через IsarLinks (они будут в памяти)
  for (final item in items) {
    checklist.items.add(item);
  }
  return checklist;
}

/// Создаёт пустой тестовый чек-лист в памяти
RenovationChecklist createEmptyTestChecklist({
  int id = 1,
  String name = 'Пустой чек-лист',
}) {
  return RenovationChecklist()
    ..id = id
    ..name = name
    ..category = ChecklistCategory.general
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();
}

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ChecklistDetailsScreen - базовое отображение', () {
    testWidgets('показывает ошибку для несуществующего ID', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 1,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);
    });

    testWidgets('содержит AppBar с заголовком', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 1,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: 1),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Чек-лист'), findsOneWidget);
    });

    testWidgets('checklistId передаётся в widget', (tester) async {
      setTestViewportSize(tester);
      const testId = 42;

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: testId,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: testId),
          ),
        ),
      );

      final widget = tester.widget<ChecklistDetailsScreen>(
        find.byType(ChecklistDetailsScreen),
      );
      expect(widget.checklistId, testId);
    });

    testWidgets('имеет Scaffold', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 1,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: 1),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('ошибка отображается в Center', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 1,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Center), findsWidgets);
    });
  });

  group('ChecklistDetailsScreen - отображение ошибок', () {
    testWidgets('показывает ошибку при несуществующем ID', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 99999,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: 99999),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);
    });

    testWidgets('показывает кнопку Назад в состоянии ошибки', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 99999,
          checklist: null,
          child: const MaterialApp(
            home: ChecklistDetailsScreen(checklistId: 99999),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Назад'), findsOneWidget);
    });

    testWidgets('кнопка Назад закрывает экран при ошибке', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: 99999,
          checklist: null,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChecklistDetailsScreen(
                          checklistId: 99999,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);

      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsNothing);
    });
  });

  group('ChecklistDetailsScreen - успешная загрузка', () {
    testWidgets('показывает название чек-листа после загрузки', (tester) async {
      setTestViewportSize(tester);

      final checklist = createTestChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(checklist.name), findsOneWidget);
    });

    testWidgets('показывает прогресс-карту', (tester) async {
      setTestViewportSize(tester);

      final checklist = createTestChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Прогресс'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('показывает счётчик выполненных задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = createTestChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('0 из ${checklist.items.length}'),
        findsOneWidget,
      );
    });

    testWidgets('показывает процент выполнения', (tester) async {
      setTestViewportSize(tester);

      final checklist = createTestChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('показывает FAB для добавления задачи', (tester) async {
      setTestViewportSize(tester);

      final checklist = createTestChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Добавить задачу'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsWidgets);
    });

    testWidgets('показывает меню с действиями', (tester) async {
      setTestViewportSize(tester);

      // Используем пустой чек-лист т.к. IsarLinks не работает без БД
      final checklist = createEmptyTestChecklist(name: 'Тест меню');

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - пустой чек-лист', () {
    testWidgets('показывает пустое состояние без задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = createEmptyTestChecklist();

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Список задач пуст'), findsOneWidget);
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
      expect(
        find.text('Добавьте первую задачу, чтобы начать отслеживать прогресс вашего ремонта'),
        findsOneWidget,
      );
    });

    testWidgets('прогресс 0% для пустого чек-листа', (tester) async {
      setTestViewportSize(tester);

      final checklist = createEmptyTestChecklist();

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 из 0'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });

  // Примечание: Тесты взаимодействия с задачами (CheckboxListTile, Dismissible)
  // требуют интеграционного тестирования с реальной БД Isar, т.к. IsarLinks
  // не поддерживают добавление элементов в памяти без сохранения в БД.
  // Эти тесты перенесены в интеграционные тесты.

  group('ChecklistDetailsScreen - структура UI', () {
    testWidgets('экран содержит Card для прогресса', (tester) async {
      setTestViewportSize(tester);

      final checklist = createEmptyTestChecklist(name: 'Тест структуры');

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Должна быть хотя бы одна Card (для прогресса)
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('AppBar содержит кнопку редактирования', (tester) async {
      setTestViewportSize(tester);

      final checklist = createEmptyTestChecklist(name: 'Тест кнопок');

      await tester.pumpWidget(
        createChecklistTestScope(
          checklistId: checklist.id,
          checklist: checklist,
          child: MaterialApp(
            home: ChecklistDetailsScreen(checklistId: checklist.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });
  });
}
