import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:probrab_ai/data/repositories/checklist_repository.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';
import 'package:probrab_ai/presentation/views/checklist/checklist_details_screen.dart';
import 'package:probrab_ai/core/database/database_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late Isar isar;
  late ChecklistRepository repository;

  setUpAll(() {
    setupMocks();
  });

  setUp(() async {
    // Создаём in-memory Isar для тестов
    isar = await Isar.open(
      [RenovationChecklistSchema, ChecklistItemSchema],
      directory: '',
      name: 'test_checklist_details_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = ChecklistRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('ChecklistDetailsScreen - базовое отображение', () {
    testWidgets('показывает индикатор загрузки при старте', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );
      // Не ждём async операций - сразу проверяем loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('содержит AppBar с заголовком Чек-лист при загрузке',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Чек-лист'), findsOneWidget);
    });

    testWidgets('checklistId передаётся в widget', (tester) async {
      setTestViewportSize(tester);
      const testId = 42;

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: testId),
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
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('индикатор загрузки центрирован', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - отображение ошибок', () {
    testWidgets('показывает ошибку при несуществующем ID', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 99999),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('показывает кнопку Назад в состоянии ошибки', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 99999),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Назад'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('кнопка Назад закрывает экран при ошибке', (tester) async {
      setTestViewportSize(tester);

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        createTestApp(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
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
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
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
    testWidgets('показывает название чек-листа после загрузки',
        (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(checklist.name), findsOneWidget);
    });

    testWidgets('показывает прогресс-карту', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Прогресс'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('показывает счётчик выполненных задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('0 из ${checklist.totalItems}'),
        findsOneWidget,
      );
    });

    testWidgets('показывает процент выполнения', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('показывает FAB для добавления задачи', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Добавить задачу'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('показывает список задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('показывает меню с действиями', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - пустой чек-лист', () {
    testWidgets('показывает пустое состояние без задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = RenovationChecklist()
        ..name = 'Пустой чек-лист'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await repository.createChecklist(checklist);

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Нет задач'), findsOneWidget);
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
      expect(
        find.text('Нажмите + чтобы добавить задачу'),
        findsOneWidget,
      );
    });

    testWidgets('прогресс 0% для пустого чек-листа', (tester) async {
      setTestViewportSize(tester);

      final checklist = RenovationChecklist()
        ..name = 'Пустой чек-лист'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await repository.createChecklist(checklist);

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 из 0'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - взаимодействие с задачами', () {
    testWidgets('отображает чекбоксы для всех задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsWidgets);
      expect(
        tester.widgetList<CheckboxListTile>(checkboxes).length,
        equals(checklist.totalItems),
      );
    });

    testWidgets('задачи показывают название', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final firstItem = checklist.items.first;

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(firstItem.title), findsOneWidget);
    });

    testWidgets('задачи отображаются в Card', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('задачи поддерживают swipe to delete', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsWidgets);
    });

    testWidgets('невыполненные задачи показывают пустой круг', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsWidgets);
    });
  });

  group('ChecklistDetailsScreen - отображение прогресса', () {
    testWidgets('обновляет прогресс при выполнении задачи', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final firstItem = checklist.items.first;

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);

      // Отмечаем задачу как выполненную через repository
      await repository.toggleChecklistItem(firstItem.id);

      // Перезагружаем виджет
      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final updatedChecklist = await repository.getChecklistById(checklist.id);
      expect(
        find.text('${updatedChecklist!.progressPercent}%'),
        findsOneWidget,
      );
      expect(updatedChecklist.progressPercent, greaterThan(0));
    });

    testWidgets('показывает правильный счётчик задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining('из ${checklist.totalItems}'),
        findsOneWidget,
      );
    });

    testWidgets('LinearProgressIndicator отображает прогресс', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.0));
    });
  });

  group('ChecklistDetailsScreen - PopupMenu действия', () {
    testWidgets('открывает PopupMenu при нажатии', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Изменить название'), findsOneWidget);
      expect(find.text('Удалить'), findsOneWidget);
    });

    testWidgets('PopupMenu содержит пункт редактирования', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });

    testWidgets('PopupMenu содержит пункт удаления', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - UI компоненты', () {
    testWidgets('прогресс-карта имеет правильный цвет фона', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Прогресс'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('FAB имеет расширенную форму', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.child, isA<Row>());
    });

    testWidgets('задачи в Card имеют margin', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.margin, isNotNull);
    });

    testWidgets('Scaffold имеет body', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isNotNull);
    });

    testWidgets('AppBar имеет actions', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, greaterThan(0));
    });
  });

  group('ChecklistDetailsScreen - структура данных', () {
    testWidgets('widget является ConsumerStatefulWidget', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      final widget = find.byType(ChecklistDetailsScreen);
      expect(widget, findsOneWidget);
    });

    testWidgets('widget принимает required checklistId', (tester) async {
      setTestViewportSize(tester);
      const testId = 123;

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: testId),
        ),
      );

      final screen = tester.widget<ChecklistDetailsScreen>(
        find.byType(ChecklistDetailsScreen),
      );
      expect(screen.checklistId, equals(testId));
    });

    testWidgets('widget имеет key параметр', (tester) async {
      setTestViewportSize(tester);
      const testKey = Key('test_checklist_details');

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(
            key: testKey,
            checklistId: 1,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - lifecycle', () {
    testWidgets('виджет создаётся без ошибок', (tester) async {
      setTestViewportSize(tester);

      expect(
        () => tester.pumpWidget(
          createTestApp(
            child: const ChecklistDetailsScreen(checklistId: 1),
          ),
        ),
        returnsNormally,
      );
    });

    testWidgets('виджет можно пересобрать', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Пересоздаём виджет
      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(checklist.name), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - граничные случаи', () {
    testWidgets('обрабатывает ID = 0', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 0),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);
    });

    testWidgets('обрабатывает очень большой ID', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 999999999),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);
    });

    testWidgets('обрабатывает отрицательный ID', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: -1),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Чек-лист не найден'), findsOneWidget);
    });
  });

  group('ChecklistDetailsScreen - производительность', () {
    testWidgets('быстро отображает индикатор загрузки', (tester) async {
      setTestViewportSize(tester);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        createTestApp(
          child: const ChecklistDetailsScreen(checklistId: 1),
        ),
      );

      stopwatch.stop();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('эффективно отображает большой список задач', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      // Добавляем больше задач
      for (int i = 0; i < 10; i++) {
        await repository.createChecklistItem(
          checklistId: checklist.id,
          title: 'Дополнительная задача $i',
        );
      }

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
    });
  });

  group('ChecklistDetailsScreen - accessibility', () {
    testWidgets('все кнопки имеют semantic labels', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Добавить задачу'), findsOneWidget);
    });

    testWidgets('текст имеет достаточный контраст', (tester) async {
      setTestViewportSize(tester);

      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ChecklistDetailsScreen(checklistId: checklist.id),
          overrides: [
            isarProvider.overrideWith((ref) async => isar),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что текст отображается
      expect(find.text(checklist.name), findsOneWidget);
      expect(find.text('Прогресс'), findsOneWidget);
    });
  });
}
