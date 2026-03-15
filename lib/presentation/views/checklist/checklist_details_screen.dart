import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../domain/models/checklist.dart';
import '../../../presentation/providers/checklist_provider.dart';

/// Экран деталей чек-листа (переписан для использования Riverpod провайдеров)
class ChecklistDetailsScreen extends ConsumerWidget {
  final int checklistId;

  const ChecklistDetailsScreen({
    super.key,
    required this.checklistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final checklistAsync = ref.watch(checklistProvider(checklistId));

    return checklistAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('checklist.title')),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('checklist.title')),
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
                loc.translate('checklist.not_found'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(loc.translate('checklist.back')),
              ),
            ],
          ),
        ),
      ),
      data: (checklist) {
        if (checklist == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(loc.translate('checklist.title')),
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
                    loc.translate('checklist.not_found'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(loc.translate('checklist.back')),
                  ),
                ],
              ),
            ),
          );
        }

        return _ChecklistDetailsContent(
          checklist: checklist,
        );
      },
    );
  }
}

/// Контент экрана деталей чек-листа
class _ChecklistDetailsContent extends ConsumerWidget {
  final RenovationChecklist checklist;

  const _ChecklistDetailsContent({
    required this.checklist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final items = checklist.items.toList();
    final completedCount = items.where((i) => i.isCompleted).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(checklist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _editChecklistName(context, ref, checklist),
            tooltip: loc.translate('checklist.edit_name'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChecklist(context, ref, checklist);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(loc.translate('checklist.delete_checklist_menu'), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.translate('checklist.progress'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.translate('checklist.completed_summary').replaceFirst('{completed}', '$completedCount').replaceFirst('{total}', '$totalCount'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tasks list or empty state
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 80,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            loc.translate('checklist.empty_tasks'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.translate('checklist.empty_tasks_hint'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () => _addNewTask(context, ref, checklist),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(loc.translate('checklist.add_first_task')),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ChecklistItemCard(
                        item: item,
                        checklistId: checklist.id,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewTask(context, ref, checklist),
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.translate('checklist.add_task')),
      ),
    );
  }

  Future<void> _addNewTask(BuildContext context, WidgetRef ref, RenovationChecklist checklist) async {
    final controller = TextEditingController();
    final loc = AppLocalizations.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('checklist.new_task')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: loc.translate('checklist.task_name'),
            border: const OutlineInputBorder(),
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
            child: Text(loc.translate('button.cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(loc.translate('checklist.add')),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await ref.read(checklistNotifierProvider.notifier).addItem(
              checklistId: checklist.id,
              title: result,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('checklist.task_added'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('workflow.timeline.error').replaceFirst('{error}', GlobalErrorHandler.getUserFriendlyMessage(context, e))),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editChecklistName(BuildContext context, WidgetRef ref, RenovationChecklist checklist) async {
    final controller = TextEditingController(text: checklist.name);
    final loc = AppLocalizations.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('checklist.rename_title')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: loc.translate('checklist.checklist_name'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.translate('button.cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(loc.translate('button.save')),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != checklist.name && context.mounted) {
      try {
        checklist.name = result;
        await ref.read(checklistNotifierProvider.notifier).updateChecklist(checklist);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('checklist.name_updated'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('workflow.timeline.error').replaceFirst('{error}', GlobalErrorHandler.getUserFriendlyMessage(context, e))),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteChecklist(BuildContext context, WidgetRef ref, RenovationChecklist checklist) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('checklist.delete_title')),
        content: Text(
          loc.translate('checklist.delete_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.translate('button.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.translate('button.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(checklistNotifierProvider.notifier).deleteChecklist(checklist.id);

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('checklist.deleted'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('workflow.timeline.error').replaceFirst('{error}', GlobalErrorHandler.getUserFriendlyMessage(context, e))),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Карточка элемента чек-листа
class _ChecklistItemCard extends ConsumerWidget {
  final ChecklistItem item;
  final int checklistId;

  const _ChecklistItemCard({
    required this.item,
    required this.checklistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('checklist_item_${item.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe to delete
          return _confirmDeleteTask(context, item);
        } else {
          // Swipe to toggle
          await _toggleItem(context, ref, item);
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onLongPress: () => _showTaskOptions(context, ref, item),
          borderRadius: BorderRadius.circular(12),
          child: CheckboxListTile(
            value: item.isCompleted,
            onChanged: (_) => _toggleItem(context, ref, item),
            title: Text(
              item.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                color: item.isCompleted
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
            subtitle: item.description != null && item.description!.isNotEmpty
                ? Text(
                    item.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            secondary: item.priority == ChecklistPriority.high
                ? Icon(
                    Icons.priority_high_rounded,
                    color: theme.colorScheme.error,
                  )
                : null,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleItem(BuildContext context, WidgetRef ref, ChecklistItem item) async {
    final loc = AppLocalizations.of(context);
    try {
      await ref.read(checklistNotifierProvider.notifier).toggleItem(item.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('workflow.timeline.error').replaceFirst('{error}', GlobalErrorHandler.getUserFriendlyMessage(context, e))),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDeleteTask(BuildContext context, ChecklistItem item) async {
    final loc = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.translate('checklist.delete_task_title')),
            content: Text(loc.translate('checklist.delete_task_message').replaceFirst('{name}', item.title)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.translate('button.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(loc.translate('button.delete')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref, ChecklistItem item) async {
    final loc = AppLocalizations.of(context);
    try {
      await ref.read(checklistNotifierProvider.notifier).deleteItem(item.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('checklist.task_deleted'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('workflow.timeline.error').replaceFirst('{error}', GlobalErrorHandler.getUserFriendlyMessage(context, e))),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTaskOptions(BuildContext context, WidgetRef ref, ChecklistItem item) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

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
              title: Text(loc.translate('button.edit')),
              onTap: () {
                Navigator.of(context).pop();
                _editTask(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(loc.translate('button.delete'), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                if (context.mounted) {
                  final confirmed = await _confirmDeleteTask(context, item);
                  if (confirmed && context.mounted) {
                    _deleteTask(context, ref, item);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref, ChecklistItem item) async {
    final controller = TextEditingController(text: item.title);
    final descController = TextEditingController(text: item.description ?? '');
    final loc = AppLocalizations.of(context);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('checklist.edit_task')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: loc.translate('project.name'),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: loc.translate('project.description_optional'),
                border: const OutlineInputBorder(),
              ),
              maxLength: 500,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.translate('button.cancel')),
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
            child: Text(loc.translate('button.save')),
          ),
        ],
      ),
    );

    if (result != null && result['title']!.isNotEmpty && context.mounted) {
      try {
        item.title = result['title']!;
        item.description = result['description']!.isEmpty ? null : result['description'];
        await ref.read(checklistNotifierProvider.notifier).updateItem(item);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('checklist.task_updated'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('workflow.timeline.error').replaceFirst('{error}', GlobalErrorHandler.getUserFriendlyMessage(context, e))),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
