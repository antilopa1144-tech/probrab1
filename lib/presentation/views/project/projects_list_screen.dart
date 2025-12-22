import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/project_v2.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../providers/project_v2_provider.dart';
import 'project_details_screen.dart';
import 'widgets/projects_empty_state.dart';
import 'widgets/projects_list_body.dart';

part 'projects_list_screen_actions.dart';

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

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen>
    with ProjectsListActions {
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
              const PopupMenuItem(value: null, child: Text('Все проекты')),
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
            return ProjectsEmptyState(
              searchQuery: _searchQuery,
              showFavoritesOnly: _showFavoritesOnly,
              filterStatus: _filterStatus,
            );
          }

          return ProjectsListBody(
            projects: projects,
            filtered: filtered,
            showFavoritesOnly: _showFavoritesOnly,
            filterStatus: _filterStatus,
            searchQuery: _searchQuery,
            hasActiveFilters: _hasActiveFilters(),
            onClearFavorites: () {
              setState(() {
                _showFavoritesOnly = false;
              });
            },
            onClearStatus: () {
              setState(() {
                _filterStatus = null;
              });
            },
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            statusLabel: _getStatusLabel,
            statusIcon: _getStatusIcon,
            statusColor: _getStatusColor,
            onOpenProject: _navigateToDetails,
            onDeleteProject: _deleteProject,
            onToggleFavorite: _toggleFavorite,
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
}
