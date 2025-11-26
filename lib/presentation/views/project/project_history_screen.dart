import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/project.dart';
import '../../providers/project_provider.dart';

/// Экран истории проектов.
class ProjectHistoryScreen extends ConsumerWidget {
  const ProjectHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проекты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateProjectDialog(context, ref),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) => projects.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_outlined, size: 64),
                    const SizedBox(height: 16),
                    const Text('Нет проектов'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showCreateProjectDialog(context, ref),
                      child: const Text('Создать проект'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  final project = projects[index];
                return RepaintBoundary(
                  child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        _getObjectIcon(project.objectType),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(project.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.description),
                        const SizedBox(height: 4),
                        Text(
                          'Бюджет: ${project.totalBudget.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Расчётов: ${project.calculationIds.length}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('Открыть'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'view') {
                          // Открыть детали проекта
                        } else if (value == 'delete') {
                          ref.read(projectProvider.notifier).deleteProject(project.id);
                        }
                      },
                    ),
                    onTap: () {
                      // Открыть детали проекта
                    },
                  ),
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки проектов: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(projectProvider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getObjectIcon(String objectType) {
    switch (objectType) {
      case 'дом':
      case 'home':
        return Icons.house;
      case 'квартира':
      case 'flat':
        return Icons.apartment;
      case 'гараж':
      case 'garage':
        return Icons.garage;
      default:
        return Icons.home;
    }
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'дом';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать проект'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'дом', child: Text('Дом')),
                DropdownMenuItem(value: 'квартира', child: Text('Квартира')),
                DropdownMenuItem(value: 'гараж', child: Text('Гараж')),
              ],
              onChanged: (value) => selectedType = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final project = Project(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                description: descController.text,
                objectType: selectedType,
                createdAt: DateTime.now(),
              );
              ref.read(projectProvider.notifier).addProject(project);
              Navigator.pop(context);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}

