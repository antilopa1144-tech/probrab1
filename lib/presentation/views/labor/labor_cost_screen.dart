import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/region_ids.dart';
import '../../../domain/entities/labor_cost.dart';
import '../../providers/region_provider.dart';
import '../../providers/settings_provider.dart';

/// Экран расчёта трудозатрат.
class LaborCostScreen extends ConsumerStatefulWidget {
  final String calculatorId;
  final double quantity;

  const LaborCostScreen({
    super.key,
    required this.calculatorId,
    required this.quantity,
  });

  @override
  ConsumerState<LaborCostScreen> createState() => _LaborCostScreenState();
}

class _LaborCostScreenState extends ConsumerState<LaborCostScreen> {
  static const _laborCategoryFinishing = 'finishing';
  static const _laborUnitSquareMeterKey = 'common.sqm';

  late String _selectedRegion;
  final Map<String, LaborRate> _rates = {
    RegionId.moscow: const LaborRate(
      category: _laborCategoryFinishing,
      region: RegionId.moscow,
      pricePerUnit: 500,
      unit: _laborUnitSquareMeterKey,
      minPrice: 5000,
    ),
    RegionId.spb: const LaborRate(
      category: _laborCategoryFinishing,
      region: RegionId.spb,
      pricePerUnit: 470,
      unit: _laborUnitSquareMeterKey,
      minPrice: 4200,
    ),
    RegionId.ekaterinburg: const LaborRate(
      category: _laborCategoryFinishing,
      region: RegionId.ekaterinburg,
      pricePerUnit: 420,
      unit: _laborUnitSquareMeterKey,
      minPrice: 3600,
    ),
    RegionId.krasnodar: const LaborRate(
      category: _laborCategoryFinishing,
      region: RegionId.krasnodar,
      pricePerUnit: 390,
      unit: _laborUnitSquareMeterKey,
      minPrice: 3300,
    ),
    RegionId.regions: const LaborRate(
      category: _laborCategoryFinishing,
      region: RegionId.regions,
      pricePerUnit: 350,
      unit: _laborUnitSquareMeterKey,
      minPrice: 3000,
    ),
  };

  @override
  void initState() {
    super.initState();
    final preferredRegion = ref.read(regionProvider);
    final normalizedRegion = RegionCatalog.normalize(preferredRegion);
    _selectedRegion = _rates.containsKey(normalizedRegion)
        ? normalizedRegion
        : _rates.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final syncedRegion = RegionCatalog.normalize(ref.watch(regionProvider));
    if (_rates.containsKey(syncedRegion) && syncedRegion != _selectedRegion) {
      _selectedRegion = syncedRegion;
    }

    final theme = Theme.of(context);
    final rate = _rates[_selectedRegion]!;
    final calculation = LaborCostCalculation.fromCalculator(
      widget.calculatorId,
      widget.quantity,
      rate,
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('labor.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('labor.region'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedRegion,
                      isExpanded: true,
                      items: _rates.keys.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(_getRegionLabel(loc, region)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedRegion = value;
                        });
                        ref.read(regionProvider.notifier).setRegion(value);
                        ref.read(settingsProvider.notifier).updateRegion(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('labor.calculation'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResultRow(
                      label: loc.translate('labor.result.quantity'),
                      value: '${widget.quantity.toStringAsFixed(2)} ${_getUnitLabel(loc, rate.unit)}',
                    ),
                    const Divider(),
                    _ResultRow(
                      label: loc.translate('labor.result.hours'),
                      value: loc.translate('labor.value.hours', {
                        'value': calculation.estimatedHours.toString(),
                      }),
                    ),
                    _ResultRow(
                      label: loc.translate('labor.result.days'),
                      value: loc.translate('labor.value.days', {
                        'value': calculation.estimatedDays.toString(),
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('labor.info_title'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('labor.info_text'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitLabel(AppLocalizations loc, String unitKey) {
    if (unitKey.contains('.')) {
      return loc.translate(unitKey);
    }
    return unitKey;
  }

  String _getRegionLabel(AppLocalizations loc, String region) {
    final labelKey = RegionCatalog.laborLabelKey(region);
    if (labelKey.isNotEmpty) {
      return loc.translate(labelKey);
    }
    return RegionCatalog.legacyName(region);
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


