import 'package:flutter/material.dart';
import '../components/mat_card.dart';
import '../../domain/entities/object_type.dart';
import '../data/work_catalog.dart';
import '../../core/animations/page_transitions.dart';
import '../../core/localization/app_localizations.dart';
import 'category_selector_screen.dart';

/// Экран выбора типа работ для конкретного объекта (дом/квартира/гараж).
class ObjectSelectorScreen extends StatelessWidget {
  final ObjectType objectType;

  const ObjectSelectorScreen({super.key, required this.objectType});

  String _title(AppLocalizations loc) {
    switch (objectType) {
      case ObjectType.house:
        return loc.translate('workflow.object.home');
      case ObjectType.flat:
        return loc.translate('workflow.object.flat');
      case ObjectType.garage:
        return loc.translate('workflow.object.garage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final areas = WorkCatalog.areasFor(objectType);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(loc)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: areas.isEmpty
            ? Center(
                child: Text(
                  loc.translate('work.screen.no_categories'),
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : GridView.builder(
                itemCount: areas.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final area = areas[index];
                  return MatCardButton(
                    icon: area.icon,
                    title: loc.translate(area.title),
                    subtitle: loc.translate(area.subtitle),
                    backgroundColor: area.color.withValues(alpha: 0.12),
                    iconColor: area.color,
                    onTap: () {
                      Navigator.push(
                        context,
                        ModernPageTransitions.slideRight(
                          CategorySelectorScreen(
                            objectType: objectType,
                            area: area,
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
