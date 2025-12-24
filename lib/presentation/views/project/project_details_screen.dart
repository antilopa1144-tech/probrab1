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
import '../../utils/calculator_navigation_helper.dart';
import 'widgets/project_details_content.dart';

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

    return Scaffold(
      body: FutureBuilder<ProjectV2?>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
                    'Ошибка загрузки проекта',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _refreshProject,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final project = snapshot.data;

          if (project == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_rounded,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text('Проект не найден', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Назад'),
                  ),
                ],
              ),
            );
          }

          return ProjectDetailsContent(
            project: project,
            onToggleFavorite: () => _toggleFavorite(project),
            onEdit: () => _editProjectInfo(project),
            onAddCalculation: () => _addCalculation(project),
            onExport: () => _exportProject(project),
            onChangeStatus: () => _changeStatus(project),
            onOpenCalculation: _openCalculation,
            onDeleteCalculation: _deleteCalculation,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final project = await _projectFuture;
          if (project != null) {
            _addCalculation(project);
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

}
