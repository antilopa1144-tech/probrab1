import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/reminder.dart';
import '../../providers/reminder_provider.dart';

/// Экран напоминаний.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderProvider);
    final upcoming = reminders.where((r) => r.isUpcoming && !r.isCompleted).toList();
    final overdue = reminders.where((r) => r.isOverdue).toList();
    final all = reminders.where((r) => !r.isCompleted).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Напоминания'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Все', icon: Icon(Icons.list)),
              Tab(text: 'Скоро', icon: Icon(Icons.schedule)),
              Tab(text: 'Просрочено', icon: Icon(Icons.warning)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddReminderDialog(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _RemindersList(reminders: all),
            _RemindersList(reminders: upcoming),
            _RemindersList(reminders: overdue),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    ReminderType selectedType = ReminderType.custom;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Новое напоминание'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Дата: ${_formatDate(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                DropdownButton<ReminderType>(
                  value: selectedType,
                  isExpanded: true,
                  items: ReminderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final reminder = Reminder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  description: descController.text,
                  scheduledDate: selectedDate,
                  type: selectedType,
                );
                ref.read(reminderProvider.notifier).addReminder(reminder);
                Navigator.pop(context);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.materialPurchase:
        return 'Закупка материалов';
      case ReminderType.workStart:
        return 'Начало работ';
      case ReminderType.qualityCheck:
        return 'Проверка качества';
      case ReminderType.nextStep:
        return 'Следующий этап';
      case ReminderType.deadline:
        return 'Дедлайн';
      case ReminderType.custom:
        return 'Пользовательское';
    }
  }
}

class _RemindersList extends ConsumerWidget {
  final List<Reminder> reminders;

  const _RemindersList({required this.reminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reminders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64),
            SizedBox(height: 16),
            Text('Нет напоминаний'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return RepaintBoundary(
          child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: reminder.isOverdue 
              ? Colors.red.withValues(alpha: 0.1)
              : reminder.isUpcoming
                  ? Colors.orange.withValues(alpha: 0.1)
                  : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: reminder.isOverdue
                  ? Colors.red
                  : reminder.isUpcoming
                      ? Colors.orange
                      : Colors.blue,
              child: Icon(_getTypeIcon(reminder.type)),
            ),
            title: Text(reminder.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.description),
                const SizedBox(height: 4),
                Text(
                  _formatDate(reminder.scheduledDate),
                  style: TextStyle(
                    color: reminder.isOverdue ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: reminder.isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      ref.read(reminderProvider.notifier).completeReminder(reminder.id);
                    },
                  ),
            onTap: () {
              // Открыть детали
            },
          ),
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.materialPurchase:
        return Icons.shopping_cart;
      case ReminderType.workStart:
        return Icons.play_arrow;
      case ReminderType.qualityCheck:
        return Icons.check_circle;
      case ReminderType.nextStep:
        return Icons.arrow_forward;
      case ReminderType.deadline:
        return Icons.warning;
      case ReminderType.custom:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

