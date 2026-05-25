import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/septic_rings_canonical_adapter.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum SepticGround {
  sandy('septic_calc.ground.sandy', 'septic_calc.ground.sandy_desc'),
  loamy('septic_calc.ground.loamy', 'septic_calc.ground.loamy_desc'),
  clay('septic_calc.ground.clay', 'septic_calc.ground.clay_desc');

  final String nameKey;
  final String descKey;
  const SepticGround(this.nameKey, this.descKey);
}

class SepticRingsCalculatorScreen extends ConsumerStatefulWidget {
  const SepticRingsCalculatorScreen({super.key});

  @override
  ConsumerState<SepticRingsCalculatorScreen> createState() => _SepticRingsCalculatorScreenState();
}

class _SepticRingsCalculatorScreenState extends ConsumerState<SepticRingsCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('septic_calc.title');

  int _residents = 4;
  int _chambersCount = 3;
  int _ringDiameter = 1000;
  SepticGround _groundType = SepticGround.loamy;
  bool _withFilterWell = true;
  double _pipeLengthFromHouse = 8.0;

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
    return calculateCanonicalSepticRings({
      'residents': _residents.toDouble(),
      'chambersCount': _chambersCount.toDouble(),
      'ringDiameter': _ringDiameter.toDouble(),
      'groundType': _groundType.index.toDouble(),
      'withFilterWell': _withFilterWell ? 1.0 : 0.0,
      'pipeLengthFromHouse': _pipeLengthFromHouse,
    });
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('septic_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('septic_calc.export.residents')
        .replaceFirst('{value}', '$_residents'));
    buffer.writeln(_loc.translate('septic_calc.export.chambers')
        .replaceFirst('{value}', '$_chambersCount'));
    buffer.writeln(_loc.translate('septic_calc.export.diameter')
        .replaceFirst('{value}', '$_ringDiameter'));
    buffer.writeln(_loc.translate('septic_calc.export.ground')
        .replaceFirst('{value}', _loc.translate(_groundType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('septic_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    for (final m in _result.materials) {
      final qty = m.purchaseQty != null && m.purchaseQty! > 0
          ? m.purchaseQty!.toStringAsFixed(m.purchaseQty! % 1 == 0 ? 0 : 2)
          : m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 2);
      buffer.writeln('• ${m.name}: $qty ${m.unit}');
    }
    if (_result.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_loc.translate('septic_calc.export.warnings_title'));
      buffer.writeln('─' * 40);
      for (final w in _result.warnings) {
        buffer.writeln('⚠ $w');
      }
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('septic_calc.export.footer'));
    return buffer.toString();
  }

  double _t(String key) => _result.totals[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('septic_calc.title'),
      accentColor: _accentColor,
      faqPrefix: 'faq.septic_rings',
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('septic_calc.result.rings').toUpperCase(),
            value: '${_t('totalRings').toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.circle_outlined,
          ),
          ResultItem(
            label: _loc.translate('septic_calc.result.volume').toUpperCase(),
            value: '${_t('totalVolume').toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.water_drop,
          ),
          ResultItem(
            label: _loc.translate('septic_calc.result.daily').toUpperCase(),
            value: '${_t('dailyVolumeLiters').toStringAsFixed(0)} ${_loc.translate('common.liters')}',
            icon: Icons.calendar_today,
          ),
        ],
      ),
      children: [
        _buildResidentsCard(),
        const SizedBox(height: 16),
        _buildChambersCard(),
        const SizedBox(height: 16),
        _buildRingDiameterCard(),
        const SizedBox(height: 16),
        _buildGroundCard(),
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

  Widget _buildResidentsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('septic_calc.label.residents'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '$_residents ${_loc.translate('common.pcs')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _residents.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: _accentColor,
            onChanged: (v) { _residents = v.round(); _update(); },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('septic_calc.label.pipe_length'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${_pipeLengthFromHouse.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _pipeLengthFromHouse,
            min: 2,
            max: 50,
            divisions: 48,
            activeColor: _accentColor,
            onChanged: (v) { _pipeLengthFromHouse = v; _update(); },
          ),
        ],
      ),
    );
  }

  Widget _buildChambersCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('septic_calc.section.chambers'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['1', '2', '3'],
            selectedIndex: _chambersCount - 1,
            onSelect: (i) {
              setState(() {
                _chambersCount = i + 1;
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('septic_calc.chambers.${_chambersCount}_desc'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingDiameterCard() {
    const diameters = [1000, 1500, 2000];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('septic_calc.section.diameter'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: diameters
                .map((d) => '$d ${_loc.translate('common.mm')}')
                .toList(),
            selectedIndex: diameters.indexOf(_ringDiameter),
            onSelect: (i) {
              setState(() {
                _ringDiameter = diameters[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('septic_calc.diameter.${_ringDiameter}_desc'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('septic_calc.section.ground'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: SepticGround.values
                .map((g) => _loc.translate(g.nameKey))
                .toList(),
            selectedIndex: _groundType.index,
            onSelect: (i) {
              setState(() {
                _groundType = SepticGround.values[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_groundType.descKey),
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
          _loc.translate('septic_calc.option.filter_well'),
          style: CalculatorDesignSystem.bodyMedium.copyWith(
            color: CalculatorColors.getTextPrimary(_isDark),
          ),
        ),
        subtitle: Text(
          _loc.translate('septic_calc.option.filter_well_desc'),
          style: CalculatorDesignSystem.bodySmall.copyWith(
            color: CalculatorColors.getTextSecondary(_isDark),
          ),
        ),
        value: _withFilterWell,
        activeTrackColor: _accentColor,
        onChanged: (v) { _withFilterWell = v; _update(); },
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
                _loc.translate('septic_calc.warnings.title'),
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
      _loc.translate('septic_calc.tip.distance'),
      _loc.translate('septic_calc.tip.slope'),
    ];
    if (_groundType == SepticGround.clay && _withFilterWell) {
      tips.add(_loc.translate('septic_calc.tip.clay_filter'));
    }
    if (_chambersCount == 1) {
      tips.add(_loc.translate('septic_calc.tip.single_chamber'));
    }
    if (_residents >= 6) {
      tips.add(_loc.translate('septic_calc.tip.large_family'));
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
