import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart' show isarProvider;
import '../../../data/repositories/checklist_repository.dart';
import '../../../domain/models/checklist.dart';

/// Экран деталей чек-листа
class ChecklistDetailsScreen extends ConsumerStatefulWidget {
  final int checklistId;

  const ChecklistDetailsScreen({
    super.key,
    required this.checklistId,
  });

  @override
  ConsumerState<ChecklistDetailsScreen> createState() =>
      _ChecklistDetailsScreenState();
}

class _ChecklistDetailsScreenState
    extends ConsumerState<ChecklistDetailsScreen> {
  RenovationChecklist? _checklist;
  List<ChecklistItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isar = await ref.read(isarProvider.future);
      final repository = ChecklistRepository(isar);

      final checklist = await repository.getChecklistById(widget.checklistId);
      if (checklist == null) {
        setState(() {
          _error = 'Чек-лист не найден';
          _isLoading = false;
        });
        return;
      }

      final items = await repository.getChecklistItems(widget.checklistId);

      setState(() {
        _checklist = checklist;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final repository = ChecklistRepository(isar);

      await repository.toggleChecklistItem(item.id);
      await _loadChecklist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addNewTask() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая задача'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название задачи',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final isar = await ref.read(isarProvider.future);
        final repository = ChecklistRepository(isar);

        await repository.createChecklistItem(
          checklistId: widget.checklistId,
          title: result,
        );

        await _loadChecklist();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Задача добавлена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editChecklistName() async {
    if (_checklist == null) return;

    final controller = TextEditingController(text: _checklist!.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить название'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название чек-листа',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _checklist!.name) {
      try {
        final isar = await ref.read(isarProvider.future);
        final repository = ChecklistRepository(isar);

        _checklist!.name = result;
        await repository.updateChecklist(_checklist!);
        await _loadChecklist();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Название обновлено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editTask(ChecklistItem item) async {
    final controller = TextEditingController(text: item.title);
    final descController = TextEditingController(text: item.description ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать задачу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLength: 500,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop({
                  'title': controller.text.trim(),
                  'description': descController.text.trim(),
                });
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result['title']!.isNotEmpty) {
      try {
        final isar = await ref.read(isarProvider.future);
        final repository = ChecklistRepository(isar);

        item.title = result['title']!;
        item.description =
            result['description']!.isEmpty ? null : result['description'];
        await repository.updateChecklistItem(item);
        await _loadChecklist();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Задача обновлена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _confirmDeleteTask(ChecklistItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить задачу?'),
            content: Text('Удалить "${item.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTask(ChecklistItem item) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final repository = ChecklistRepository(isar);

      await repository.deleteChecklistItem(item.id);
      await _loadChecklist();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTaskOptions(ChecklistItem item) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                item.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.of(context).pop();
                _editTask(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title:
                  const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await _confirmDeleteTask(item);
                if (confirmed) {
                  _deleteTask(item);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteChecklist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить чек-лист?'),
        content: const Text(
          'Это действие нельзя отменить. Все задачи будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final isar = await ref.read(isarProvider.future);
        final repository = ChecklistRepository(isar);

        await repository.deleteChecklist(widget.checklistId);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Чек-лист удалён')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Чек-лист'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _checklist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Чек-лист'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Чек-лист не найден',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_checklist!.name),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit_name',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded),
                    SizedBox(width: 12),
                    Text('Изменить название'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Удалить', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'edit_name':
                  _editChecklistName();
                  break;
                case 'delete':
                  _deleteChecklist();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Прогресс',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${_checklist!.completedItems} из ${_checklist!.totalItems}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _checklist!.progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_checklist!.progressPercent}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет задач',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите + чтобы добавить задачу',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key('task_${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (_) => _confirmDeleteTask(item),
                        onDismissed: (_) => _deleteTask(item),
                        child: GestureDetector(
                          onLongPress: () => _showTaskOptions(item),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: CheckboxListTile(
                              value: item.isCompleted,
                              onChanged: (_) => _toggleItem(item),
                              title: Text(
                                item.title,
                                style: item.isCompleted
                                    ? const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              subtitle: item.description != null
                                  ? Text(
                                      item.description!,
                                      style: item.isCompleted
                                          ? const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    )
                                  : null,
                              secondary: item.isCompleted
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                    )
                                  : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить задачу'),
      ),
    );
  }
}
