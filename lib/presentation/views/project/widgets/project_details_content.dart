import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/project_v2.dart';
import '../../../../domain/models/checklist.dart';
import '../../../../data/repositories/checklist_repository.dart';
import '../../../providers/checklist_provider.dart';
import 'calculation_item_card.dart';
import 'project_info_card.dart';
import 'project_materials_list.dart';
import '../../checklist/checklist_details_screen.dart';

/// Основной контент экрана деталей проекта.
class ProjectDetailsContent extends ConsumerStatefulWidget {
  final ProjectV2 project;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onAddCalculation;
  final VoidCallback onExport;
  final VoidCallback onChangeStatus;
  final VoidCallback onShareQR;
  final void Function(ProjectCalculation) onOpenCalculation;
  final void Function(ProjectCalculation) onDeleteCalculation;
  final VoidCallback onRefresh;

  const ProjectDetailsContent({
    super.key,
    required this.project,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onAddCalculation,
    required this.onExport,
    required this.onChangeStatus,
    required this.onShareQR,
    required this.onOpenCalculation,
    required this.onDeleteCalculation,
    required this.onRefresh,
  });

  @override
  ConsumerState<ProjectDetailsContent> createState() =>
      _ProjectDetailsContentState();
}

class _ProjectDetailsContentState extends ConsumerState<ProjectDetailsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            title: Text(widget.project.name),
            pinned: true,
            floating: true,
            forceElevated: innerBoxIsScrolled,
            actions: [
              IconButton(
                icon: Icon(
                  widget.project.isFavorite ? Icons.star : Icons.star_border,
                  color: widget.project.isFavorite ? Colors.amber : null,
                ),
                onPressed: widget.onToggleFavorite,
                tooltip: widget.project.isFavorite
                    ? 'Убрать из избранного'
                    : 'Добавить в избранное',
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: widget.onEdit,
                tooltip: 'Редактировать',
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_rounded),
                        SizedBox(width: 12),
                        Flexible(child: Text('Поделиться QR кодом')),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded),
                        SizedBox(width: 12),
                        Flexible(child: Text('Экспортировать')),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded),
                        SizedBox(width: 12),
                        Flexible(child: Text('Изменить статус')),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'qr':
                      widget.onShareQR();
                      break;
                    case 'export':
                      widget.onExport();
                      break;
                    case 'status':
                      widget.onChangeStatus();
                      break;
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.calculate_outlined),
                  text: 'Расчёты (${widget.project.calculations.length})',
                ),
                Tab(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  text: 'Материалы (${widget.project.allMaterials.length})',
                ),
                const Tab(
                  icon: Icon(Icons.checklist_rounded),
                  text: 'Чек-листы',
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _CalculationsTab(
            project: widget.project,
            onAddCalculation: widget.onAddCalculation,
            onOpenCalculation: widget.onOpenCalculation,
            onDeleteCalculation: widget.onDeleteCalculation,
          ),
          _MaterialsTab(
            project: widget.project,
            onMaterialToggled: widget.onRefresh,
          ),
          _ChecklistsTab(
            projectId: widget.project.id,
            onRefresh: widget.onRefresh,
          ),
        ],
      ),
    );
  }
}

/// Вкладка с расчётами
class _CalculationsTab extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onAddCalculation;
  final void Function(ProjectCalculation) onOpenCalculation;
  final void Function(ProjectCalculation) onDeleteCalculation;

  const _CalculationsTab({
    required this.project,
    required this.onAddCalculation,
    required this.onOpenCalculation,
    required this.onDeleteCalculation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculations = project.calculations.toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: ProjectInfoCard(project: project)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Text('Расчёты', style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAddCalculation,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Добавить'),
                ),
              ],
            ),
          ),
        ),
        if (calculations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
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
                    'Добавьте первый расчёт',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final calc = calculations[index];
                  return CalculationItemCard(
                    calculation: calc,
                    onTap: () => onOpenCalculation(calc),
                    onDelete: () => onDeleteCalculation(calc),
                  );
                },
                childCount: calculations.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// Вкладка с материалами
class _MaterialsTab extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onMaterialToggled;

  const _MaterialsTab({
    required this.project,
    required this.onMaterialToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: ProjectMaterialsList(
        project: project,
        onMaterialToggled: onMaterialToggled,
      ),
    );
  }
}

/// Вкладка с чек-листами
class _ChecklistsTab extends ConsumerWidget {
  final int projectId;
  final VoidCallback onRefresh;

  const _ChecklistsTab({
    required this.projectId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repository = ref.watch(checklistRepositoryProvider);
    final checklistsAsync = ref.watch(projectChecklistsProvider(projectId));

    return checklistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error'),
      ),
      data: (checklists) => CustomScrollView(
        slivers: [
          // Статистика чек-листов
          SliverToBoxAdapter(
            child: _ChecklistStatsCard(
              projectId: projectId,
              repository: repository,
            ),
          ),
          // Заголовок с кнопкой добавления
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('Чек-листы', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addChecklist(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
            ),
          ),
          // Список чек-листов или пустое состояние
          if (checklists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет чек-листов',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавьте чек-лист для отслеживания работ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addChecklist(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Создать чек-лист'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final checklist = checklists[index];
                    return _ChecklistCard(
                      checklist: checklist,
                      onTap: () => _openChecklist(context, checklist),
                      onDelete: () =>
                          _deleteChecklist(context, ref, checklist),
                    );
                  },
                  childCount: checklists.length,
                ),
              ),
            ),
        ],
      ),
    );
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

    if (result != null) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Чек-лист создан'),
            action: SnackBarAction(
              label: 'Открыть',
              onPressed: () => _openChecklist(context, createdChecklist),
            ),
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

    if (confirm == true) {
      final repository = ref.read(checklistRepositoryProvider);
      await repository.deleteChecklist(checklist.id);
      // StreamProvider автоматически обновится

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Чек-лист удалён')),
        );
      }
    }
  }
}

/// Карточка статистики чек-листов проекта
class _ChecklistStatsCard extends StatelessWidget {
  final int projectId;
  final ChecklistRepository repository;

  const _ChecklistStatsCard({
    required this.projectId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<ChecklistStats>(
      future: repository.getProjectStats(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        if (stats.totalItems == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Прогресс работ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats.completedItems} / ${stats.totalItems}',
                            style: theme.textTheme.headlineSmall?.copyWith(
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
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: stats.progress,
                            strokeWidth: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: _getProgressColor(stats.progress, theme),
                          ),
                          Text(
                            '${stats.progressPercent}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: stats.progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: _getProgressColor(stats.progress, theme),
                ),
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
}

/// Карточка чек-листа
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
      margin: const EdgeInsets.only(bottom: 12),
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
                    child: LinearProgressIndicator(
                      value: checklist.progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
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
