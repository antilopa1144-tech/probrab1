import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/presentation/providers/reminder_provider.dart';
import 'package:probrab_ai/domain/entities/reminder.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReminderNotifier', () {
    test('starts with empty list', () {
      final notifier = ReminderNotifier();
      expect(notifier.state, isEmpty);
    });

    test('addReminder adds reminder to state', () async {
      final notifier = ReminderNotifier();

      final reminder = Reminder(
        id: '1',
        title: 'Test Reminder',
        description: 'Test Description',
        scheduledDate: DateTime(2025, 1, 15),
        type: ReminderType.custom,
      );

      await notifier.addReminder(reminder);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, '1');
      expect(notifier.state.first.title, 'Test Reminder');
    });

    test('addReminder persists to SharedPreferences', () async {
      final notifier = ReminderNotifier();

      final reminder = Reminder(
        id: '1',
        title: 'Test Reminder',
        description: 'Test Description',
        scheduledDate: DateTime(2025, 1, 15),
        type: ReminderType.materialPurchase,
      );

      await notifier.addReminder(reminder);

      // Create new notifier to load from SharedPreferences
      final notifier2 = ReminderNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier2.state.length, 1);
      expect(notifier2.state.first.title, 'Test Reminder');
    });

    test('updateReminder updates existing reminder', () async {
      final notifier = ReminderNotifier();

      final reminder = Reminder(
        id: '1',
        title: 'Original',
        description: 'Description',
        scheduledDate: DateTime(2025, 1, 15),
        type: ReminderType.custom,
      );

      await notifier.addReminder(reminder);

      final updated = Reminder(
        id: '1',
        title: 'Updated',
        description: 'New Description',
        scheduledDate: DateTime(2025, 1, 20),
        type: ReminderType.workStart,
      );

      await notifier.updateReminder('1', updated);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.title, 'Updated');
      expect(notifier.state.first.description, 'New Description');
    });

    test('updateReminder does not affect other reminders', () async {
      final notifier = ReminderNotifier();

      await notifier.addReminder(Reminder(
        id: '1',
        title: 'First',
        description: 'Description 1',
        scheduledDate: DateTime(2025, 1, 15),
        type: ReminderType.custom,
      ));

      await notifier.addReminder(Reminder(
        id: '2',
        title: 'Second',
        description: 'Description 2',
        scheduledDate: DateTime(2025, 1, 20),
        type: ReminderType.deadline,
      ));

      final updated = Reminder(
        id: '1',
        title: 'Updated',
        description: 'Updated Description',
        scheduledDate: DateTime(2025, 1, 25),
        type: ReminderType.workStart,
      );

      await notifier.updateReminder('1', updated);

      expect(notifier.state.length, 2);
      expect(notifier.state[0].title, 'Updated');
      expect(notifier.state[1].title, 'Second');
    });

    test('completeReminder marks reminder as completed', () async {
      final notifier = ReminderNotifier();

      final reminder = Reminder(
        id: '1',
        title: 'Test',
        description: 'Description',
        scheduledDate: DateTime(2025, 1, 15),
        type: ReminderType.custom,
      );

      await notifier.addReminder(reminder);
      await notifier.completeReminder('1');

      expect(notifier.state.first.isCompleted, true);
      expect(notifier.state.first.completedAt, isNotNull);
    });

    test('deleteReminder removes reminder from state', () async {
      final notifier = ReminderNotifier();

      await notifier.addReminder(Reminder(
        id: '1',
        title: 'First',
        description: 'Description 1',
        scheduledDate: DateTime(2025, 1, 15),
        type: ReminderType.custom,
      ));

      await notifier.addReminder(Reminder(
        id: '2',
        title: 'Second',
        description: 'Description 2',
        scheduledDate: DateTime(2025, 1, 20),
        type: ReminderType.deadline,
      ));

      await notifier.deleteReminder('1');

      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, '2');
    });

    test('getUpcoming returns only upcoming uncompleted reminders', () async {
      final notifier = ReminderNotifier();
      final now = DateTime.now();

      // Upcoming reminder (within 24 hours)
      await notifier.addReminder(Reminder(
        id: '1',
        title: 'Upcoming',
        description: 'Description',
        scheduledDate: now.add(const Duration(hours: 12)),
        type: ReminderType.custom,
      ));

      // Future reminder (more than 24 hours away)
      await notifier.addReminder(Reminder(
        id: '2',
        title: 'Future',
        description: 'Description',
        scheduledDate: now.add(const Duration(days: 5)),
        type: ReminderType.custom,
      ));

      // Past reminder
      await notifier.addReminder(Reminder(
        id: '3',
        title: 'Past',
        description: 'Description',
        scheduledDate: now.subtract(const Duration(days: 1)),
        type: ReminderType.custom,
      ));

      // Completed upcoming reminder
      await notifier.addReminder(Reminder(
        id: '4',
        title: 'Completed',
        description: 'Description',
        scheduledDate: now.add(const Duration(hours: 6)),
        type: ReminderType.custom,
        isCompleted: true,
      ));

      final upcoming = notifier.getUpcoming();

      expect(upcoming.length, 1);
      expect(upcoming.first.id, '1');
    });

    test('getOverdue returns only overdue reminders', () async {
      final notifier = ReminderNotifier();
      final now = DateTime.now();

      // Overdue reminder
      await notifier.addReminder(Reminder(
        id: '1',
        title: 'Overdue',
        description: 'Description',
        scheduledDate: now.subtract(const Duration(days: 1)),
        type: ReminderType.custom,
      ));

      // Future reminder
      await notifier.addReminder(Reminder(
        id: '2',
        title: 'Future',
        description: 'Description',
        scheduledDate: now.add(const Duration(days: 1)),
        type: ReminderType.custom,
      ));

      // Completed overdue reminder
      await notifier.addReminder(Reminder(
        id: '3',
        title: 'Completed Overdue',
        description: 'Description',
        scheduledDate: now.subtract(const Duration(days: 2)),
        type: ReminderType.custom,
        isCompleted: true,
        completedAt: now,
      ));

      final overdue = notifier.getOverdue();

      expect(overdue.length, 1);
      expect(overdue.first.id, '1');
    });

    test('handles JSON serialization/deserialization correctly', () async {
      final notifier = ReminderNotifier();

      final reminder = Reminder(
        id: 'test-id',
        title: 'Test Reminder',
        description: 'Test Description',
        scheduledDate: DateTime(2025, 1, 15, 10, 30),
        type: ReminderType.materialPurchase,
        relatedCalculationId: 'calc-123',
        relatedProjectId: 'project-456',
      );

      await notifier.addReminder(reminder);

      // Load from storage
      final notifier2 = ReminderNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final loaded = notifier2.state.first;
      expect(loaded.id, 'test-id');
      expect(loaded.title, 'Test Reminder');
      expect(loaded.description, 'Test Description');
      expect(loaded.scheduledDate, DateTime(2025, 1, 15, 10, 30));
      expect(loaded.type, ReminderType.materialPurchase);
      expect(loaded.relatedCalculationId, 'calc-123');
      expect(loaded.relatedProjectId, 'project-456');
    });
  });

  group('ReminderTemplate', () {
    test('createReminder creates reminder from template', () {
      const template = ReminderTemplate(
        workType: 'painting',
        type: ReminderType.materialPurchase,
        title: 'Buy paint',
        description: 'Purchase paint for walls',
        daysBefore: 3,
      );

      final eventDate = DateTime(2025, 1, 20);
      final reminder = template.createReminder(
        id: 'reminder-1',
        eventDate: eventDate,
        calculationId: 'calc-123',
        projectId: 'project-456',
      );

      expect(reminder.id, 'reminder-1');
      expect(reminder.title, 'Buy paint');
      expect(reminder.description, 'Purchase paint for walls');
      expect(reminder.scheduledDate, DateTime(2025, 1, 17)); // 3 days before
      expect(reminder.type, ReminderType.materialPurchase);
      expect(reminder.relatedCalculationId, 'calc-123');
      expect(reminder.relatedProjectId, 'project-456');
    });
  });
}
