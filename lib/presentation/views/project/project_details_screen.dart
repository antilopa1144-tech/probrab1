import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/project_v2.dart';
import '../../../domain/models/export_data.dart';
import '../../../domain/services/csv_export_service.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../providers/project_v2_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../services/pdf_file_handler.dart';
import '../../utils/calculator_navigation_helper.dart';
import 'widgets/project_details_content.dart';
import 'qr_share_screen.dart';

part 'project_details_screen_actions.dart';

/// Экран деталей проекта.
///
/// Функции:
/// - Просмотр информации о проекте
/// - Список расчётов проекта
/// - Добавление новых расчётов
/// - Редактирование расчётов
/// - Удаление расчётов
/// - Изменение статуса проекта
/// - Экспорт проекта в CSV
class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final int projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen>
    with ProjectDetailsActions {
  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return FutureBuilder<ProjectV2?>(
      future: _projectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.translate('common.loading'))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.translate('common.error'))),
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
                    loc.translate('project.error.loading_project'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _refreshProject,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(loc.translate('button.retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final project = snapshot.data;

        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.translate('project.title'))),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_rounded,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(loc.translate('project.not_found'), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.translate('button.back')),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              // Избранное
              IconButton(
                icon: Icon(
                  project.isFavorite ? Icons.star : Icons.star_border,
                  color: project.isFavorite ? Colors.amber : null,
                ),
                onPressed: () => _toggleFavorite(project),
                tooltip: project.isFavorite
                    ? AppLocalizations.of(context).translate('favorites.remove')
                    : AppLocalizations.of(context).translate('favorites.add'),
              ),
              // Редактировать
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _editProjectInfo(project),
                tooltip: AppLocalizations.of(context).translate('button.edit'),
              ),
              // Меню
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_rounded),
                        const SizedBox(width: 12),
                        Flexible(child: Text(loc.translate('project.share_project'))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        const Icon(Icons.share_rounded),
                        const SizedBox(width: 12),
                        Flexible(child: Text(loc.translate('project.export'))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        const Icon(Icons.flag_rounded),
                        const SizedBox(width: 12),
                        Flexible(child: Text(loc.translate('project.change_status'))),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'qr':
                      _shareViaQR(project);
                      break;
                    case 'export':
                      _showExportOptions(project);
                      break;
                    case 'status':
                      _changeStatus(project);
                      break;
                  }
                },
              ),
            ],
          ),
          body: ProjectDetailsContent(
            project: project,
            onAddCalculation: () => _addCalculation(project),
            onOpenCalculation: _openCalculation,
            onDeleteCalculation: _deleteCalculation,
            onMaterialToggled: _refreshProject,
            onRefresh: _refreshProject,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addCalculation(project),
            icon: const Icon(Icons.add_rounded),
            label: Text(loc.translate('project.add_calculation')),
          ),
        );
      },
    );
  }

}
