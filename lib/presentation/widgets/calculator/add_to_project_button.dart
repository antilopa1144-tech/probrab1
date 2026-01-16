import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/project_v2.dart';
import '../../providers/project_v2_provider.dart';
import '../../views/project/project_details_screen.dart';
import '../../views/project/project_form_screen.dart';

/// Модель данных расчёта для сохранения в проект
class CalculationData {
  /// ID калькулятора (например, 'putty_calc', 'foundation_slab')
  final String calculatorId;

  /// Название расчёта (например, 'Шпатлёвка - Спальня')
  final String name;

  /// Входные данные как Map<String, double>
  final Map<String, double> inputs;

  /// Результаты расчёта как Map<String, double>
  final Map<String, double> results;

  /// Общая стоимость материалов
  final double? materialCost;

  /// Стоимость работ
  final double? laborCost;

  /// Список материалов (опционально)
  final List<MaterialData>? materials;

  const CalculationData({
    required this.calculatorId,
    required this.name,
    required this.inputs,
    required this.results,
    this.materialCost,
    this.laborCost,
    this.materials,
  });
}

/// Данные материала для сохранения
class MaterialData {
  final String name;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String? sku;

  const MaterialData({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    this.sku,
  });
}

/// Кнопка "Добавить в проект" для калькуляторов.
///
/// Показывает диалог выбора проекта или создания нового.
///
/// Пример использования:
/// ```dart
/// AddToProjectButton(
///   calculationData: CalculationData(
///     calculatorId: 'putty_calc',
///     name: 'Шпатлёвка - Спальня',
///     inputs: {'width': 5.0, 'height': 2.7, 'length': 4.0},
///     results: {'area': 35.9, 'startBags': 2, 'finishBags': 3},
///     materialCost: 5000,
///   ),
///   accentColor: CalculatorColors.interior,
/// )
/// ```
class AddToProjectButton extends ConsumerWidget {
  /// Данные расчёта для сохранения
  final CalculationData calculationData;

  /// Акцентный цвет кнопки
  final Color accentColor;

  /// Callback после успешного сохранения
  final VoidCallback? onSaved;

  const AddToProjectButton({
    super.key,
    required this.calculationData,
    required this.accentColor,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return FilledButton.icon(
      onPressed: () => _showProjectSelector(context, ref, loc),
      icon: const Icon(Icons.folder_outlined, size: 20),
      label: Text(loc.translate('common.add_to_project')),
      style: FilledButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<void> _showProjectSelector(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
  ) async {
    // Загружаем проекты напрямую из репозитория чтобы избежать проблем с state
    final repository = ref.read(projectRepositoryV2Provider);
    List<ProjectV2> projects;
    try {
      projects = await repository.getAllProjects();
    } catch (e) {
      projects = <ProjectV2>[];
    }

    if (!context.mounted) return;

    final result = await showModalBottomSheet<_ProjectSelectorResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProjectSelectorSheet(
        projects: projects,
        loc: loc,
      ),
    );

    if (result == null || !context.mounted) return;

    ProjectV2? targetProject;

    if (result.createNew) {
      // Создать новый проект
      targetProject = await ProjectFormScreen.create(context);
    } else {
      targetProject = result.selectedProject;
    }

    if (targetProject == null || !context.mounted) return;

    // Сохраняем расчёт в проект
    await _saveCalculationToProject(context, ref, targetProject, loc);
  }

  Future<void> _saveCalculationToProject(
    BuildContext context,
    WidgetRef ref,
    ProjectV2 project,
    AppLocalizations loc,
  ) async {
    try {
      final repository = ref.read(projectRepositoryV2Provider);

      // Создаём объект расчёта
      final calculation = ProjectCalculation()
        ..calculatorId = calculationData.calculatorId
        ..name = calculationData.name
        ..materialCost = calculationData.materialCost
        ..laborCost = calculationData.laborCost
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      // Устанавливаем входные данные
      calculation.setInputsFromMap(calculationData.inputs);

      // Устанавливаем результаты
      calculation.setResultsFromMap(calculationData.results);

      // Устанавливаем материалы если есть
      if (calculationData.materials != null) {
        calculation.materials = calculationData.materials!.map((m) {
          final material = ProjectMaterial()
            ..name = m.name
            ..quantity = m.quantity
            ..unit = m.unit
            ..pricePerUnit = m.pricePerUnit
            ..sku = m.sku
            ..calculatorId = calculationData.calculatorId
            ..priority = 3
            ..purchased = false;
          return material;
        }).toList();
      }

      // Сохраняем в проект
      await repository.addCalculationToProject(project.id, calculation);

      // Обновляем список проектов
      ref.invalidate(projectV2NotifierProvider);

      if (context.mounted) {
        // Показываем диалог с выбором действий
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            title: Text(loc.translate('common.calculation_added')),
            content: Text(
              loc.translate('common.calculation_saved_to_project', {'name': project.name}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'continue'),
                child: Text(loc.translate('common.add_more')),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'open'),
                icon: const Icon(Icons.folder_open),
                label: Text(loc.translate('common.open_project')),
              ),
            ],
          ),
        );

        if (result == 'open' && context.mounted) {
          // Переходим к проекту
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(projectId: project.id),
            ),
          );
        }

        onSaved?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('common.error')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Результат выбора проекта
class _ProjectSelectorResult {
  final bool createNew;
  final ProjectV2? selectedProject;

  const _ProjectSelectorResult({
    this.createNew = false,
    this.selectedProject,
  });
}

/// BottomSheet для выбора проекта
class _ProjectSelectorSheet extends StatelessWidget {
  final List<ProjectV2> projects;
  final AppLocalizations loc;

  const _ProjectSelectorSheet({
    required this.projects,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.translate('common.select_project'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Create new button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.add,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  loc.translate('common.create_new_project'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(loc.translate('common.create_new_project_hint')),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    const _ProjectSelectorResult(createNew: true),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Divider with text
            if (projects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        loc.translate('common.or_select_existing'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
                  ],
                ),
              ),

            // Projects list
            Expanded(
              child: projects.isEmpty
                  ? Center(
                      child: Text(
                        loc.translate('common.no_projects'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _ProjectTile(
                          project: project,
                          onTap: () {
                            Navigator.pop(
                              context,
                              _ProjectSelectorResult(selectedProject: project),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Плитка проекта в списке выбора
class _ProjectTile extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final projectColor = project.color != null
        ? Color(project.color!)
        : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: projectColor.withValues(alpha: 0.2),
          child: Icon(
            Icons.business,
            color: projectColor,
            size: 20,
          ),
        ),
        title: Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: project.address != null && project.address!.isNotEmpty
            ? Text(
                project.address!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }
}
