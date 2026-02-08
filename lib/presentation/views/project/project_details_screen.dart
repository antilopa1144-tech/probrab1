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

    return FutureBuilder<ProjectV2?>(
      future: _projectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Загрузка...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ошибка')),
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
            ),
          );
        }

        final project = snapshot.data;

        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Проект')),
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
                  Text('Проект не найден', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Назад'),
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
                tooltip: 'Редактировать',
              ),
              // Меню
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
            label: const Text('Добавить расчёт'),
          ),
        );
      },
    );
  }

}
