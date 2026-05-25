import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/lawn_canonical_adapter.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum LawnType {
  seed('lawn_calc.type.seed', 'lawn_calc.type.seed_desc', Icons.spa),
  rolls('lawn_calc.type.rolls', 'lawn_calc.type.rolls_desc', Icons.view_in_ar);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LawnType(this.nameKey, this.descKey, this.icon);
}

enum LawnGroundType {
  sandy('lawn_calc.ground.sandy', 'lawn_calc.ground.sandy_desc'),
  loamy('lawn_calc.ground.loamy', 'lawn_calc.ground.loamy_desc'),
  clay('lawn_calc.ground.clay', 'lawn_calc.ground.clay_desc');

  final String nameKey;
  final String descKey;
  const LawnGroundType(this.nameKey, this.descKey);
}

enum LawnUsage {
  decor('lawn_calc.usage.decor', 'lawn_calc.usage.decor_desc'),
  normal('lawn_calc.usage.normal', 'lawn_calc.usage.normal_desc'),
  sport('lawn_calc.usage.sport', 'lawn_calc.usage.sport_desc');

  final String nameKey;
  final String descKey;
  const LawnUsage(this.nameKey, this.descKey);
}

class LawnCalculatorScreen extends ConsumerStatefulWidget {
  const LawnCalculatorScreen({super.key});

  @override
  ConsumerState<LawnCalculatorScreen> createState() => _LawnCalculatorScreenState();
}

class _LawnCalculatorScreenState extends ConsumerState<LawnCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('lawn_calc.title');

  double _area = 50.0;
  double _soilThickness = 12.0;
  LawnType _lawnType = LawnType.seed;
  LawnGroundType _groundType = LawnGroundType.loamy;
  LawnUsage _usage = LawnUsage.normal;
  bool _withDrainage = false;
  bool _withGeotextile = false;

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
    return calculateCanonicalLawn({
      'area': _area,
      'lawnType': _lawnType.index.toDouble(),
      'soilThickness': _soilThickness,
      'groundType': _groundType.index.toDouble(),
      'usageIntensity': _usage.index.toDouble(),
      'withDrainage': _withDrainage ? 1.0 : 0.0,
      'withGeotextile': _withGeotextile ? 1.0 : 0.0,
    });
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('lawn_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('lawn_calc.export.area')
        .replaceFirst('{value}', _area.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('lawn_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_lawnType.nameKey)));
    buffer.writeln(_loc.translate('lawn_calc.export.usage')
        .replaceFirst('{value}', _loc.translate(_usage.nameKey)));
    buffer.writeln(_loc.translate('lawn_calc.export.ground')
        .replaceFirst('{value}', _loc.translate(_groundType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('lawn_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    for (final m in _result.materials) {
      final qty = m.purchaseQty != null && m.purchaseQty! > 0
          ? m.purchaseQty!.toStringAsFixed(m.purchaseQty! % 1 == 0 ? 0 : 2)
          : m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 2);
      buffer.writeln('• ${m.name}: $qty ${m.unit}');
    }
    if (_result.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_loc.translate('lawn_calc.export.warnings_title'));
      buffer.writeln('─' * 40);
      for (final w in _result.warnings) {
        buffer.writeln('⚠ $w');
      }
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('lawn_calc.export.footer'));
    return buffer.toString();
  }

  double _t(String key) => _result.totals[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryUnit = _lawnType == LawnType.rolls
        ? _loc.translate('common.pcs')
        : _loc.translate('common.sqm');
    final primaryValue = _lawnType == LawnType.rolls
        ? _t('rollsCount').toStringAsFixed(0)
        : _area.toStringAsFixed(0);
    final primaryLabel = _lawnType == LawnType.rolls
        ? _loc.translate('lawn_calc.result.rolls').toUpperCase()
        : _loc.translate('lawn_calc.result.area').toUpperCase();

    return CalculatorScaffold(
      title: _loc.translate('lawn_calc.title'),
      accentColor: _accentColor,
      faqPrefix: 'faq.lawn',
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: primaryLabel,
            value: '$primaryValue $primaryUnit',
            icon: _lawnType == LawnType.rolls ? Icons.view_in_ar : Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('lawn_calc.result.topsoil').toUpperCase(),
            value: '${_t('topsoilM3').toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.terrain,
          ),
          ResultItem(
            label: _loc.translate('lawn_calc.result.fertilizer').toUpperCase(),
            value: '${_t('fertilizerKg').toStringAsFixed(1)} ${_loc.translate('common.kg')}',
            icon: Icons.eco,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildGroundCard(),
        const SizedBox(height: 16),
        _buildUsageCard(),
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
      options: LawnType.values
          .map((t) => TypeSelectorOption(
                icon: t.icon,
                title: _loc.translate(t.nameKey),
                subtitle: _loc.translate(t.descKey),
              ))
          .toList(),
      selectedIndex: _lawnType.index,
      onSelect: (i) {
        setState(() {
          _lawnType = LawnType.values[i];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('lawn_calc.label.area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 5,
            max: 2000,
            divisions: 399,
            activeColor: _accentColor,
            onChanged: (v) { _area = v; _update(); },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('lawn_calc.label.soil_thickness'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${_soilThickness.toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _soilThickness,
            min: 8,
            max: 25,
            divisions: 17,
            activeColor: _accentColor,
            onChanged: (v) { _soilThickness = v; _update(); },
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
            _loc.translate('lawn_calc.section.ground'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: LawnGroundType.values
                .map((g) => _loc.translate(g.nameKey))
                .toList(),
            selectedIndex: _groundType.index,
            onSelect: (i) {
              setState(() {
                _groundType = LawnGroundType.values[i];
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

  Widget _buildUsageCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _loc.translate('lawn_calc.section.usage'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: LawnUsage.values
                .map((u) => _loc.translate(u.nameKey))
                .toList(),
            selectedIndex: _usage.index,
            onSelect: (i) {
              setState(() {
                _usage = LawnUsage.values[i];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_usage.descKey),
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
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('lawn_calc.option.drainage'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('lawn_calc.option.drainage_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _withDrainage,
            activeTrackColor: _accentColor,
            onChanged: (v) { _withDrainage = v; _update(); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('lawn_calc.option.geotextile'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('lawn_calc.option.geotextile_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _withGeotextile,
            activeTrackColor: _accentColor,
            onChanged: (v) { _withGeotextile = v; _update(); },
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
                _loc.translate('lawn_calc.warnings.title'),
                style: CalculatorDesignSystem.titleSmall.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final w in _result.warnings) ...[
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
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];
    if (_lawnType == LawnType.seed) {
      tips.add(_loc.translate('lawn_calc.tip.seed_season'));
      tips.add(_loc.translate('lawn_calc.tip.seed_watering'));
    } else {
      tips.add(_loc.translate('lawn_calc.tip.rolls_install'));
      tips.add(_loc.translate('lawn_calc.tip.rolls_stagger'));
    }
    if (_groundType == LawnGroundType.clay) {
      tips.add(_loc.translate('lawn_calc.tip.clay_drainage'));
    }
    if (_usage == LawnUsage.sport) {
      tips.add(_loc.translate('lawn_calc.tip.sport_soil'));
    }
    tips.add(_loc.translate('lawn_calc.tip.roller'));

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
