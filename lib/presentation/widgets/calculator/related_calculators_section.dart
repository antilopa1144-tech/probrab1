import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_link.dart';
import '../../utils/calculator_navigation_helper.dart';

/// Секция «Связанные калькуляторы» после результатов.
///
/// Отображает кнопки-ссылки на связанные калькуляторы.
/// При нажатии открывает целевой калькулятор с предзаполненными данными.
class RelatedCalculatorsSection extends StatelessWidget {
  final List<CalculatorLink> links;
  final Map<String, double> results;
  final Map<String, double> inputs;

  const RelatedCalculatorsSection({
    super.key,
    required this.links,
    required this.results,
    required this.inputs,
  });

  @override
  Widget build(BuildContext context) {
    final visibleLinks = links.where((l) => l.shouldShow(results)).toList();
    if (visibleLinks.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              loc.translate('related_calculators.title'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextSecondary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleLinks.map((link) {
              return FilledButton.tonalIcon(
                onPressed: () {
                  final targetInputs = link.buildTargetInputs(results, inputs);
                  CalculatorNavigationHelper.navigateToCalculatorById(
                    context,
                    link.targetId,
                    initialInputs: targetInputs,
                    checkPremium: false,
                  );
                },
                icon: Icon(_resolveIcon(link.iconName), size: 18),
                label: Text(
                  loc.translate(link.labelKey),
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _resolveIcon(String? iconName) {
    return switch (iconName) {
      'texture' => Icons.texture,
      'format_paint' => Icons.format_paint,
      'brush' => Icons.brush,
      'wallpaper' => Icons.wallpaper,
      'imagesearch_roller' => Icons.imagesearch_roller,
      'layers' => Icons.layers,
      'grid_on' => Icons.grid_on,
      _ => Icons.calculate_outlined,
    };
  }
}
