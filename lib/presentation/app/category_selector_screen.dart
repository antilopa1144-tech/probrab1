import 'package:flutter/material.dart';

import '../../domain/entities/object_type.dart';
import '../components/mat_card.dart';
import '../data/work_catalog.dart';
import '../../core/animations/page_transitions.dart';
import 'work_items_screen.dart';

/// Экран, отображающий разделы выбранной категории работ
/// (например: Внутренняя отделка → Стены / Потолки / Полы).
class CategorySelectorScreen extends StatelessWidget {
  final ObjectType objectType;
  final WorkAreaDefinition area;

  const CategorySelectorScreen({
    super.key,
    required this.objectType,
    required this.area,
  });

  @override
  Widget build(BuildContext context) {
    final sections = area.sections;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(area.title),
            Text(
              area.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final section = sections[index];
            return MatCardButton(
              icon: section.icon,
              title: section.title,
              subtitle: section.description,
              onTap: () {
                Navigator.push(
                  context,
                  ModernPageTransitions.slideRight(
                    WorkItemsScreen(
                      objectType: objectType,
                      area: area,
                      section: section,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

