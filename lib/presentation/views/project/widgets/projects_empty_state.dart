import 'package:flutter/material.dart';
import '../../../../domain/models/project_v2.dart';
import '../../../../core/localization/app_localizations.dart';

/// Пустое состояние для списка проектов.
class ProjectsEmptyState extends StatelessWidget {
  final String searchQuery;
  final bool showFavoritesOnly;
  final ProjectStatus? filterStatus;

  const ProjectsEmptyState({
    super.key,
    required this.searchQuery,
    required this.showFavoritesOnly,
    required this.filterStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    String message;
    IconData icon;

    if (searchQuery.isNotEmpty) {
      message = loc.translate('project.empty.not_found');
      icon = Icons.search_off_rounded;
    } else if (showFavoritesOnly) {
      message = loc.translate('project.empty.no_favorites');
      icon = Icons.star_border_rounded;
    } else if (filterStatus != null) {
      message = loc.translate('project.empty.no_status');
      icon = Icons.filter_list_off_rounded;
    } else {
      message = loc.translate('project.empty.none');
      icon = Icons.folder_open_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (searchQuery.isEmpty &&
              !showFavoritesOnly &&
              filterStatus == null) ...[
            const SizedBox(height: 8),
            Text(
              loc.translate('project.empty.create_first'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

