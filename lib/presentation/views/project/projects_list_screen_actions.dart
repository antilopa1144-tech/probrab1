part of 'projects_list_screen.dart';

/// Опции сортировки проектов
enum ProjectSortOption {
  custom, // Ручной порядок (drag-and-drop)
  updatedDesc, // По дате изменения (новые сверху)
  updatedAsc, // По дате изменения (старые сверху)
  nameAsc, // По имени (А-Я)
  nameDesc, // По имени (Я-А)
  budgetDesc, // По бюджету (большие сверху)
  progressDesc, // По прогрессу (завершённые сверху)
  deadlineAsc, // По дедлайну (ближайшие сверху)
}

mixin ProjectsListActions on ConsumerState<ProjectsListScreen> {
  ProjectStatus? _filterStatus;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  ProjectSortOption _sortOption = ProjectSortOption.updatedDesc;
  List<int> _customOrder = [];
  final _searchController = TextEditingController();

  // Selection mode
  bool _isSelectionMode = false;
  final Set<int> _selectedProjectIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Обработчик перетаскивания для изменения порядка
  void _onReorder(int oldIndex, int newIndex, List<ProjectV2> projects) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = projects.removeAt(oldIndex);
      projects.insert(newIndex, item);
      _customOrder = projects.map((p) => p.id).toList();
      _sortOption = ProjectSortOption.custom;
    });
    _saveCustomOrder();
  }

  /// Сохранить кастомный порядок
  Future<void> _saveCustomOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'projects_custom_order',
      _customOrder.map((id) => id.toString()).toList(),
    );
  }

  /// Загрузить кастомный порядок
  Future<void> _loadCustomOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderStrings = prefs.getStringList('projects_custom_order');
    if (orderStrings != null) {
      setState(() {
        _customOrder = orderStrings.map((s) => int.tryParse(s) ?? 0).toList();
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Selection Mode Methods
  // ─────────────────────────────────────────────────────────────────

  /// Включить/выключить режим выбора
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProjectIds.clear();
      }
    });
  }

  /// Выбрать/снять выбор с проекта
  void _toggleProjectSelection(int projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
        if (_selectedProjectIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProjectIds.add(projectId);
      }
    });
  }

  /// Выбрать все проекты
  void _selectAllProjects(List<ProjectV2> projects) {
    setState(() {
      _selectedProjectIds.addAll(projects.map((p) => p.id));
    });
  }

  /// Снять выбор со всех
  void _deselectAll() {
    setState(() {
      _selectedProjectIds.clear();
      _isSelectionMode = false;
    });
  }

  /// Показать меню групповых действий
  void _showBulkActionsSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final count = _selectedProjectIds.length;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.translate('project.bulk.title', {'count': count.toString()}),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(loc.translate('project.bulk.delete')),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                _bulkDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(loc.translate('project.bulk.change_status')),
              onTap: () {
                Navigator.pop(context);
                _showBulkStatusChangeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: Text(loc.translate('project.bulk.add_favorites')),
              onTap: () {
                Navigator.pop(context);
                _bulkAddToFavorites();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border_rounded),
              title: Text(loc.translate('project.bulk.remove_favorites')),
              onTap: () {
                Navigator.pop(context);
                _bulkRemoveFromFavorites();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Массовое удаление
  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('project.bulk.delete_confirm_title')),
        content: Text(
          AppLocalizations.of(context).translate(
            'project.bulk.delete_confirm_message',
            {'count': _selectedProjectIds.length.toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('button.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context).translate('button.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(projectV2NotifierProvider.notifier);
        for (final id in _selectedProjectIds) {
          await notifier.deleteProject(id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate(
                'project.bulk.deleted',
                {'count': _selectedProjectIds.length.toString()},
              )),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        _deselectAll();
      } catch (e, stack) {
        if (mounted) {
          GlobalErrorHandler.handle(context, e, stackTrace: stack);
        }
      }
    }
  }

  /// Диалог массового изменения статуса
  void _showBulkStatusChangeDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('project.bulk.change_status')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProjectStatus.values.map((status) {
            return ListTile(
              leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
              title: Text(_getStatusLabel(status)),
              onTap: () {
                Navigator.pop(context);
                _bulkChangeStatus(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Массовое изменение статуса
  Future<void> _bulkChangeStatus(ProjectStatus newStatus) async {
    try {
      final notifier = ref.read(projectV2NotifierProvider.notifier);
      final projects = ref.read(allProjectsProvider).valueOrNull ?? [];

      for (final id in _selectedProjectIds) {
        final project = projects.firstWhere((p) => p.id == id);
        final updated = ProjectV2()
          ..id = project.id
          ..name = project.name
          ..description = project.description
          ..address = project.address
          ..thumbnailUrl = project.thumbnailUrl
          ..createdAt = project.createdAt
          ..updatedAt = DateTime.now()
          ..deadline = project.deadline
          ..budgetTotal = project.budgetTotal
          ..budgetSpent = project.budgetSpent
          ..tasksTotal = project.tasksTotal
          ..tasksCompleted = project.tasksCompleted
          ..status = newStatus
          ..isFavorite = project.isFavorite
          ..tags = project.tags
          ..color = project.color
          ..notes = project.notes;

        await notifier.updateProject(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate(
              'project.bulk.status_changed',
              {'count': _selectedProjectIds.length.toString()},
            )),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _deselectAll();
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(context, e, stackTrace: stack);
      }
    }
  }

  /// Массовое добавление в избранное
  Future<void> _bulkAddToFavorites() async {
    await _bulkToggleFavorite(true);
  }

  /// Массовое удаление из избранного
  Future<void> _bulkRemoveFromFavorites() async {
    await _bulkToggleFavorite(false);
  }

  /// Массовое изменение избранного
  Future<void> _bulkToggleFavorite(bool isFavorite) async {
    try {
      final notifier = ref.read(projectV2NotifierProvider.notifier);
      final projects = ref.read(allProjectsProvider).valueOrNull ?? [];

      for (final id in _selectedProjectIds) {
        final project = projects.firstWhere((p) => p.id == id);
        final updated = ProjectV2()
          ..id = project.id
          ..name = project.name
          ..description = project.description
          ..address = project.address
          ..thumbnailUrl = project.thumbnailUrl
          ..createdAt = project.createdAt
          ..updatedAt = DateTime.now()
          ..deadline = project.deadline
          ..budgetTotal = project.budgetTotal
          ..budgetSpent = project.budgetSpent
          ..tasksTotal = project.tasksTotal
          ..tasksCompleted = project.tasksCompleted
          ..status = project.status
          ..isFavorite = isFavorite
          ..tags = project.tags
          ..color = project.color
          ..notes = project.notes;

        await notifier.updateProject(updated);
      }

      if (mounted) {
        final key = isFavorite ? 'project.bulk.added_favorites' : 'project.bulk.removed_favorites';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate(
              key,
              {'count': _selectedProjectIds.length.toString()},
            )),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _deselectAll();
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(context, e, stackTrace: stack);
      }
    }
  }

  void _createNewProject() async {
    final project = await ProjectFormScreen.create(context);

    if (project != null && mounted) {
      // Автоматически открываем созданный проект
      _navigateToDetails(project);
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
        ..address = project.address
        ..thumbnailUrl = project.thumbnailUrl
        ..createdAt = project.createdAt
        ..updatedAt = DateTime.now()
        ..deadline = project.deadline
        ..budgetTotal = project.budgetTotal
        ..budgetSpent = project.budgetSpent
        ..tasksTotal = project.tasksTotal
        ..tasksCompleted = project.tasksCompleted
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
    var filtered = projects.toList();

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
            (p.address?.toLowerCase().contains(query) ?? false) ||
            p.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Сортировка
    filtered = _sortProjects(filtered);

    return filtered;
  }

  List<ProjectV2> _sortProjects(List<ProjectV2> projects) {
    switch (_sortOption) {
      case ProjectSortOption.custom:
        // Ручной порядок - сортируем по сохранённому порядку ID
        return _sortByCustomOrder(projects);
      case ProjectSortOption.updatedDesc:
        return projects..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case ProjectSortOption.updatedAsc:
        return projects..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case ProjectSortOption.nameAsc:
        return projects
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ProjectSortOption.nameDesc:
        return projects
          ..sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case ProjectSortOption.budgetDesc:
        return projects..sort((a, b) => b.budgetTotal.compareTo(a.budgetTotal));
      case ProjectSortOption.progressDesc:
        return projects..sort((a, b) => b.progress.compareTo(a.progress));
      case ProjectSortOption.deadlineAsc:
        return projects..sort((a, b) {
            // Проекты без дедлайна в конец
            if (a.deadline == null && b.deadline == null) return 0;
            if (a.deadline == null) return 1;
            if (b.deadline == null) return -1;
            return a.deadline!.compareTo(b.deadline!);
          });
    }
  }

  List<ProjectV2> _sortByCustomOrder(List<ProjectV2> projects) {
    if (_customOrder.isEmpty) {
      return projects;
    }
    final orderMap = <int, int>{};
    for (int i = 0; i < _customOrder.length; i++) {
      orderMap[_customOrder[i]] = i;
    }
    return projects..sort((a, b) {
        final orderA = orderMap[a.id] ?? 999999;
        final orderB = orderMap[b.id] ?? 999999;
        return orderA.compareTo(orderB);
      });
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
        return 'Приостановлен';
      case ProjectStatus.completed:
        return 'Завершён';
      case ProjectStatus.cancelled:
        return 'Отменён';
      case ProjectStatus.problem:
        return 'Проблема';
    }
  }

  void _scanQRCode() async {
    if (mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScanScreen(),
        ),
      );

      // Если QR код успешно отсканирован и проект импортирован
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект успешно импортирован'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Обновить список проектов
        ref.invalidate(allProjectsProvider);
      }
    }
  }

}
