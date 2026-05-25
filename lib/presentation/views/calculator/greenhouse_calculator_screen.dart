import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/greenhouse_canonical_adapter.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum GreenhouseRoof {
  arch('greenhouse_calc.roof.arch', 'greenhouse_calc.roof.arch_desc', Icons.adjust),
  gable('greenhouse_calc.roof.gable', 'greenhouse_calc.roof.gable_desc', Icons.change_history);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const GreenhouseRoof(this.nameKey, this.descKey, this.icon);
}

enum GreenhouseFoundation {
  none('greenhouse_calc.foundation.none', 'greenhouse_calc.foundation.none_desc'),
  wood('greenhouse_calc.foundation.wood', 'greenhouse_calc.foundation.wood_desc'),
  block('greenhouse_calc.foundation.block', 'greenhouse_calc.foundation.block_desc'),
  strip('greenhouse_calc.foundation.strip', 'greenhouse_calc.foundation.strip_desc');

  final String nameKey;
  final String descKey;
  const GreenhouseFoundation(this.nameKey, this.descKey);
}

class GreenhouseCalculatorScreen extends ConsumerStatefulWidget {
  const GreenhouseCalculatorScreen({super.key});

  @override
  ConsumerState<GreenhouseCalculatorScreen> createState() => _GreenhouseCalculatorScreenState();
}

class _GreenhouseCalculatorScreenState extends ConsumerState<GreenhouseCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('greenhouse_calc.title');

  double _length = 6.0;
  double _width = 3.0;
  double _height = 2.1;
  GreenhouseRoof _roof = GreenhouseRoof.arch;
  int _polyThickness = 6;
  GreenhouseFoundation _foundation = GreenhouseFoundation.wood;

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
    return calculateCanonicalGreenhouse({
      'length': _length,
      'width': _width,
      'height': _height,
      'roofType': _roof.index.toDouble(),
      'polycarbonateThickness': _polyThickness.toDouble(),
      'foundationType': _foundation.index.toDouble(),
    });
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('greenhouse_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('greenhouse_calc.export.size')
        .replaceFirst('{value}',
            '${_length.toStringAsFixed(1)}×${_width.toStringAsFixed(1)}×${_height.toStringAsFixed(1)}'));
    buffer.writeln(_loc.translate('greenhouse_calc.export.roof')
        .replaceFirst('{value}', _loc.translate(_roof.nameKey)));
    buffer.writeln(_loc.translate('greenhouse_calc.export.poly')
        .replaceFirst('{value}', '$_polyThickness'));
    buffer.writeln(_loc.translate('greenhouse_calc.export.foundation')
        .replaceFirst('{value}', _loc.translate(_foundation.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('greenhouse_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    for (final m in _result.materials) {
      final qty = m.purchaseQty != null && m.purchaseQty! > 0
          ? m.purchaseQty!.toStringAsFixed(m.purchaseQty! % 1 == 0 ? 0 : 2)
          : m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 2);
      buffer.writeln('• ${m.name}: $qty ${m.unit}');
    }
    if (_result.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_loc.translate('greenhouse_calc.export.warnings_title'));
      buffer.writeln('─' * 40);
      for (final w in _result.warnings) {
        buffer.writeln('⚠ $w');
      }
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('greenhouse_calc.export.footer'));
    return buffer.toString();
  }

  double _t(String key) => _result.totals[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('greenhouse_calc.title'),
      accentColor: _accentColor,
      faqPrefix: 'faq.greenhouse',
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('greenhouse_calc.result.poly').toUpperCase(),
            value: '${_t('polySheets').toStringAsFixed(0)} ${_loc.translate('common.sheets')}',
            icon: Icons.view_in_ar,
          ),
          ResultItem(
            label: _loc.translate('greenhouse_calc.result.frame').toUpperCase(),
            value: '${_t('frameProfilePieces').toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.linear_scale,
          ),
          ResultItem(
            label: _loc.translate('greenhouse_calc.result.area').toUpperCase(),
            value: '${(_length * _width).toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
        ],
      ),
      children: [
        _buildRoofSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildPolyThicknessCard(),
        const SizedBox(height: 16),
        _buildFoundationCard(),
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

  Widget _buildRoofSelector() {
    return TypeSelectorGroup(
      options: GreenhouseRoof.values
          .map((r) => TypeSelectorOption(
                icon: r.icon,
                title: _loc.translate(r.nameKey),
                subtitle: _loc.translate(r.descKey),
              ))
          .toList(),
      selectedIndex: _roof.index,
      onSelect: (i) {
        setState(() {
          _roof = GreenhouseRoof.values[i];
          _update();
        });
      },
      accentColor: _accentColor,
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
                  label: _loc.translate('greenhouse_calc.label.length'),
                  value: _length,
                  onChanged: (v) { _length = v; _update(); },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 2,
                  maxValue: 12,
                  decimalPlaces: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('greenhouse_calc.label.width'),
                  value: _width,
                  onChanged: (v) { _width = v; _update(); },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 2,
                  maxValue: 6,
                  decimalPlaces: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('greenhouse_calc.label.height'),
            value: _height,
            onChanged: (v) { _height = v; _update(); },
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            minValue: 1.8,
            maxValue: 3.0,
            decimalPlaces: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPolyThicknessCard() {
    const thicknesses = [4, 6, 8, 10];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('greenhouse_calc.section.poly'),
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
            selectedIndex: thicknesses.indexOf(_polyThickness),
            onSelect: (i) {
              setState(() {
                _polyThickness = thicknesses[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('greenhouse_calc.poly.${_polyThickness}_desc'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
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
            _loc.translate('greenhouse_calc.section.foundation'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: GreenhouseFoundation.values
                .map((f) => _loc.translate(f.nameKey))
                .toList(),
            selectedIndex: _foundation.index,
            onSelect: (i) {
              setState(() {
                _foundation = GreenhouseFoundation.values[i];
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
                _loc.translate('greenhouse_calc.warnings.title'),
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
      _loc.translate('greenhouse_calc.tip.poly_protect'),
      _loc.translate('greenhouse_calc.tip.snow_load'),
    ];
    if (_polyThickness <= 4) {
      tips.add(_loc.translate('greenhouse_calc.tip.thin_poly'));
    }
    if (_foundation == GreenhouseFoundation.none) {
      tips.add(_loc.translate('greenhouse_calc.tip.no_foundation'));
    }
    tips.add(_loc.translate('greenhouse_calc.tip.ventilation'));

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
