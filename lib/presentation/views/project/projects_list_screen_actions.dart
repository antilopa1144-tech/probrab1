part of 'projects_list_screen.dart';

mixin ProjectsListActions on ConsumerState<ProjectsListScreen> {
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

        await ref
            .read(projectV2NotifierProvider.notifier)
            .createProject(project);

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
        await ref
            .read(projectV2NotifierProvider.notifier)
            .deleteProject(project.id);

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

  bool _hasActiveFilters() {
    return _showFavoritesOnly ||
        _filterStatus != null ||
        _searchQuery.isNotEmpty;
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
