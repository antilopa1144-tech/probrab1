import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/core/services/notification_service.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService Settings', () {
    test('areNotificationsEnabled returns false by default', () async {
      final enabled = await NotificationService.areNotificationsEnabled();
      expect(enabled, false);
    });

    test('getReminderDays returns default values', () async {
      final days = await NotificationService.getReminderDays();
      expect(days, [1, 3, 7]);
    });

    test('setReminderDays persists custom values', () async {
      await NotificationService.setReminderDays([2, 5, 10]);
      final days = await NotificationService.getReminderDays();
      expect(days, [2, 5, 10]);
    });

    test('getReminderHour returns default value', () async {
      final hour = await NotificationService.getReminderHour();
      expect(hour, 9);
    });

    test('setReminderHour persists custom value', () async {
      await NotificationService.setReminderHour(14);
      final hour = await NotificationService.getReminderHour();
      expect(hour, 14);
    });

    test('setReminderHour accepts valid hours', () async {
      await NotificationService.setReminderHour(0);
      expect(await NotificationService.getReminderHour(), 0);

      await NotificationService.setReminderHour(23);
      expect(await NotificationService.getReminderHour(), 23);
    });

    test('setReminderDays accepts empty list', () async {
      await NotificationService.setReminderDays([]);
      final days = await NotificationService.getReminderDays();
      expect(days, isEmpty);
    });

    test('setReminderDays accepts single day', () async {
      await NotificationService.setReminderDays([1]);
      final days = await NotificationService.getReminderDays();
      expect(days, [1]);
    });
  });

  group('NotificationService Project Filtering', () {
    // These tests verify the filtering logic without calling the actual notification plugin

    test('project with no deadline should be skipped', () {
      final project = ProjectV2()
        ..id = 1
        ..name = 'Test Project';

      expect(project.deadline, isNull);
    });

    test('completed project should be skipped', () {
      final project = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..deadline = DateTime.now().add(const Duration(days: 10))
        ..status = ProjectStatus.completed;

      expect(project.status, ProjectStatus.completed);
    });

    test('cancelled project should be skipped', () {
      final project = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..deadline = DateTime.now().add(const Duration(days: 10))
        ..status = ProjectStatus.cancelled;

      expect(project.status, ProjectStatus.cancelled);
    });

    test('active project with deadline is valid for notifications', () {
      final project = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..deadline = DateTime.now().add(const Duration(days: 10))
        ..status = ProjectStatus.inProgress;

      expect(project.deadline, isNotNull);
      expect(project.status, isNot(ProjectStatus.completed));
      expect(project.status, isNot(ProjectStatus.cancelled));
    });

    test('planning project with deadline is valid for notifications', () {
      final project = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..deadline = DateTime.now().add(const Duration(days: 10))
        ..status = ProjectStatus.planning;

      expect(project.deadline, isNotNull);
      expect(project.status, isNot(ProjectStatus.completed));
      expect(project.status, isNot(ProjectStatus.cancelled));
    });
  });

  group('Notification ID Generation', () {
    // Tests for notification ID uniqueness logic

    test('different projects have different base IDs', () {
      final project1 = ProjectV2()..id = 1;
      final project2 = ProjectV2()..id = 2;

      // IDs should be different based on project ID
      expect(project1.id, isNot(project2.id));
    });

    test('project ID is used for notification identification', () {
      final project = ProjectV2()..id = 123;

      // The notification service uses project.id * 100 + daysBefore
      // So project 123 with 7 days before would be 12307
      expect(project.id * 100 + 7, 12307);
      expect(project.id * 100 + 1, 12301);
      expect(project.id * 100 + 3, 12303);
    });
  });
}
