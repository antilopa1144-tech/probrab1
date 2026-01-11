import 'package:flutter/material.dart';
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
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildGroupCard(
          title: _translateGroupLabel('materials'),
          icon: Icons.inventory_2_outlined,
          keys: groups['materials']!,
        ),
        const SizedBox(height: 12),
        _buildGroupCard(
          title: _translateGroupLabel('consumables'),
          icon: Icons.build_outlined,
          keys: groups['consumables']!,
        ),
        const SizedBox(height: 12),
        _buildGroupCard(
          title: _translateGroupLabel('additional'),
          icon: Icons.add_circle_outline,
          keys: groups['additional']!,
        ),
      ],
    );
  }

  Widget _buildGroupCard({
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
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
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      unit.isEmpty ? formatted : '$formatted $unit',
                      style: const TextStyle(
                        color: Colors.white,
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
