import 'package:flutter/material.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/localization/app_localizations.dart';

class GroupedResultsCard extends StatelessWidget {
  final Map<String, double> results;
  final AppLocalizations loc;
  final String? primaryKey;

  const GroupedResultsCard({
    super.key,
    required this.results,
    required this.loc,
    this.primaryKey,
  });

  static const Map<String, List<String>> groups = {
    'materials': [
      'cementBags',
      'sandVolume',
      'plasterBags',
      'paintLiters',
      'wallpaperRolls',
      'sheetsNeeded',
      'insulationArea',
      'studsLength',
      'battensLength',
      'counterBattensLength',
      'groutNeeded',
      'bagsNeeded',
      'panelsCount',
      'panelsArea',
      'profileLength',
    ],
    'consumables': [
      'meshArea',
      'beaconsLength',
      'damperTapeLength',
      'plasticizerNeeded',
      'screwsNeeded',
      'screwDiameter',
      'nailsNeeded',
      'fastenersNeeded',
      'clips',
      'foamNeeded',
      'glueNeeded',
      'glueNeededKg',
      'spatulaCount',
      'spongePackCount',
      'cornersCount',
      'startersCount',
    ],
    'additional': [
      'waterproofingArea',
      'primerLiters',
      'underlayArea',
      'windBarrierArea',
      'vaporBarrierArea',
      'underlaymentArea',
      'membraneArea',
      'recommendedThickness',
      'consumptionPerM2',
      'bagWeight',
      'wastePercent',
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildGroupCard(
          context: context,
          title: _translateGroupLabel('materials'),
          icon: Icons.inventory_2_outlined,
          keys: groups['materials']!,
        ),
        const SizedBox(height: 12),
        _buildGroupCard(
          context: context,
          title: _translateGroupLabel('consumables'),
          icon: Icons.build_outlined,
          keys: groups['consumables']!,
        ),
        const SizedBox(height: 12),
        _buildGroupCard(
          context: context,
          title: _translateGroupLabel('additional'),
          icon: Icons.add_circle_outline,
          keys: groups['additional']!,
        ),
      ],
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<String> keys,
  }) {
    final groupResults = results.entries
        .where((entry) => keys.contains(entry.key))
        .where((entry) => entry.key != primaryKey)
        .where((entry) => entry.value > 0)
        .toList();

    if (groupResults.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Тёмная карточка: в светлой теме — тёмно-синий фон, в тёмной — чуть светлее основного фона
    final cardBg = isDark ? CalculatorColors.cardBackgroundLightDark : const Color(0xFF1E293B);
    final headerColor = isDark ? CalculatorColors.textSecondaryDark : Colors.white;
    final labelColor = isDark ? CalculatorColors.textPrimaryDark : Colors.white;
    final valueColor = isDark ? CalculatorColors.textPrimaryDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: headerColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: headerColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...groupResults.map((entry) {
            final unit = _getUnit(entry.key);
            final formatted = _formatValue(entry.key, entry.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _translateResultLabel(entry.key),
                      style: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      unit.isEmpty ? formatted : '$formatted $unit',
                      style: TextStyle(
                        color: valueColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getUnit(String resultKey) {
    if (resultKey.contains('Kg') || resultKey.contains('kg')) {
      return loc.translate('unit.kg');
    }
    if (resultKey.contains('Liter') || resultKey.contains('liter')) {
      return loc.translate('unit.liter');
    }
    if (resultKey.contains('Area') || resultKey.contains('area')) {
      return loc.translate('unit.sqm');
    }
    if (resultKey.contains('Size') || resultKey.contains('size')) {
      return loc.translate('unit.mm');
    }
    if (resultKey.contains('Thickness') || resultKey.contains('thickness')) {
      return loc.translate('unit.mm');
    }
    if (resultKey == 'screwDiameter' || resultKey == 'screwLength') {
      return loc.translate('unit.mm');
    }
    return '';
  }

  String _formatValue(String key, double value) {
    if (key == 'screwDiameter') {
      final length = results['screwLength'];
      if (length != null && length > 0) {
        return '${_formatNumber(value)}×${_formatNumber(length)}';
      }
    }
    return _formatNumber(value);
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _translateResultLabel(String key) {
    final resultKey = 'result.$key';
    final translated = loc.translate(resultKey);
    if (translated == resultKey) {
      final fallback = loc.translate(key);
      if (fallback != key) return fallback;
    }
    return translated;
  }

  String _translateGroupLabel(String key) {
    final resultKey = 'result.group.$key';
    final translated = loc.translate(resultKey);
    if (translated == resultKey) {
      final fallbackKey = 'group.$key';
      final fallback = loc.translate(fallbackKey);
      if (fallback != fallbackKey) return fallback;
    }
    return translated;
  }
}
