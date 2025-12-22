import 'package:flutter/material.dart';
import '../../../../domain/models/project_v2.dart';
import 'calculation_item_card.dart';
import 'project_info_card.dart';

/// Основной контент экрана деталей проекта.
class ProjectDetailsContent extends StatelessWidget {
  final ProjectV2 project;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onAddCalculation;
  final VoidCallback onExport;
  final VoidCallback onChangeStatus;
  final void Function(ProjectCalculation) onOpenCalculation;
  final void Function(ProjectCalculation) onDeleteCalculation;

  const ProjectDetailsContent({
    super.key,
    required this.project,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onAddCalculation,
    required this.onExport,
    required this.onChangeStatus,
    required this.onOpenCalculation,
    required this.onDeleteCalculation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculations = project.calculations.toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(project.name),
          pinned: true,
          actions: [
            IconButton(
              icon: Icon(
                project.isFavorite ? Icons.star : Icons.star_border,
                color: project.isFavorite ? Colors.amber : null,
              ),
              onPressed: onToggleFavorite,
              tooltip:
                  project.isFavorite ? 'Убрать из избранного' : 'Добавить в избранное',
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: onEdit,
              tooltip: 'Редактировать',
            ),
            PopupMenuButton(
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded),
                      SizedBox(width: 12),
                      Text('Экспортировать'),
                    ],
                  ),
                ),
                PopupMenuItem(
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
                    onExport();
                    break;
                  case 'status':
                    onChangeStatus();
                    break;
                }
              },
            ),
          ],
        ),
        SliverToBoxAdapter(child: ProjectInfoCard(project: project)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Text('Расчёты', style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAddCalculation,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Добавить'),
                ),
              ],
            ),
          ),
        ),
        if (calculations.isEmpty)
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final calc = calculations[index];
                  return CalculationItemCard(
                    calculation: calc,
                    onTap: () => onOpenCalculation(calc),
                    onDelete: () => onDeleteCalculation(calc),
                  );
                },
                childCount: calculations.length,
              ),
            ),
          ),
      ],
    );
  }
}
