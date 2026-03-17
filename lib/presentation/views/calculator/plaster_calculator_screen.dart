import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/calculate_plaster.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

const _plasterMaterialCategoryBase = 'Основное';

enum PlasterMaterial { gypsum, cement }
enum PlasterInputMode { manual, room }

/// Тип основания для штукатурки
enum SubstrateType {
  concrete('plaster_pro.substrate.concrete', 1.0),
  newBrick('plaster_pro.substrate.new_brick', 1.15),
  oldBrick('plaster_pro.substrate.old_brick', 1.3),
  gasBlock('plaster_pro.substrate.gas_block', 1.25),
  foamBlock('plaster_pro.substrate.foam_block', 1.2);

  final String nameKey;
  final double multiplier;
  const SubstrateType(this.nameKey, this.multiplier);
}

/// Ровность стен
enum WallEvenness {
  even('plaster_pro.evenness.even', 1.0),
  uneven('plaster_pro.evenness.uneven', 1.15),
  veryUneven('plaster_pro.evenness.very_uneven', 1.3);

  final String nameKey;
  final double multiplier;
  const WallEvenness(this.nameKey, this.multiplier);
}

class _PlasterResult {
  final double area;
  final double totalWeight;
  final int bags;
  final int beacons;
  final int meshArea;
  final double primerLiters;
  final int beaconSize;
  final int bagWeight;

  const _PlasterResult({
    required this.area,
    required this.totalWeight,
    required this.bags,
    required this.beacons,
    required this.meshArea,
    required this.primerLiters,
    required this.beaconSize,
    required this.bagWeight,
  });
}

class PlasterCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const PlasterCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<PlasterCalculatorScreen> createState() => _PlasterCalculatorScreenState();
}

class _PlasterCalculatorScreenState extends State<PlasterCalculatorScreen>
    with ExportableMixin {
  final CalculatePlaster _calculator = CalculatePlaster();
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  double _manualArea = 30;
  double _thickness = 15;
  int _bagWeight = 30;
  bool _useBeacons = true;
  bool _useMesh = false;
  bool _usePrimer = true;
  PlasterMaterial _materialType = PlasterMaterial.gypsum;
  PlasterInputMode _inputMode = PlasterInputMode.manual;
  SubstrateType _substrateType = SubstrateType.concrete;
  WallEvenness _wallEvenness = WallEvenness.even;
  late _PlasterResult _result;
  late AppLocalizations _loc;
  bool _isDark = false;


  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    final inputMode = initial['inputMode']?.round();
    if (inputMode == 0) {
      _inputMode = PlasterInputMode.room;
    } else if (inputMode == 1) {
      _inputMode = PlasterInputMode.manual;
    }

    if (initial['length'] != null && initial['length']! > 0) {
      _roomLength = initial['length']!.clamp(0.1, 100.0);
      _inputMode = PlasterInputMode.room;
    }
    if (initial['width'] != null && initial['width']! > 0) {
      _roomWidth = initial['width']!.clamp(0.1, 100.0);
      _inputMode = PlasterInputMode.room;
    }
    if (initial['height'] != null && initial['height']! > 0) {
      _roomHeight = initial['height']!.clamp(1.5, 10.0);
      _inputMode = PlasterInputMode.room;
    }
    if (initial['openingsArea'] != null) {
      _openingsArea = initial['openingsArea']!.clamp(0.0, 100.0);
    }
    if (initial['area'] != null && initial['area']! > 0) {
      _manualArea = initial['area']!.clamp(1.0, 1000.0);
      if (!initial.containsKey('length') && !initial.containsKey('width')) {
        _inputMode = PlasterInputMode.manual;
      }
    }
    if (initial['thickness'] != null) {
      _thickness = initial['thickness']!.clamp(5.0, 100.0);
    }

    final plasterType = initial['plasterType']?.round();
    final legacyType = initial['type']?.round();
    if (plasterType == 1 || legacyType == 2) {
      _materialType = PlasterMaterial.cement;
      _bagWeight = 25;
    } else if (plasterType == 0 || legacyType == 1) {
      _materialType = PlasterMaterial.gypsum;
      _bagWeight = 30;
    }

    final substrateType = initial['substrateType']?.round();
    if (substrateType != null && substrateType >= 1 && substrateType <= SubstrateType.values.length) {
      _substrateType = SubstrateType.values[substrateType - 1];
    }

    final wallEvenness = initial['wallEvenness']?.round();
    if (wallEvenness != null && wallEvenness >= 1 && wallEvenness <= WallEvenness.values.length) {
      _wallEvenness = WallEvenness.values[wallEvenness - 1];
    }
  }

  Map<String, double> _buildCalculationInputs() {
    return {
      'inputMode': _inputMode == PlasterInputMode.room ? 0.0 : 1.0,
      'length': _roomLength,
      'width': _roomWidth,
      'height': _roomHeight,
      'area': _manualArea,
      'openingsArea': _openingsArea,
      'plasterType': _materialType == PlasterMaterial.gypsum ? 0.0 : 1.0,
      'thickness': _thickness,
      'bagWeight': _bagWeight.toDouble(),
      'substrateType': (_substrateType.index + 1).toDouble(),
      'wallEvenness': (_wallEvenness.index + 1).toDouble(),
    };
  }

  int _findMaterialPurchaseQty(
    CanonicalCalculatorContractResult contract, {
    required String category,
    required String fallbackNamePart,
  }) {
    for (final material in contract.materials) {
      if (material.category == category && material.name.toLowerCase().contains(fallbackNamePart)) {
        return material.purchaseQty?.toInt() ?? 0;
      }
    }
    for (final material in contract.materials) {
      if (material.name.toLowerCase().contains(fallbackNamePart)) {
        return material.purchaseQty?.toInt() ?? 0;
      }
    }
    return 0;
  }

  _PlasterResult _calculate() {
    final contract = _calculator.calculateCanonical(_buildCalculationInputs());
    final totals = contract.totals;
    final autoMesh = (_thickness >= 30) || ((totals['warningMeshRecommended'] ?? 0) > 0);
    final meshNeeded = _useMesh || autoMesh;
    final primerNeed = totals['primerNeed'] ?? 0;

    return _PlasterResult(
      area: totals['netArea'] ?? 0,
      totalWeight: totals['totalKg'] ?? 0,
      bags: _findMaterialPurchaseQty(
        contract,
        category: _plasterMaterialCategoryBase,
        fallbackNamePart: 'штукатурка',
      ),
      beacons: _useBeacons ? (totals['beacons'] ?? 0).round() : 0,
      meshArea: meshNeeded ? (totals['meshArea'] ?? 0).round() : 0,
      primerLiters: _usePrimer ? double.parse(primerNeed.toStringAsFixed(1)) : 0,
      beaconSize: (totals['beaconSize'] ?? 10).round(),
      bagWeight: (totals['bagWeight'] ?? _bagWeight).round(),
    );
  }

  int _defaultBagWeightFor(PlasterMaterial material) {
    final inputs = Map<String, double>.from(_buildCalculationInputs())
      ..['plasterType'] = material == PlasterMaterial.gypsum ? 0.0 : 1.0
      ..remove('bagWeight');
    final contract = _calculator.calculateCanonical(inputs);
    return (contract.totals['bagWeight'] ?? (material == PlasterMaterial.gypsum ? 30 : 25)).round();
  }

  void _update() => setState(() => _result = _calculate());

  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('plaster_pro.brand');

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('plaster_pro.brand'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln('${_loc.translate('plaster_pro.label.wall_area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('plaster_pro.label.thickness')}: $_thickness ${_loc.translate('common.mm')}');
    buffer.writeln('${_loc.translate('plaster_pro.label.material')}: ${_materialType == PlasterMaterial.gypsum ? _loc.translate('plaster_pro.material.gypsum') : _loc.translate('plaster_pro.material.cement')}');
    buffer.writeln();
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('plaster_pro.section.results').toUpperCase());
    buffer.writeln('─' * 40);
    buffer.writeln('${_loc.translate('plaster_pro.label.bags')}: ${_result.bags} ${_loc.translate('common.pcs')} (${(_result.totalWeight).toStringAsFixed(1)} ${_loc.translate('common.kg')})');
    if (_useBeacons) {
      buffer.writeln('${_loc.translate('plaster_pro.label.beacons')}: ${_result.beacons} ${_loc.translate('common.pcs')} (${_result.beaconSize} ${_loc.translate('common.mm')})');
    }
    if (_useMesh) {
      buffer.writeln('${_loc.translate('plaster_pro.label.mesh')}: ${_result.meshArea} ${_loc.translate('common.sqm')}');
    }
    if (_usePrimer) {
      buffer.writeln('${_loc.translate('plaster_pro.label.primer')}: ${_result.primerLiters} ${_loc.translate('common.liters')}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate('plaster_pro.brand'),
      accentColor: accentColor,
      actions: exportActions,

      // Header с ключевыми результатами вверху
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('plaster_pro.label.wall_area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('plaster_pro.summary.bags').toUpperCase(),
            value: '${_result.bags}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('plaster_pro.summary.weight').toUpperCase(),
            value: '${(_result.totalWeight / 1000).toStringAsFixed(1)} ${_loc.translate('common.tons')}',
            icon: Icons.scale,
          ),
        ],
      ),

      children: [
        _buildMaterialSelector(),
        const SizedBox(height: 16),
        _buildSubstrateSelector(),
        const SizedBox(height: 16),
        _buildEvennessSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        // Убираем большую карточку с результатами - теперь они в header
        // _buildSummaryCard(),
        // const SizedBox(height: 16),
        _buildSpecCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    const accentColor = CalculatorColors.walls;
    final gypsumBagWeight = _materialType == PlasterMaterial.gypsum ? _result.bagWeight : _defaultBagWeightFor(PlasterMaterial.gypsum);
    final cementBagWeight = _materialType == PlasterMaterial.cement ? _result.bagWeight : _defaultBagWeightFor(PlasterMaterial.cement);
    return TypeSelectorGroup(
      options: [
        TypeSelectorOption(
          icon: Icons.home_repair_service,
          title: _loc.translate('plaster_pro.material.gypsum'),
          subtitle: '$gypsumBagWeight ${_loc.translate('common.kg')}',
        ),
        TypeSelectorOption(
          icon: Icons.construction,
          title: _loc.translate('plaster_pro.material.cement'),
          subtitle: '$cementBagWeight ${_loc.translate('common.kg')}',
        ),
      ],
      selectedIndex: _materialType == PlasterMaterial.gypsum ? 0 : 1,
      onSelect: (index) {
        setState(() {
          _materialType = index == 0 ? PlasterMaterial.gypsum : PlasterMaterial.cement;
          _bagWeight = index == 0 ? 30 : 25;
          _result = _calculate();
        });
      },
      accentColor: accentColor,
    );
  }

  Widget _buildSubstrateSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('plaster_pro.substrate.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SubstrateType.values.map((type) {
              final isSelected = _substrateType == type;
              return ChoiceChip(
                label: Text(_loc.translate(type.nameKey)),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() {
                    _substrateType = type;
                    _update();
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvennessSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('plaster_pro.evenness.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WallEvenness.values.map((type) {
              final isSelected = _wallEvenness == type;
              return ChoiceChip(
                label: Text(_loc.translate(type.nameKey)),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() {
                    _wallEvenness = type;
                    _update();
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('plaster_pro.mode.manual'),
              _loc.translate('plaster_pro.mode.room'),
            ],
            selectedIndex: _inputMode == PlasterInputMode.manual ? 0 : 1,
            onSelect: (index) {
              setState(() {
                _inputMode = index == 0 ? PlasterInputMode.manual : PlasterInputMode.room;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == PlasterInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    const accentColor = CalculatorColors.walls;
    return CalculatorSliderField(
      label: _loc.translate('plaster_pro.label.wall_area'),
      value: _manualArea,
      min: 1,
      max: 500,
      divisions: 4990,
      suffix: _loc.translate('common.sqm'),
      accentColor: accentColor,
      onChanged: (v) { setState(() { _manualArea = v; _update(); }); },
      decimalPlaces: 1,
    );
  }

  Widget _buildRoomInputs() {
    const accentColor = CalculatorColors.walls;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('plaster_pro.label.width'),
                value: _roomWidth,
                onChanged: (v) => setState(() { _roomWidth = v; _update(); }),
                suffix: _loc.translate('common.meters'),
                accentColor: accentColor,
                minValue: 0.1,
                maxValue: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('plaster_pro.label.length'),
                value: _roomLength,
                onChanged: (v) => setState(() { _roomLength = v; _update(); }),
                suffix: _loc.translate('common.meters'),
                accentColor: accentColor,
                minValue: 0.1,
                maxValue: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: _loc.translate('plaster_pro.label.height'),
          value: _roomHeight,
          onChanged: (v) => setState(() { _roomHeight = v; _update(); }),
          suffix: _loc.translate('common.meters'),
          accentColor: accentColor,
          minValue: 1.5,
          maxValue: 10,
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: _loc.translate('plaster_pro.label.openings_hint'),
          value: _openingsArea,
          onChanged: (v) => setState(() { _openingsArea = v; _update(); }),
          suffix: _loc.translate('common.sqm'),
          accentColor: accentColor,
          minValue: 0,
          maxValue: 100,
        ),
      ],
    );
  }

  Widget _buildThicknessCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('plaster_pro.thickness.title'),
            value: _thickness,
            min: 5,
            max: 100,
            divisions: 950,
            suffix: _loc.translate('common.mm'),
            accentColor: accentColor,
            onChanged: (v) { setState(() { _thickness = v; _update(); }); },
            decimalPlaces: 1,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _optIcon(Icons.architecture, _useBeacons, () => setState(() { _useBeacons = !_useBeacons; _update(); })),
              _optIcon(Icons.grid_on, _useMesh, () => setState(() { _useMesh = !_useMesh; _update(); })),
              _optIcon(Icons.water_drop, _usePrimer, () => setState(() { _usePrimer = !_usePrimer; _update(); })),
            ],
          )
        ],
      ),
    );
  }

  Widget _optIcon(IconData icon, bool active, VoidCallback tap) {
    const accentColor = CalculatorColors.walls;
    return IconButton(
      icon: Icon(icon, color: active ? accentColor : Colors.grey[300]),
      onPressed: tap,
    );
  }


  Widget _buildSpecCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('plaster_pro.summary.weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.scale,
      ),
    ];

    if (_useBeacons) {
      items.add(MaterialItem(
        name: _loc.translate('plaster_pro.options.beacons'),
        value: '${_result.beacons} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.beaconSize} ${_loc.translate('common.mm')}',
        icon: Icons.architecture,
      ));
    }

    if (_useMesh) {
      items.add(MaterialItem(
        name: _loc.translate('plaster_pro.spec.mesh_title'),
        value: '${_result.meshArea} ${_loc.translate('common.sqm')}',
        icon: Icons.grid_on,
      ));
    }

    if (_usePrimer) {
      items.add(MaterialItem(
        name: _loc.translate('plaster_pro.options.primer'),
        value: '${_result.primerLiters} ${_loc.translate('common.liters')}',
        icon: Icons.water_drop,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('plaster_pro.spec.title'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.walls;
    final tips = <String>[];

    switch (_materialType) {
      case PlasterMaterial.gypsum:
        tips.addAll([
          _loc.translate('plaster_calc.tip.gypsum_1'),
          _loc.translate('plaster_calc.tip.gypsum_2'),
        ]);
        break;
      case PlasterMaterial.cement:
        tips.addAll([
          _loc.translate('plaster_calc.tip.cement_1'),
          _loc.translate('plaster_calc.tip.cement_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('plaster_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }

}





