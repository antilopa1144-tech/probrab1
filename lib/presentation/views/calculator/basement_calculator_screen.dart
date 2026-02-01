import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_basement_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип подвала
enum BasementType {
  technical('basement_calc.type.technical', 'basement_calc.type.technical_desc', Icons.engineering),
  living('basement_calc.type.living', 'basement_calc.type.living_desc', Icons.home),
  garage('basement_calc.type.garage', 'basement_calc.type.garage_desc', Icons.garage);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const BasementType(this.nameKey, this.descKey, this.icon);
}

class _BasementResult {
  final double floorArea;
  final double wallArea;
  final double concreteVolume;
  final double waterproofArea;
  final double insulationArea;
  final double drainageLength;

  const _BasementResult({
    required this.floorArea,
    required this.wallArea,
    required this.concreteVolume,
    required this.waterproofArea,
    required this.insulationArea,
    required this.drainageLength,
  });

  factory _BasementResult.fromCalculatorResult(Map<String, double> values) {
    return _BasementResult(
      floorArea: values['floorArea'] ?? 0,
      wallArea: values['wallArea'] ?? 0,
      concreteVolume: values['concreteVolume'] ?? 0,
      waterproofArea: values['waterproofArea'] ?? 0,
      insulationArea: values['insulationArea'] ?? 0,
      drainageLength: values['drainageLength'] ?? 0,
    );
  }
}

class BasementCalculatorScreen extends ConsumerStatefulWidget {
  const BasementCalculatorScreen({super.key});

  @override
  ConsumerState<BasementCalculatorScreen> createState() => _BasementCalculatorScreenState();
}

class _BasementCalculatorScreenState extends ConsumerState<BasementCalculatorScreen>
    with ExportableConsumerMixin {
  bool _isDark = false;

  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('basement_calc.title');

  // Domain layer calculator
  final _calculator = CalculateBasementV2();

  double _length = 10.0;
  double _width = 8.0;
  double _depth = 2.5;
  double _wallThickness = 0.3;

  BasementType _basementType = BasementType.technical;
  bool _needWaterproof = true;
  bool _needInsulation = false;
  bool _needDrainage = true;

  late _BasementResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.foundation;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _BasementResult _calculate() {
    final inputs = <String, double>{
      'length': _length,
      'width': _width,
      'depth': _depth,
      'wallThickness': _wallThickness,
      'basementType': _basementType.index.toDouble(),
      'needWaterproof': _needWaterproof ? 1.0 : 0.0,
      'needInsulation': _needInsulation ? 1.0 : 0.0,
      'needDrainage': _needDrainage ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _BasementResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('basement_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('basement_calc.export.floor_area')
        .replaceFirst('{value}', _result.floorArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('basement_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_basementType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('basement_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('basement_calc.export.concrete')
        .replaceFirst('{value}', _result.concreteVolume.toStringAsFixed(1)));
    if (_needWaterproof) {
      buffer.writeln(_loc.translate('basement_calc.export.waterproof')
          .replaceFirst('{value}', _result.waterproofArea.toStringAsFixed(1)));
    }
    if (_needInsulation) {
      buffer.writeln(_loc.translate('basement_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    if (_needDrainage) {
      buffer.writeln(_loc.translate('basement_calc.export.drainage')
          .replaceFirst('{value}', _result.drainageLength.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('basement_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('basement_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('basement_calc.result.floor_area').toUpperCase(),
            value: '${_result.floorArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('basement_calc.result.concrete').toUpperCase(),
            value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.view_in_ar,
          ),
          ResultItem(
            label: _loc.translate('basement_calc.result.wall_area').toUpperCase(),
            value: '${_result.wallArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: BasementType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _basementType.index,
      onSelect: (index) {
        setState(() {
          _basementType = BasementType.values[index];
          if (_basementType == BasementType.living) {
            _needInsulation = true;
          }
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  /// Возвращает рекомендуемую толщину стены для текущего типа подвала
  int _getRecommendedWallThickness() {
    switch (_basementType) {
      case BasementType.technical:
        return 20; // Технический подвал - минимальная толщина
      case BasementType.living:
        return 30; // Жилой - требует утепления и комфорта
      case BasementType.garage:
        return 25; // Гараж - средняя нагрузка
    }
  }

  /// Подсказка по толщине стен
  String _getWallThicknessHint() {
    final recommended = _getRecommendedWallThickness();
    final current = (_wallThickness * 100).round();

    if (current < recommended) {
      return '★ Рекомендуется от $recommended см';
    } else if (current == recommended) {
      return '★ Оптимально для ${_loc.translate(_basementType.nameKey).toLowerCase()}';
    }
    return '';
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.length'), value: _length, onChanged: (v) { setState(() { _length = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 30)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.width'), value: _width, onChanged: (v) { setState(() { _width = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.depth'), value: _depth, onChanged: (v) { setState(() { _depth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1.5, maxValue: 4)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.wall_thickness'), value: _wallThickness * 100, onChanged: (v) { setState(() { _wallThickness = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 15, maxValue: 60, hint: _getWallThicknessHint())),
            ],
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
            title: Text(_loc.translate('basement_calc.option.waterproof'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('basement_calc.option.waterproof_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needWaterproof,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needWaterproof = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('basement_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('basement_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needInsulation,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('basement_calc.option.drainage'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('basement_calc.option.drainage_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needDrainage,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needDrainage = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('basement_calc.materials.concrete'),
        value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('basement_calc.materials.concrete_desc'),
        icon: Icons.view_in_ar,
      ),
    ];

    if (_needWaterproof && _result.waterproofArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('basement_calc.materials.waterproof'),
        value: '${_result.waterproofArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('basement_calc.materials.waterproof_desc'),
        icon: Icons.water_drop,
      ));
    }

    if (_needInsulation && _result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('basement_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('basement_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    if (_needDrainage && _result.drainageLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('basement_calc.materials.drainage'),
        value: '${_result.drainageLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('basement_calc.materials.drainage_desc'),
        icon: Icons.water,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('basement_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_basementType) {
      case BasementType.technical:
        tips.addAll([
          _loc.translate('basement_calc.tip.technical_1'),
          _loc.translate('basement_calc.tip.technical_2'),
        ]);
        break;
      case BasementType.living:
        tips.addAll([
          _loc.translate('basement_calc.tip.living_1'),
          _loc.translate('basement_calc.tip.living_2'),
        ]);
        break;
      case BasementType.garage:
        tips.addAll([
          _loc.translate('basement_calc.tip.garage_1'),
          _loc.translate('basement_calc.tip.garage_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('basement_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}
