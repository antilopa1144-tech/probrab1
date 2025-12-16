import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/project_v2.dart';
import '../../../domain/models/export_data.dart';
import '../../../domain/services/csv_export_service.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/project_v2_provider.dart';
import '../../utils/calculator_navigation_helper.dart';

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

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  late Future<ProjectV2?> _projectFuture;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  void _loadProject() {
    _projectFuture = _loadProjectWithCalculations();
  }

  Future<ProjectV2?> _loadProjectWithCalculations() async {
    final repository = ref.read(projectRepositoryV2Provider);
    final project = await repository.getProjectById(widget.projectId);
    if (project != null) {
      // Загружаем расчёты проекта
      await project.calculations.load();
    }
    return project;
  }

  void _refreshProject() {
    setState(() {
      _loadProject();
    });
  }

  void _editProjectInfo(ProjectV2 project) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(
      text: project.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название проекта'),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
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
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final updated = ProjectV2()
          ..id = project.id
          ..name = nameController.text.trim()
          ..description = descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim()
          ..createdAt = project.createdAt
          ..updatedAt = DateTime.now()
          ..status = project.status
          ..isFavorite = project.isFavorite
          ..tags = project.tags
          ..color = project.color
          ..notes = project.notes;

        await ref
            .read(projectV2NotifierProvider.notifier)
            .updateProject(updated);
        _refreshProject();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проект обновлён'),
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
            contextMessage: 'Update project info',
          );
        }
      }
    }
  }

  void _changeStatus(ProjectV2 project) async {
    final newStatus = await showDialog<ProjectStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Изменить статус'),
        children: ProjectStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 12),
                Text(_getStatusLabel(status)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (newStatus != null && newStatus != project.status) {
      try {
        final updated = ProjectV2()
          ..id = project.id
          ..name = project.name
          ..description = project.description
          ..createdAt = project.createdAt
          ..updatedAt = DateTime.now()
          ..status = newStatus
          ..isFavorite = project.isFavorite
          ..tags = project.tags
          ..color = project.color
          ..notes = project.notes;

        await ref
            .read(projectV2NotifierProvider.notifier)
            .updateProject(updated);
        _refreshProject();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Статус изменён на "${_getStatusLabel(newStatus)}"',
              ),
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
            contextMessage: 'Change project status',
          );
        }
      }
    }
  }

  void _addCalculation(ProjectV2 project) async {
    final allCalcs = CalculatorRegistry.allCalculators;

    if (allCalcs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступных калькуляторов'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final selectedCalcId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите калькулятор'),
        children: allCalcs.map((calc) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, calc.id),
            child: ListTile(
              leading: const Icon(Icons.calculate_rounded),
              title: Text(calc.titleKey),
              subtitle: Text(calc.descriptionKey ?? ''),
            ),
          );
        }).toList(),
      ),
    );

    if (selectedCalcId != null) {
      final calcDef = CalculatorRegistry.getById(selectedCalcId);
      if (calcDef != null && mounted) {
        // Navigate to calculator screen
        // TODO: After calculation, save results to project
        CalculatorNavigationHelper.navigateToCalculator(context, calcDef);
      }
    }
  }

  void _openCalculation(ProjectCalculation calculation) async {
    // Получаем определение калькулятора
    final calcDef = CalculatorRegistry.getById(calculation.calculatorId);
    if (calcDef == null) {
      // Логируем ошибку в Crashlytics
      try {
        FirebaseCrashlytics.instance.recordError(
          Exception('Calculator not found: ${calculation.calculatorId}'),
          StackTrace.current,
          reason:
              'User attempted to open saved calculation with non-existent calculator',
          information: [
            'calculatorId: ${calculation.calculatorId}',
            'projectId: ${widget.projectId}',
          ],
        );
      } catch (e) {
        // Игнорируем ошибки Firebase, если сервис недоступен
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Калькулятор "${calculation.calculatorId}" не найден',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Открываем калькулятор с предзаполненными данными
    if (mounted) {
      final initialInputs = <String, double>{};
      for (final pair in calculation.inputs) {
        initialInputs[pair.key] = pair.value;
      }
      CalculatorNavigationHelper.navigateToCalculator(
        context,
        calcDef,
        initialInputs: initialInputs,
      );
    }
  }

  void _deleteCalculation(ProjectCalculation calculation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить расчёт?'),
        content: Text(
          'Расчёт "${calculation.name}" будет удалён безвозвратно.',
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
            .read(projectRepositoryV2Provider)
            .removeCalculationFromProject(calculation.id);
        _refreshProject();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Расчёт "${calculation.name}" удалён'),
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
            contextMessage: 'Delete calculation',
          );
        }
      }
    }
  }

  void _exportProject(ProjectV2 project) async {
    try {
      // Создаём данные для экспорта
      final exportCalcs = project.calculations.map((calc) {
        return ExportCalculation(
          calculatorName: calc.name,
          inputs: calc.inputsMap,
          results: calc.resultsMap,
          materialCost: calc.materialCost,
          laborCost: calc.laborCost,
          notes: calc.notes,
        );
      }).toList();

      final exportData = ExportData(
        projectName: project.name,
        projectDescription: project.description,
        createdAt: project.createdAt,
        calculations: exportCalcs,
        totalMaterialCost: project.totalMaterialCost,
        totalLaborCost: project.totalLaborCost,
        totalCost: project.totalCost,
        notes: project.notes,
      );

      // Экспортируем через CSV сервис
      final csvService = CsvExportService();
      await csvService.exportAndShare(exportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект экспортирован'),
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
          contextMessage: 'Export project',
        );
      }
    }
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

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                title: Text(project.name),
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      project.isFavorite ? Icons.star : Icons.star_border,
                      color: project.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => _toggleFavorite(project),
                    tooltip: project.isFavorite
                        ? 'Убрать из избранного'
                        : 'Добавить в избранное',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => _editProjectInfo(project),
                    tooltip: 'Редактировать',
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.share_rounded),
                            SizedBox(width: 12),
                            Text('Экспортировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.flag_rounded),
                            SizedBox(width: 12),
                            Text('Изменить статус'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'export':
                          _exportProject(project);
                          break;
                        case 'status':
                          _changeStatus(project);
                          break;
                      }
                    },
                  ),
                ],
              ),

              // Информация о проекте
              SliverToBoxAdapter(child: _ProjectInfoCard(project: project)),

              // Заголовок расчётов
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Text('Расчёты', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _addCalculation(project),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Добавить'),
                      ),
                    ],
                  ),
                ),
              ),

              // Список расчётов
              if (project.calculations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет расчётов',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте первый расчёт',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final calc = project.calculations.toList()[index];
                      return _CalculationCard(
                        calculation: calc,
                        onTap: () => _openCalculation(calc),
                        onDelete: () => _deleteCalculation(calc),
                      );
                    }, childCount: project.calculations.length),
                  ),
                ),
            ],
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
      _refreshProject();
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

/// Карточка информации о проекте.
class _ProjectInfoCard extends StatelessWidget {
  final ProjectV2 project;

  const _ProjectInfoCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Описание
            if (project.description != null &&
                project.description!.isNotEmpty) ...[
              Text(project.description!, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
            ],

            // Даты
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Создан',
              value: dateFormat.format(project.createdAt),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.update_rounded,
              label: 'Обновлён',
              value: dateFormat.format(project.updatedAt),
            ),

            const Divider(height: 24),

            // Стоимости
            Row(
              children: [
                Expanded(
                  child: _CostColumn(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Материалы',
                    value: project.totalMaterialCost,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _CostColumn(
                    icon: Icons.handyman_outlined,
                    label: 'Работы',
                    value: project.totalLaborCost,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Итого
            // Цены временно скрыты до интеграции с магазинами
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       'Итого:',
            //       style: theme.textTheme.titleLarge?.copyWith(
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     Text(
            //       _formatCurrency(project.totalCost),
            //       style: theme.textTheme.headlineSmall?.copyWith(
            //         fontWeight: FontWeight.bold,
            //         color: theme.colorScheme.primary,
            //       ),
            //     ),
            //   ],
            // ),

            // Теги
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Заметки
            if (project.notes != null && project.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Заметки', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                project.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

/// Строка информации с иконкой.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Колонка со стоимостью.
class _CostColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _CostColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat('#,##0', 'ru_RU');

    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${format.format(value)} ₽',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Карточка расчёта.
class _CalculationCard extends StatelessWidget {
  final ProjectCalculation calculation;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _CalculationCard({
    required this.calculation,
    this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final results = calculation.resultsMap;

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
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calculation.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calculation.calculatorId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                    tooltip: 'Удалить',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Дата
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(calculation.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Основные результаты (первые 3)
              if (results.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...results.entries.take(3).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatResultKey(entry.key),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatResultValue(entry.key, entry.value),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Стоимости (скрыты до интеграции с магазинами)
              // if (calculation.materialCost != null ||
              //     calculation.laborCost != null) ...[
              //   const SizedBox(height: 12),
              //   const Divider(),
              //   const SizedBox(height: 8),
              //   Row(
              //     children: [
              //       if (calculation.materialCost != null)
              //         Expanded(
              //           child: _CostInfo(
              //             label: 'Материалы',
              //             value: calculation.materialCost!,
              //             icon: Icons.shopping_cart_outlined,
              //           ),
              //         ),
              //       if (calculation.materialCost != null &&
              //           calculation.laborCost != null)
              //         const SizedBox(width: 16),
              //       if (calculation.laborCost != null)
              //         Expanded(
              //           child: _CostInfo(
              //             label: 'Работы',
              //             value: calculation.laborCost!,
              //             icon: Icons.handyman_outlined,
              //           ),
              //         ),
              //     ],
              //   ),
              // ],

              // Заметки
              if (calculation.notes != null &&
                  calculation.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  calculation.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Кнопка открыть
              if (onTap != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('button.open_for_recalculation'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatResultKey(String key) {
    // Преобразуем ключ в читаемый формат
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String _formatResultValue(String key, double value) {
    final format = NumberFormat('#,##0.00', 'ru_RU');

    // Определяем единицу измерения по ключу
    if (key.contains('area')) return '${format.format(value)} м²';
    if (key.contains('volume')) return '${format.format(value)} м³';
    if (key.contains('length') || key.contains('perimeter')) {
      return '${format.format(value)} м';
    }
    if (key.contains('kg') || key.contains('weight')) {
      return '${format.format(value)} кг';
    }
    if (key.contains('liters') || key.contains('l')) {
      return '${format.format(value)} л';
    }
    if (key.contains('pieces') ||
        key.contains('pcs') ||
        key.contains('needed')) {
      return '${format.format(value)} шт.';
    }
    if (key.contains('price') || key.contains('cost')) {
      return '${format.format(value)} ₽';
    }

    return format.format(value);
  }
}

/// Информация о стоимости для расчёта (скрыта до интеграции с магазинами).
// class _CostInfo extends StatelessWidget {
//   final String label;
//   final double value;
//   final IconData icon;
//
//   const _CostInfo({
//     required this.label,
//     required this.value,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final format = NumberFormat('#,##0', 'ru_RU');
//
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
//         const SizedBox(width: 4),
//         Text(
//           '$label: ',
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: theme.colorScheme.onSurfaceVariant,
//           ),
//         ),
//         Text(
//           '${format.format(value)} ₽',
//           style: theme.textTheme.bodySmall?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     );
//   }
// }
