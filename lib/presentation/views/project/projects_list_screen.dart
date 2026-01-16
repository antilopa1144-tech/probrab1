import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/project_v2.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/project_v2_provider.dart';
import 'project_details_screen.dart';
import 'project_form_screen.dart';
import 'qr_scan_screen.dart';
import 'widgets/projects_empty_state.dart';
import 'widgets/dashboard_project_card.dart';

part 'projects_list_screen_actions.dart';

/// Экран списка проектов в стиле Dashboard.
///
/// Функции:
/// - Отображение всех проектов в современном Dashboard UI
/// - Предупреждение о проблемных проектах
/// - Фильтрация по статусу через FilterChips
/// - Поиск по названию, адресу, тегам
/// - Сортировка проектов
/// - Создание нового проекта
/// - Навигация к деталям проекта
/// - Удаление проектов
class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen>
    with ProjectsListActions {
  @override
  void initState() {
    super.initState();
    _loadCustomOrder();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      body: projectsAsync.when(
        data: (projects) => _buildDashboard(context, projects),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProject,
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.translate('project.list.new_project')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<ProjectV2> projects) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final filtered = _filterProjects(projects);
    final problemProjects = projects.where((p) => p.hasProblems || p.needsAttention).toList();

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar.large(
          title: Text(_isSelectionMode
              ? loc.translate('project.bulk.selected', {'count': _selectedProjectIds.length.toString()})
              : loc.translate('project.list.title')),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _deselectAll,
                  tooltip: loc.translate('button.cancel'),
                )
              : null,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded),
                    onPressed: () => _selectAllProjects(projects),
                    tooltip: loc.translate('project.bulk.select_all'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showBulkActionsSheet(context),
                    tooltip: loc.translate('project.bulk.actions'),
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    onPressed: _toggleSelectionMode,
                    tooltip: loc.translate('project.bulk.select'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: _scanQRCode,
                    tooltip: loc.translate('project.qr.scan'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    onPressed: () => _showSortOptions(context),
                    tooltip: loc.translate('project.sort.title'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () => _showFilterSheet(context),
                    tooltip: loc.translate('project.filter.title'),
                  ),
                ],
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: loc.translate('project.search.hint'),
              leading: const Icon(Icons.search_rounded),
              trailing: _searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ]
                  : null,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        // Problem Projects Alert
        if (problemProjects.isNotEmpty && !_hasActiveFilters())
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _ProblemProjectsAlert(
                count: problemProjects.length,
                onShowProblems: () {
                  setState(() => _filterStatus = ProjectStatus.problem);
                },
              ),
            ),
          ),

        // Filter Chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusFilterChip(
                    label: loc.translate('project.filter.all'),
                    count: projects.length,
                    isSelected: _filterStatus == null && !_showFavoritesOnly,
                    onSelected: () => setState(() {
                      _filterStatus = null;
                      _showFavoritesOnly = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _StatusFilterChip(
                    label: loc.translate('project.filter.favorites'),
                    count: projects.where((p) => p.isFavorite).length,
                    color: Colors.amber,
                    icon: Icons.star_rounded,
                    isSelected: _showFavoritesOnly,
                    onSelected: () => setState(() {
                      _showFavoritesOnly = !_showFavoritesOnly;
                      if (_showFavoritesOnly) _filterStatus = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  ...ProjectStatus.values.map((status) {
                    final count = projects.where((p) => p.status == status).length;
                    if (count == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StatusFilterChip(
                        label: _getStatusLabel(status),
                        count: count,
                        color: _getStatusColor(status),
                        isSelected: _filterStatus == status,
                        onSelected: () => setState(() {
                          _filterStatus = _filterStatus == status ? null : status;
                          _showFavoritesOnly = false;
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        // Results Count
        if (_hasActiveFilters())
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${loc.translate('project.filter.found')}: ${filtered.length} ${loc.translate('project.filter.of')} ${projects.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(loc.translate('project.filter.clear')),
                  ),
                ],
              ),
            ),
          ),

        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  _filterStatus == null
                      ? loc.translate('project.dashboard.all_projects')
                      : _getStatusLabel(_filterStatus!),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Projects List
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ProjectsEmptyState(
              searchQuery: _searchQuery,
              showFavoritesOnly: _showFavoritesOnly,
              filterStatus: _filterStatus,
            ),
          )
        else if (_sortOption == ProjectSortOption.custom && !_hasActiveFilters() && !_isSelectionMode)
          // Reorderable list для ручной сортировки
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverReorderableList(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final project = filtered[index];
                return ReorderableDragStartListener(
                  key: ValueKey(project.id),
                  index: index,
                  child: DashboardProjectCard(
                    project: project,
                    onTap: () => _navigateToDetails(project),
                    onDelete: () => _deleteProject(project),
                    onToggleFavorite: () => _toggleFavorite(project),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) =>
                  _onReorder(oldIndex, newIndex, filtered),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final project = filtered[index];
                  final isSelected = _selectedProjectIds.contains(project.id);

                  return _isSelectionMode
                      ? _SelectableProjectCard(
                          key: ValueKey(project.id),
                          project: project,
                          isSelected: isSelected,
                          onTap: () => _toggleProjectSelection(project.id),
                          onLongPress: null,
                        )
                      : GestureDetector(
                          onLongPress: () {
                            _toggleSelectionMode();
                            _toggleProjectSelection(project.id);
                          },
                          child: DashboardProjectCard(
                            key: ValueKey(project.id),
                            project: project,
                            onTap: () => _navigateToDetails(project),
                            onDelete: () => _deleteProject(project),
                            onToggleFavorite: () => _toggleFavorite(project),
                          ),
                        );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Center(
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
            loc.translate('project.error.loading'),
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
            label: Text(loc.translate('button.retry')),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.translate('project.sort.title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.drag_handle_rounded),
              title: Text(loc.translate('project.sort.custom')),
              subtitle: Text(loc.translate('project.sort.custom_hint')),
              selected: _sortOption == ProjectSortOption.custom,
              onTap: () {
                setState(() => _sortOption = ProjectSortOption.custom);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: Text(loc.translate('project.sort.updated_desc')),
              selected: _sortOption == ProjectSortOption.updatedDesc,
              onTap: () {
                setState(() => _sortOption = ProjectSortOption.updatedDesc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded),
              title: Text(loc.translate('project.sort.name_asc')),
              selected: _sortOption == ProjectSortOption.nameAsc,
              onTap: () {
                setState(() => _sortOption = ProjectSortOption.nameAsc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money_rounded),
              title: Text(loc.translate('project.sort.budget_desc')),
              selected: _sortOption == ProjectSortOption.budgetDesc,
              onTap: () {
                setState(() => _sortOption = ProjectSortOption.budgetDesc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up_rounded),
              title: Text(loc.translate('project.sort.progress_desc')),
              selected: _sortOption == ProjectSortOption.progressDesc,
              onTap: () {
                setState(() => _sortOption = ProjectSortOption.progressDesc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_rounded),
              title: Text(loc.translate('project.sort.deadline_asc')),
              selected: _sortOption == ProjectSortOption.deadlineAsc,
              onTap: () {
                setState(() => _sortOption = ProjectSortOption.deadlineAsc);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('project.filter.title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(loc.translate('project.filter.all')),
                    selected: _filterStatus == null && !_showFavoritesOnly,
                    onSelected: (_) {
                      setState(() {
                        _filterStatus = null;
                        _showFavoritesOnly = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.star_rounded, size: 18),
                    label: Text(loc.translate('project.filter.favorites')),
                    selected: _showFavoritesOnly,
                    onSelected: (_) {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                        _filterStatus = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ...ProjectStatus.values.map(
                    (status) => FilterChip(
                      label: Text(_getStatusLabel(status)),
                      selected: _filterStatus == status,
                      onSelected: (_) {
                        setState(() {
                          _filterStatus = status;
                          _showFavoritesOnly = false;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterStatus = null;
      _showFavoritesOnly = false;
    });
  }
}

/// Алерт о проблемных проектах
class _ProblemProjectsAlert extends StatelessWidget {
  final int count;
  final VoidCallback onShowProblems;

  const _ProblemProjectsAlert({
    required this.count,
    required this.onShowProblems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${_getProjectWord(count)} ${loc.translate('project.dashboard.needs_attention')}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    loc.translate('project.dashboard.problems_description'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onShowProblems,
              child: Text(loc.translate('button.show')),
            ),
          ],
        ),
      ),
    );
  }

  String _getProjectWord(int count) {
    if (count == 1) return 'проект';
    if (count >= 2 && count <= 4) return 'проекта';
    return 'проектов';
  }
}

/// Чип фильтра по статусу
class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    this.color,
    this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      avatar: icon != null ? Icon(icon, size: 18) : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                  : chipColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.onPrimary : chipColor,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor,
      checkmarkColor: theme.colorScheme.onPrimary,
    );
  }
}

/// Карточка проекта с возможностью выбора
class _SelectableProjectCard extends StatelessWidget {
  final ProjectV2 project;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SelectableProjectCard({
    super.key,
    required this.project,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Project info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.address != null && project.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.address!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(project.status),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(project.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
