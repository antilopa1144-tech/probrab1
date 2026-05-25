import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/paving_tiles_canonical_adapter.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum PavingFoundation {
  sand('paving_calc.foundation.sand', 'paving_calc.foundation.sand_desc'),
  cementSand('paving_calc.foundation.cement_sand', 'paving_calc.foundation.cement_sand_desc'),
  concrete('paving_calc.foundation.concrete', 'paving_calc.foundation.concrete_desc');

  final String nameKey;
  final String descKey;
  const PavingFoundation(this.nameKey, this.descKey);
}

class PavingTilesCalculatorScreen extends ConsumerStatefulWidget {
  const PavingTilesCalculatorScreen({super.key});

  @override
  ConsumerState<PavingTilesCalculatorScreen> createState() => _PavingTilesCalculatorScreenState();
}

class _PavingTilesCalculatorScreenState extends ConsumerState<PavingTilesCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('paving_calc.title');

  double _area = 50.0;
  double _perimeter = 30.0;
  PavingFoundation _foundation = PavingFoundation.cementSand;
  int _tileThickness = 60;
  bool _borderEnabled = true;

  late CanonicalCalculatorContractResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.facade;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  CanonicalCalculatorContractResult _calculate() {
    return calculateCanonicalPavingTiles({
      'area': _area,
      'perimeter': _perimeter,
      'foundationType': _foundation.index.toDouble(),
      'tileThickness': _tileThickness.toDouble(),
      'borderEnabled': _borderEnabled ? 1.0 : 0.0,
    });
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('paving_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('paving_calc.export.area')
        .replaceFirst('{value}', _area.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('paving_calc.export.perimeter')
        .replaceFirst('{value}', _perimeter.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('paving_calc.export.foundation')
        .replaceFirst('{value}', _loc.translate(_foundation.nameKey)));
    buffer.writeln(_loc.translate('paving_calc.export.thickness')
        .replaceFirst('{value}', '$_tileThickness'));
    buffer.writeln();
    buffer.writeln(_loc.translate('paving_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    for (final m in _result.materials) {
      final qty = m.purchaseQty != null && m.purchaseQty! > 0
          ? m.purchaseQty!.toStringAsFixed(m.purchaseQty! % 1 == 0 ? 0 : 2)
          : m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 2);
      buffer.writeln('• ${m.name}: $qty ${m.unit}');
    }
    if (_result.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_loc.translate('paving_calc.export.warnings_title'));
      buffer.writeln('─' * 40);
      for (final w in _result.warnings) {
        buffer.writeln('⚠ $w');
      }
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('paving_calc.export.footer'));
    return buffer.toString();
  }

  double _t(String key) => _result.totals[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('paving_calc.title'),
      accentColor: _accentColor,
      faqPrefix: 'faq.paving_tiles',
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('paving_calc.result.tile').toUpperCase(),
            value: '${_t('tileM2').toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.grid_view,
          ),
          ResultItem(
            label: _loc.translate('paving_calc.result.sand').toUpperCase(),
            value: '${_t('sandBeddingM3').toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.grain,
          ),
          ResultItem(
            label: _loc.translate('paving_calc.result.border').toUpperCase(),
            value: '${_t('borderPcs').toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.fence,
          ),
        ],
      ),
      children: [
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildFoundationCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        if (_result.warnings.isNotEmpty) ...[
          _buildWarningsCard(),
          const SizedBox(height: 16),
        ],
        CanonicalMaterialsCard(
          materials: _result.materials,
          accentColor: _accentColor,
          loc: _loc,
        ),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('paving_calc.label.area'),
                  value: _area,
                  onChanged: (v) { _area = v; _update(); },
                  suffix: _loc.translate('common.sqm'),
                  accentColor: _accentColor,
                  minValue: 5,
                  maxValue: 2000,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('paving_calc.label.perimeter'),
                  value: _perimeter,
                  onChanged: (v) { _perimeter = v; _update(); },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 4,
                  maxValue: 500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoundationCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('paving_calc.section.foundation'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: PavingFoundation.values
                .map((f) => _loc.translate(f.nameKey))
                .toList(),
            selectedIndex: _foundation.index,
            onSelect: (i) {
              setState(() {
                _foundation = PavingFoundation.values[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_foundation.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThicknessCard() {
    const thicknesses = [30, 40, 60, 80];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('paving_calc.section.thickness'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: thicknesses
                .map((t) => '$t ${_loc.translate('common.mm')}')
                .toList(),
            selectedIndex: thicknesses.indexOf(_tileThickness),
            onSelect: (i) {
              setState(() {
                _tileThickness = thicknesses[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('paving_calc.thickness.${_tileThickness}_desc'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _loc.translate('paving_calc.option.border'),
          style: CalculatorDesignSystem.bodyMedium.copyWith(
            color: CalculatorColors.getTextPrimary(_isDark),
          ),
        ),
        subtitle: Text(
          _loc.translate('paving_calc.option.border_desc'),
          style: CalculatorDesignSystem.bodySmall.copyWith(
            color: CalculatorColors.getTextSecondary(_isDark),
          ),
        ),
        value: _borderEnabled,
        activeTrackColor: _accentColor,
        onChanged: (v) { _borderEnabled = v; _update(); },
      ),
    );
  }

  Widget _buildWarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: _isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                _loc.translate('paving_calc.warnings.title'),
                style: CalculatorDesignSystem.titleSmall.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final w in _result.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $w',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[
      _loc.translate('paving_calc.tip.slope'),
      _loc.translate('paving_calc.tip.compaction'),
    ];
    if (_tileThickness < 60) {
      tips.add(_loc.translate('paving_calc.tip.thin_tile'));
    }
    if (_foundation == PavingFoundation.concrete) {
      tips.add(_loc.translate('paving_calc.tip.concrete_base'));
    }
    if (!_borderEnabled) {
      tips.add(_loc.translate('paving_calc.tip.no_border'));
    }

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(_isDark),
      ),
      child: child,
    );
  }
}
