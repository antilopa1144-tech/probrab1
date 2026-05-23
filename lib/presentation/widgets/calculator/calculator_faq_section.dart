import 'package:flutter/material.dart';

import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/calculator_colors.dart';

class CalculatorFaqItem {
  final String question;
  final String answer;

  const CalculatorFaqItem({required this.question, required this.answer});
}

class CalculatorFaqSection extends StatelessWidget {
  final String? title;
  final List<CalculatorFaqItem> items;
  final Color accentColor;

  const CalculatorFaqSection({
    super.key,
    required this.items,
    required this.accentColor,
    this.title,
  });

  static List<CalculatorFaqItem> fromLocalization({
    required AppLocalizations loc,
    required String prefix,
    int maxItems = 8,
  }) {
    final items = <CalculatorFaqItem>[];

    for (var i = 1; i <= maxItems; i++) {
      final qKey = '$prefix.q$i';
      final aKey = '$prefix.a$i';

      final q = loc.translate(qKey);
      final a = loc.translate(aKey);

      // If keys are missing, AppLocalizations обычно возвращает сам ключ.
      if (q == qKey || a == aKey) break;
      if (q.trim().isEmpty || a.trim().isEmpty) break;

      items.add(CalculatorFaqItem(question: q, answer: a));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CalculatorDesignSystem.spacingL),
      decoration: CalculatorDesignSystem.cardDecorationThemed(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title ?? loc.translate('common.faq'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  collapsedIconColor: CalculatorColors.getTextSecondary(isDark),
                  iconColor: accentColor,
                  title: Text(
                    item.question,
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.getTextPrimary(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.answer,
                        style: CalculatorDesignSystem.bodyMedium.copyWith(
                          color: CalculatorColors.getTextSecondary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

