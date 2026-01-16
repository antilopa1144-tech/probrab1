import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/project_v2.dart';
import '../../../../domain/models/checklist.dart';
import '../../../../data/repositories/checklist_repository.dart';
import '../../../providers/checklist_provider.dart';
import 'calculation_item_card.dart';
import 'project_materials_list.dart';
import '../../checklist/checklist_details_screen.dart';
import '../../checklist/create_checklist_bottom_sheet.dart';

/// Основной контент экрана деталей проекта.
///
/// Простой скроллируемый список с секциями:
/// 1. INFO - основная информация о проекте
/// 2. TASKS - расчёты проекта
/// 3. SHOPPING LIST - материалы с чекбоксами
/// 4. CHECKLISTS - чек-листы (если есть)
class ProjectDetailsContent extends ConsumerWidget {
  final ProjectV2 project;
  final VoidCallback onAddCalculation;
  final void Function(ProjectCalculation) onOpenCalculation;
  final void Function(ProjectCalculation) onDeleteCalculation;
  final VoidCallback onMaterialToggled;
  final VoidCallback onRefresh;

  const ProjectDetailsContent({
    super.key,
    required this.project,
    required this.onAddCalculation,
    required this.onOpenCalculation,
    required this.onDeleteCalculation,
    required this.onMaterialToggled,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // 1. Секция INFO (основная информация)
        _ProjectInfoSection(project: project),

        // 2. Секция TASKS (расчёты)
        _ProjectTasksSection(
          project: project,
          onAddCalculation: onAddCalculation,
          onOpenCalculation: onOpenCalculation,
          onDeleteCalculation: onDeleteCalculation,
        ),

        // 3. Секция SHOPPING LIST (материалы)
        ProjectMaterialsList(
          project: project,
          onMaterialToggled: onMaterialToggled,
        ),

        // 4. Секция CHECKLISTS (чек-листы) - только если есть ID проекта
        if (project.id > 0)
          _ProjectChecklistsSection(
            projectId: project.id,
            onRefresh: onRefresh,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Секция 1: Основная информация
// ═══════════════════════════════════════════════════════════════════════════

/// Секция с основной информацией о проекте.
class _ProjectInfoSection extends StatelessWidget {
  final ProjectV2 project;

  const _ProjectInfoSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок секции
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Информация',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Статус
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Статус',
              value: _StatusChip(status: project.status),
            ),

            // Адрес (если есть)
            if (project.address != null && project.address!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Адрес',
                value: Text(project.address!),
              ),
            ],

            // Дедлайн (если есть)
            if (project.deadline != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'Дедлайн',
                value: Row(
                  children: [
                    Text(dateFormat.format(project.deadline!)),
                    if (project.isDeadlineOverdue) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Описание (если есть)
            if (project.description != null &&
                project.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                project.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Теги (если есть)
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Даты создания/обновления
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Создан: ${DateFormat('dd.MM.yyyy').format(project.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Обновлён: ${DateFormat('dd.MM.yyyy').format(project.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка информации с иконкой, лейблом и значением.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(),
            child: value,
          ),
        ),
      ],
    );
  }
}

/// Чип статуса проекта.
class _StatusChip extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        _getStatusIcon(status),
        size: 18,
        color: Colors.white,
      ),
      label: Text(_getStatusLabel(status)),
      backgroundColor: _getStatusColor(status),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Icons.edit_note_rounded;
      case ProjectStatus.inProgress:
        return Icons.construction_rounded;
      case ProjectStatus.onHold:
        return Icons.pause_circle_outline_rounded;
      case ProjectStatus.completed:
        return Icons.check_circle_outline_rounded;
      case ProjectStatus.cancelled:
        return Icons.cancel_outlined;
      case ProjectStatus.problem:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Colors.blue;
      case ProjectStatus.inProgress:
        return Colors.orange;
      case ProjectStatus.onHold:
        return Colors.grey;
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.cancelled:
        return Colors.red;
      case ProjectStatus.problem:
        return Colors.deepOrange;
    }
  }

  String _getStatusLabel(ProjectStatus status) {
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
}

// ═══════════════════════════════════════════════════════════════════════════
// Секция 2: Задачи (Расчёты)
// ═══════════════════════════════════════════════════════════════════════════

/// Секция с расчётами проекта.
class _ProjectTasksSection extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onAddCalculation;
  final void Function(ProjectCalculation) onOpenCalculation;
  final void Function(ProjectCalculation) onDeleteCalculation;

  const _ProjectTasksSection({
    required this.project,
    required this.onAddCalculation,
    required this.onOpenCalculation,
    required this.onDeleteCalculation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculations = project.calculations.toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + кнопка добавить
            Row(
              children: [
                Icon(
                  Icons.checklist_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Задачи',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (${calculations.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddCalculation,
                  tooltip: 'Добавить расчёт',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Список расчётов или пустое состояние
            if (calculations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет расчётов',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавьте расчёт из калькулятора',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...calculations.map((calc) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CalculationItemCard(
                    calculation: calc,
                    onTap: () => onOpenCalculation(calc),
                    onDelete: () => onDeleteCalculation(calc),
                    expandByDefault: false,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Секция 4: Чек-листы
// ═══════════════════════════════════════════════════════════════════════════

/// Секция с чек-листами проекта.
class _ProjectChecklistsSection extends ConsumerWidget {
  final int projectId;
  final VoidCallback onRefresh;

  const _ProjectChecklistsSection({
    required this.projectId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.watch(checklistRepositoryProvider);
    final checklistsAsync = ref.watch(projectChecklistsProvider(projectId));

    return checklistsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (checklists) {
        if (checklists.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок + кнопки добавить
                Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Чек-листы',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' (${checklists.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Кнопка создания из шаблона
                    IconButton(
                      icon: const Icon(Icons.library_add_rounded),
                      onPressed: () => _addChecklistFromTemplate(context, ref),
                      tooltip: 'Создать из шаблона',
                    ),
                    // Кнопка создания пустого
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _addChecklist(context, ref),
                      tooltip: 'Создать пустой чек-лист',
                    ),
                  ],
                ),

                // Статистика (если есть задачи)
                FutureBuilder<ChecklistStats>(
                  future: repository.getProjectStats(projectId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final stats = snapshot.data!;
                    if (stats.totalItems == 0) return const SizedBox.shrink();

                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${stats.completedItems} / ${stats.totalItems}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'задач выполнено',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${stats.progressPercent}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(stats.progress, theme),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: stats.progress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: _getProgressColor(stats.progress, theme),
                          minHeight: 6,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                // Список чек-листов
                ...checklists.map((checklist) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ChecklistCard(
                      checklist: checklist,
                      onTap: () => _openChecklist(context, checklist),
                      onDelete: () =>
                          _deleteChecklist(context, ref, checklist),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return theme.colorScheme.primary;
  }

  Future<void> _addChecklistFromTemplate(BuildContext context, WidgetRef ref) async {
    // Импортируем CreateChecklistBottomSheet
    final checklist = await CreateChecklistBottomSheet.show(
      context,
      projectId: projectId,
    );

    if (checklist != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Чек-лист "${checklist.name}" создан из шаблона'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => _openChecklist(context, checklist),
          ),
        ),
      );
    }
  }

  Future<void> _addChecklist(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    ChecklistCategory selectedCategory = ChecklistCategory.general;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Новый чек-лист'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    hintText: 'Например: Ремонт ванной',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (необязательно)',
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Text(
                  'Категория',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ChecklistCategory.values.map((category) {
                    return ChoiceChip(
                      label: Text(
                        '${category.icon} ${category.displayName}',
                      ),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedCategory = category);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'category': selectedCategory,
                  });
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final repository = ref.read(checklistRepositoryProvider);
      final checklist = RenovationChecklist()
        ..name = result['name'] as String
        ..description = (result['description'] as String).isEmpty
            ? null
            : result['description'] as String
        ..category = result['category'] as ChecklistCategory
        ..projectId = projectId
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final createdChecklist = await repository.createChecklist(checklist);

      if (context.mounted) {
        // Автоматически открываем чек-лист и показываем подсказку о добавлении задач
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChecklistDetailsScreen(checklistId: createdChecklist.id),
          ),
        );
      }
    }
  }

  void _openChecklist(BuildContext context, RenovationChecklist checklist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistDetailsScreen(checklistId: checklist.id),
      ),
    );
  }

  Future<void> _deleteChecklist(
    BuildContext context,
    WidgetRef ref,
    RenovationChecklist checklist,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить чек-лист?'),
        content: Text(
          'Чек-лист "${checklist.name}" будет удалён безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final repository = ref.read(checklistRepositoryProvider);
      await repository.deleteChecklist(checklist.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Чек-лист удалён')),
        );
      }
    }
  }
}

/// Карточка чек-листа.
class _ChecklistCard extends StatelessWidget {
  final RenovationChecklist checklist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChecklistCard({
    required this.checklist,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    checklist.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (checklist.description != null)
                          Text(
                            checklist.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: checklist.progress,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${checklist.completedItems}/${checklist.totalItems}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
