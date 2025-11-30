import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/project_v2.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../providers/project_v2_provider.dart';
import 'project_details_screen.dart';

/// Экран списка проектов.
///
/// Функции:
/// - Отображение всех проектов
/// - Фильтрация по статусу и избранным
/// - Поиск по названию
/// - Создание нового проекта
/// - Навигация к деталям проекта
/// - Удаление проектов
class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  ProjectStatus? _filterStatus;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNewProject() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название проекта',
                hintText: 'Например: Ремонт квартиры',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (опционально)',
                hintText: 'Краткое описание проекта',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final project = ProjectV2()
          ..name = nameController.text.trim()
          ..description = descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim()
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..status = ProjectStatus.planning;

        await ref.read(projectV2NotifierProvider.notifier).createProject(project);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Проект "${project.name}" создан'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        if (mounted) {
          GlobalErrorHandler.handle(
            context,
            e,
            stackTrace: stack,
            contextMessage: 'Create project',
          );
        }
      }
    }
  }

  void _deleteProject(ProjectV2 project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: Text(
          'Проект "${project.name}" и все его расчёты будут удалены безвозвратно.',
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

    if (confirmed == true) {
      try {
        await ref.read(projectV2NotifierProvider.notifier).deleteProject(project.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Проект "${project.name}" удалён'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stack) {
        if (mounted) {
          GlobalErrorHandler.handle(
            context,
            e,
            stackTrace: stack,
            contextMessage: 'Delete project',
          );
        }
      }
    }
  }

  void _toggleFavorite(ProjectV2 project) async {
    try {
      final updated = ProjectV2()
        ..id = project.id
        ..name = project.name
        ..description = project.description
        ..createdAt = project.createdAt
        ..updatedAt = DateTime.now()
        ..status = project.status
        ..isFavorite = !project.isFavorite
        ..tags = project.tags
        ..color = project.color
        ..notes = project.notes;

      await ref.read(projectV2NotifierProvider.notifier).updateProject(updated);
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Toggle favorite',
        );
      }
    }
  }

  List<ProjectV2> _filterProjects(List<ProjectV2> projects) {
    var filtered = projects;

    // Фильтр по избранным
    if (_showFavoritesOnly) {
      filtered = filtered.where((p) => p.isFavorite).toList();
    }

    // Фильтр по статусу
    if (_filterStatus != null) {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }

    // Поиск
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false) ||
            p.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проекты'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? Colors.amber : null,
            ),
            tooltip: 'Только избранные',
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
          ),
          PopupMenuButton<ProjectStatus?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Фильтр по статусу',
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Все проекты'),
              ),
              const PopupMenuDivider(),
              ...ProjectStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 20,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 12),
                      Text(_getStatusLabel(status)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Поиск проектов...',
              leading: const Icon(Icons.search_rounded),
              trailing: _searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    ]
                  : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: projectsAsync.when(
        data: (projects) {
          final filtered = _filterProjects(projects);

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final project = filtered[index];
              return _ProjectCard(
                project: project,
                onTap: () => _navigateToDetails(project),
                onDelete: () => _deleteProject(project),
                onToggleFavorite: () => _toggleFavorite(project),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                'Ошибка загрузки проектов',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(allProjectsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProject,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Новый проект'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'Проекты не найдены';
      icon = Icons.search_off_rounded;
    } else if (_showFavoritesOnly) {
      message = 'Нет избранных проектов';
      icon = Icons.star_border_rounded;
    } else if (_filterStatus != null) {
      message = 'Нет проектов с этим статусом';
      icon = Icons.filter_list_off_rounded;
    } else {
      message = 'Нет проектов';
      icon = Icons.folder_open_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_searchQuery.isEmpty && !_showFavoritesOnly && _filterStatus == null) ...[
            const SizedBox(height: 8),
            Text(
              'Создайте первый проект',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetails(ProjectV2 project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(projectId: project.id),
      ),
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
    }
  }

  String _getStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return 'Планирование';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.onHold:
        return 'Приостановлен';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
    }
  }
}

/// Карточка проекта в списке.
class _ProjectCard extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

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
              // Заголовок с избранным
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      project.isFavorite ? Icons.star : Icons.star_border,
                      color: project.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: project.isFavorite
                        ? 'Убрать из избранного'
                        : 'Добавить в избранное',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                    tooltip: 'Удалить проект',
                  ),
                ],
              ),

              // Описание
              if (project.description != null && project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Статус и даты
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(status: project.status),
                  Chip(
                    avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(dateFormat.format(project.createdAt)),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (project.tags.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.label_outline_rounded, size: 16),
                      label: Text(project.tags.first),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Стоимости
              Row(
                children: [
                  Expanded(
                    child: _CostInfo(
                      label: 'Материалы',
                      value: project.totalMaterialCost,
                      icon: Icons.shopping_cart_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CostInfo(
                      label: 'Работы',
                      value: project.totalLaborCost,
                      icon: Icons.handyman_outlined,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Итого
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Итого:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency(project.totalCost),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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

  String _formatCurrency(double value) {
    final format = NumberFormat('#,##0.00', 'ru_RU');
    return '${format.format(value)} ₽';
  }
}

/// Чип статуса проекта.
class _StatusChip extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_getIcon(), size: 16),
      label: Text(_getLabel()),
      backgroundColor: _getColor().withValues(alpha: 0.1),
      side: BorderSide(color: _getColor()),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getIcon() {
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
    }
  }

  Color _getColor() {
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
    }
  }

  String _getLabel() {
    switch (status) {
      case ProjectStatus.planning:
        return 'Планирование';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.onHold:
        return 'Приостановлен';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
    }
  }
}

/// Информация о стоимости.
class _CostInfo extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _CostInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat('#,##0', 'ru_RU');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${format.format(value)} ₽',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
