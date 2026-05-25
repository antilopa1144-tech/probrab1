import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/drainage_canonical_adapter.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum DrainageType {
  linear('drainage_calc.type.linear', 'drainage_calc.type.linear_desc', Icons.linear_scale),
  ring('drainage_calc.type.ring', 'drainage_calc.type.ring_desc', Icons.radio_button_unchecked),
  complex('drainage_calc.type.complex', 'drainage_calc.type.complex_desc', Icons.account_tree);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const DrainageType(this.nameKey, this.descKey, this.icon);
}

enum GroundwaterRisk {
  low('drainage_calc.gwr.low', 'drainage_calc.gwr.low_desc'),
  medium('drainage_calc.gwr.medium', 'drainage_calc.gwr.medium_desc'),
  high('drainage_calc.gwr.high', 'drainage_calc.gwr.high_desc');

  final String nameKey;
  final String descKey;
  const GroundwaterRisk(this.nameKey, this.descKey);
}

class DrainageCalculatorScreen extends ConsumerStatefulWidget {
  const DrainageCalculatorScreen({super.key});

  @override
  ConsumerState<DrainageCalculatorScreen> createState() => _DrainageCalculatorScreenState();
}

class _DrainageCalculatorScreenState extends ConsumerState<DrainageCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('drainage_calc.title');

  double _length = 40.0;
  int _pipeDiameter = 110;
  DrainageType _drainageType = DrainageType.ring;
  GroundwaterRisk _groundwaterRisk = GroundwaterRisk.medium;
  bool _withCollector = true;

  late CanonicalCalculatorContractResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.foundation;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  CanonicalCalculatorContractResult _calculate() {
    return calculateCanonicalDrainage({
      'length': _length,
      'pipeDiameter': _pipeDiameter.toDouble(),
      'drainageType': _drainageType.index.toDouble(),
      'groundwaterRisk': _groundwaterRisk.index.toDouble(),
      'withCollector': _withCollector ? 1.0 : 0.0,
    });
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('drainage_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('drainage_calc.export.length')
        .replaceFirst('{value}', _length.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('drainage_calc.export.diameter')
        .replaceFirst('{value}', _pipeDiameter.toString()));
    buffer.writeln(_loc.translate('drainage_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_drainageType.nameKey)));
    buffer.writeln(_loc.translate('drainage_calc.export.gwr')
        .replaceFirst('{value}', _loc.translate(_groundwaterRisk.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('drainage_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    for (final m in _result.materials) {
      final qty = m.purchaseQty != null && m.purchaseQty! > 0
          ? m.purchaseQty!.toStringAsFixed(m.purchaseQty! % 1 == 0 ? 0 : 2)
          : m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 2);
      buffer.writeln('• ${m.name}: $qty ${m.unit}');
    }
    if (_result.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_loc.translate('drainage_calc.export.warnings_title'));
      buffer.writeln('─' * 40);
      for (final w in _result.warnings) {
        buffer.writeln('⚠ $w');
      }
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('drainage_calc.export.footer'));
    return buffer.toString();
  }

  double _t(String key) => _result.totals[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('drainage_calc.title'),
      accentColor: _accentColor,
      faqPrefix: 'faq.drainage',
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('drainage_calc.result.pipe').toUpperCase(),
            value: '${_t('pipeWithReserveM').toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.water,
          ),
          ResultItem(
            label: _loc.translate('drainage_calc.result.gravel').toUpperCase(),
            value: '${_t('gravelM3').toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.grain,
          ),
          ResultItem(
            label: _loc.translate('drainage_calc.result.wells').toUpperCase(),
            value: '${_t('wellCount').toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.circle_outlined,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildLengthCard(),
        const SizedBox(height: 16),
        _buildPipeDiameterCard(),
        const SizedBox(height: 16),
        _buildGroundwaterCard(),
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

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: DrainageType.values
          .map((t) => TypeSelectorOption(
                icon: t.icon,
                title: _loc.translate(t.nameKey),
                subtitle: _loc.translate(t.descKey),
              ))
          .toList(),
      selectedIndex: _drainageType.index,
      onSelect: (i) {
        setState(() {
          _drainageType = DrainageType.values[i];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildLengthCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('drainage_calc.label.length'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${_length.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _length,
            min: 5,
            max: 500,
            divisions: 99,
            activeColor: _accentColor,
            onChanged: (v) { _length = v; _update(); },
          ),
        ],
      ),
    );
  }

  Widget _buildPipeDiameterCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('drainage_calc.section.diameter'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: ['Ø110 ${_loc.translate('common.mm')}', 'Ø160 ${_loc.translate('common.mm')}'],
            selectedIndex: _pipeDiameter == 110 ? 0 : 1,
            onSelect: (i) {
              setState(() {
                _pipeDiameter = i == 0 ? 110 : 160;
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_pipeDiameter == 110
                ? 'drainage_calc.diameter.110_desc'
                : 'drainage_calc.diameter.160_desc'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundwaterCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('drainage_calc.section.gwr'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: GroundwaterRisk.values
                .map((g) => _loc.translate(g.nameKey))
                .toList(),
            selectedIndex: _groundwaterRisk.index,
            onSelect: (i) {
              setState(() {
                _groundwaterRisk = GroundwaterRisk.values[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_groundwaterRisk.descKey),
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
          _loc.translate('drainage_calc.option.collector'),
          style: CalculatorDesignSystem.bodyMedium.copyWith(
            color: CalculatorColors.getTextPrimary(_isDark),
          ),
        ),
        subtitle: Text(
          _loc.translate('drainage_calc.option.collector_desc'),
          style: CalculatorDesignSystem.bodySmall.copyWith(
            color: CalculatorColors.getTextSecondary(_isDark),
          ),
        ),
        value: _withCollector,
        activeTrackColor: _accentColor,
        onChanged: (v) { _withCollector = v; _update(); },
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
                _loc.translate('drainage_calc.warnings.title'),
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
      _loc.translate('drainage_calc.tip.depth'),
      _loc.translate('drainage_calc.tip.slope'),
    ];
    if (_groundwaterRisk == GroundwaterRisk.high) {
      tips.add(_loc.translate('drainage_calc.tip.high_gwr'));
    }
    if (_drainageType == DrainageType.ring) {
      tips.add(_loc.translate('drainage_calc.tip.ring'));
    }
    tips.add(_loc.translate('drainage_calc.tip.geotextile'));

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
