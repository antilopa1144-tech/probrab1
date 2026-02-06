import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/dashboard_project_card.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late ProjectV2 testProject;

  setUpAll(() {
    setupMocks();
  });

  setUp(() {
    testProject = ProjectV2()
      ..id = 1
      ..name = 'Тестовый проект'
      ..description = 'Описание'
      ..address = 'ул. Тестовая, 123'
      ..status = ProjectStatus.inProgress
      ..budgetTotal = 100000
      ..budgetSpent = 50000
      ..tasksTotal = 10
      ..tasksCompleted = 5
      ..deadline = DateTime.now().add(const Duration(days: 30))
      ..isFavorite = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  });

  group('DashboardProjectCard', () {
    testWidgets('renders project name', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Тестовый проект'), findsOneWidget);
    });

    testWidgets('renders project address when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('ул. Тестовая, 123'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('does not render address when null', (tester) async {
      testProject.address = null;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('renders status badge with correct label', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('В работе'), findsOneWidget);
    });

    testWidgets('renders no progress section when no materials', (tester) async {
      // testProject has no calculations/materials (IsarLinks not loaded),
      // so _InfoRow shows neither calculations count nor progress bar
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      // No materials → no "Куплено" text and no progress bar
      expect(find.text('Куплено'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // No calculations → no calculate icon
      expect(find.byIcon(Icons.calculate_outlined), findsNothing);
    });

    testWidgets('does not render budget row (budget display removed from card)',
        (tester) async {
      // Budget display was removed from DashboardProjectCard;
      // the card now shows calculations count and materials progress instead
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      // Wallet icon is no longer present in the card
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
    });

    testWidgets('does not render budget row when budget is 0', (tester) async {
      testProject.budgetTotal = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
    });

    testWidgets('does not show budget warning icon (budget display removed)',
        (tester) async {
      testProject.budgetSpent = 150000;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      // Budget display was removed from card.
      // No wallet icon or budget-specific warning should appear.
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
    });

    testWidgets('renders deadline when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    });

    testWidgets('does not render deadline when null', (tester) async {
      testProject.deadline = null;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.event_outlined), findsNothing);
      expect(find.byIcon(Icons.event_busy_rounded), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders favorite button when callback provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('shows filled star when project is favorite', (tester) async {
      testProject.isFavorite = true;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('calls onToggleFavorite when favorite button pressed',
        (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
              onToggleFavorite: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_outline_rounded));
      expect(toggled, isTrue);
    });

    testWidgets('does not render favorite button when callback not provided',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('uses Card widget', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: DashboardProjectCard(
              project: testProject,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    group('status badges', () {
      for (final status in ProjectStatus.values) {
        testWidgets('renders correct label for $status', (tester) async {
          testProject.status = status;

          await tester.pumpWidget(
            createTestApp(
              child: Scaffold(
                body: DashboardProjectCard(
                  project: testProject,
                  onTap: () {},
                ),
              ),
            ),
          );

          final expectedLabel = _getExpectedStatusLabel(status);
          expect(find.text(expectedLabel), findsOneWidget);
        });
      }
    });

    group('deadline display', () {
      testWidgets('shows "Сегодня" for deadline today', (tester) async {
        testProject.deadline = DateTime.now();

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: DashboardProjectCard(
                project: testProject,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Сегодня'), findsOneWidget);
      });

      testWidgets('shows days remaining for future deadline', (tester) async {
        // Set deadline to 3 days from now to get consistent "3 дня" result
        testProject.deadline = DateTime.now().add(const Duration(days: 3));

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: DashboardProjectCard(
                project: testProject,
                onTap: () {},
              ),
            ),
          ),
        );

        // Should show "X дня" or "X дней" badge
        expect(find.textContaining(RegExp(r'\d+ дн')), findsOneWidget);
      });

      testWidgets('shows "Просрочен" for overdue deadline', (tester) async {
        testProject.deadline = DateTime.now().subtract(const Duration(days: 1));

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: DashboardProjectCard(
                project: testProject,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Просрочен'), findsOneWidget);
      });
    });
  });
}

String _getExpectedStatusLabel(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning:
      return 'Планирование';
    case ProjectStatus.inProgress:
      return 'В работе';
    case ProjectStatus.onHold:
      return 'На паузе';
    case ProjectStatus.completed:
      return 'Завершён';
    case ProjectStatus.cancelled:
      return 'Отменён';
    case ProjectStatus.problem:
      return 'Проблема';
  }
}
