import 'package:flutter/material.dart';
import '../../../../domain/models/project_v2.dart';
import 'dashboard_project_card.dart';

/// Основной список проектов с фильтрами и результатами.
class ProjectsListBody extends StatelessWidget {
  final List<ProjectV2> projects;
  final List<ProjectV2> filtered;
  final bool showFavoritesOnly;
  final ProjectStatus? filterStatus;
  final String searchQuery;
  final bool hasActiveFilters;
  final VoidCallback onClearFavorites;
  final VoidCallback onClearStatus;
  final VoidCallback onClearSearch;
  final String Function(ProjectStatus) statusLabel;
  final IconData Function(ProjectStatus) statusIcon;
  final Color Function(ProjectStatus) statusColor;
  final void Function(ProjectV2) onOpenProject;
  final void Function(ProjectV2) onDeleteProject;
  final void Function(ProjectV2) onToggleFavorite;

  const ProjectsListBody({
    super.key,
    required this.projects,
    required this.filtered,
    required this.showFavoritesOnly,
    required this.filterStatus,
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onClearFavorites,
    required this.onClearStatus,
    required this.onClearSearch,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.onOpenProject,
    required this.onDeleteProject,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (hasActiveFilters)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showFavoritesOnly)
                  Chip(
                    label: const Text('Только избранные'),
                    avatar: const Icon(Icons.star, size: 16),
                    onDeleted: onClearFavorites,
                  ),
                if (filterStatus != null)
                  Chip(
                    label: Text(statusLabel(filterStatus!)),
                    avatar: Icon(
                      statusIcon(filterStatus!),
                      size: 16,
                      color: statusColor(filterStatus!),
                    ),
                    onDeleted: onClearStatus,
                  ),
                if (searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Поиск: "$searchQuery"'),
                    avatar: const Icon(Icons.search, size: 16),
                    onDeleted: onClearSearch,
                  ),
              ],
            ),
          ),
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Найдено: ${filtered.length} из ${projects.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final project = filtered[index];
              return DashboardProjectCard(
                project: project,
                onTap: () => onOpenProject(project),
                onDelete: () => onDeleteProject(project),
                onToggleFavorite: () => onToggleFavorite(project),
              );
            },
          ),
        ),
      ],
    );
  }
}
