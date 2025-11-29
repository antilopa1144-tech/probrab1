import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/reminder.dart';

void main() {
  group('Reminder', () {
    test('creates reminder with all fields', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Test Reminder',
        description: 'Test Description',
        scheduledDate: DateTime(2024, 6, 15, 10, 0),
        type: ReminderType.materialPurchase,
        relatedCalculationId: 'calc-1',
        relatedProjectId: 'proj-1',
      );

      expect(reminder.id, equals('rem-1'));
      expect(reminder.title, equals('Test Reminder'));
      expect(reminder.type, equals(ReminderType.materialPurchase));
      expect(reminder.isCompleted, equals(false));
      expect(reminder.relatedCalculationId, equals('calc-1'));
    });

    test('isOverdue returns true for past dates', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Overdue',
        description: 'Test',
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        type: ReminderType.deadline,
      );

      expect(reminder.isOverdue, isTrue);
    });

    test('isOverdue returns false for future dates', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Future',
        description: 'Test',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        type: ReminderType.deadline,
      );

      expect(reminder.isOverdue, isFalse);
    });

    test('isOverdue returns false when completed', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Completed',
        description: 'Test',
        scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
        type: ReminderType.deadline,
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      expect(reminder.isOverdue, isFalse);
    });

    test('isUpcoming returns true for next 24 hours', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Upcoming',
        description: 'Test',
        scheduledDate: DateTime.now().add(const Duration(hours: 12)),
        type: ReminderType.workStart,
      );

      expect(reminder.isUpcoming, isTrue);
    });

    test('isUpcoming returns false for more than 24 hours', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Not Upcoming',
        description: 'Test',
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        type: ReminderType.workStart,
      );

      expect(reminder.isUpcoming, isFalse);
    });

    test('isUpcoming returns false when completed', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Completed',
        description: 'Test',
        scheduledDate: DateTime.now().add(const Duration(hours: 12)),
        type: ReminderType.workStart,
        isCompleted: true,
      );

      expect(reminder.isUpcoming, isFalse);
    });

    test('isUpcoming returns false for past dates', () {
      final reminder = Reminder(
        id: 'rem-1',
        title: 'Past',
        description: 'Test',
        scheduledDate: DateTime.now().subtract(const Duration(hours: 1)),
        type: ReminderType.workStart,
      );

      expect(reminder.isUpcoming, isFalse);
    });
  });

  group('ReminderTemplate', () {
    test('creates reminder from template', () {
      final template = ReminderTemplate(
        workType: 'foundation',
        type: ReminderType.materialPurchase,
        title: 'Buy Materials',
        description: 'Purchase foundation materials',
        daysBefore: 3,
      );

      final eventDate = DateTime(2024, 6, 20);
      final reminder = template.createReminder(
        id: 'rem-1',
        eventDate: eventDate,
        calculationId: 'calc-1',
        projectId: 'proj-1',
      );

      expect(reminder.title, equals('Buy Materials'));
      expect(reminder.scheduledDate, equals(eventDate.subtract(const Duration(days: 3))));
      expect(reminder.relatedCalculationId, equals('calc-1'));
      expect(reminder.relatedProjectId, equals('proj-1'));
    });

    test('creates reminder without related IDs', () {
      final template = ReminderTemplate(
        workType: 'walls',
        type: ReminderType.qualityCheck,
        title: 'Check Quality',
        description: 'Check wall quality',
        daysBefore: 1,
      );

      final reminder = template.createReminder(
        id: 'rem-2',
        eventDate: DateTime(2024, 6, 20),
      );

      expect(reminder.relatedCalculationId, isNull);
      expect(reminder.relatedProjectId, isNull);
    });
  });
}
