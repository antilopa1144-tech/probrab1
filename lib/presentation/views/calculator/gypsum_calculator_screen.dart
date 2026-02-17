import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/usecases/calculate_gypsum_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../utils/screw_formatter.dart';

enum GypsumConstructionType { wallLining, partition, ceiling }
enum GypsumGKLType { standard, moisture, fire }
enum GypsumThickness { t9_5, t12_5 }
enum GypsumSheetSize { s2000x1200, s2500x1200, s2700x1200, s3000x1200 }

/// Форма стены — влияет на расход профиля
enum WallShape {
  rectangular(1.0),  // Прямоугольная
  lShaped(1.1),      // Г-образная — +10% профиля
  complex(1.2);       // Сложная — +20% профиля

  final double profileMultiplier;
  const WallShape(this.profileMultiplier);
}

class _GypsumResult {
  final double area;
  final int gklSheets;
  final double sheetArea;
  final String sheetSizeName;
  final int constructionType;
  final int pnPieces;
  final double pnMeters;
  final int ppPieces;
  final double ppMeters;
  final int screwsTN25;
  final int screwsTN35;
  final int screwsLN;
  final int dowels;
  final int suspensions;
  final int connectors;
  final double insulationArea;
  final double sealingTape;
  final double armatureTape;
  final double fillerKg;
  final double primerLiters;
  final double sheetWeight;
  final double totalWeight;

  const _GypsumResult({
    required this.area,
    required this.gklSheets,
    required this.sheetArea,
    required this.sheetSizeName,
    required this.constructionType,
    required this.pnPieces,
    required this.pnMeters,
    required this.ppPieces,
    required this.ppMeters,
    required this.screwsTN25,
    required this.screwsTN35,
    required this.screwsLN,
    required this.dowels,
    required this.suspensions,
    required this.connectors,
    required this.insulationArea,
    required this.sealingTape,
    required this.armatureTape,
    required this.fillerKg,
    required this.primerLiters,
    required this.sheetWeight,
    required this.totalWeight,
  });

  factory _GypsumResult.fromCalculatorResult(Map<String, double> values, GypsumSheetSize sheetSize) {
    final sheetSizeNames = {
      GypsumSheetSize.s2000x1200: '2000×1200',
      GypsumSheetSize.s2500x1200: '2500×1200',
      GypsumSheetSize.s2700x1200: '2700×1200',
      GypsumSheetSize.s3000x1200: '3000×1200',
    };
    return _GypsumResult(
      area: values['calculatedArea'] ?? 0,
      gklSheets: (values['gklSheets'] ?? 0).toInt(),
      sheetArea: values['sheetArea'] ?? 0,
      sheetSizeName: sheetSizeNames[sheetSize] ?? '2500×1200',
      constructionType: (values['constructionType'] ?? 0).toInt() + 1,
      pnPieces: (values['pnPieces'] ?? 0).toInt(),
      pnMeters: values['pnMeters'] ?? 0,
      ppPieces: (values['ppPieces'] ?? 0).toInt(),
      ppMeters: values['ppMeters'] ?? 0,
      screwsTN25: (values['screwsTN25'] ?? 0).toInt(),
      screwsTN35: (values['screwsTN35'] ?? 0).toInt(),
      screwsLN: (values['screwsLN'] ?? 0).toInt(),
      dowels: (values['dowels'] ?? 0).toInt(),
      suspensions: (values['suspensions'] ?? 0).toInt(),
      connectors: (values['connectors'] ?? 0).toInt(),
      insulationArea: values['insulationArea'] ?? 0,
      sealingTape: values['sealingTape'] ?? 0,
      armatureTape: values['armatureTape'] ?? 0,
      fillerKg: values['fillerKg'] ?? 0,
      primerLiters: values['primerLiters'] ?? 0,
      sheetWeight: values['sheetWeight'] ?? 0,
      totalWeight: values['totalWeight'] ?? 0,
    );
  }
}

class GypsumCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const GypsumCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<GypsumCalculatorScreen> createState() => _GypsumCalculatorScreenState();
}

class _GypsumCalculatorScreenState extends ConsumerState<GypsumCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('gypsum.export.subject');

  // Domain layer calculator
  final _calculator = CalculateGypsumV2();

  double _area = 20.0;
  int _layers = 1;
  bool _useInsulation = false;
  GypsumConstructionType _constructionType = GypsumConstructionType.wallLining;
  GypsumGKLType _gklType = GypsumGKLType.standard;
  GypsumThickness _thickness = GypsumThickness.t12_5;
  GypsumSheetSize _sheetSize = GypsumSheetSize.s2500x1200;
  WallShape _wallShape = WallShape.rectangular;
  late _GypsumResult _result;
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
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['layers'] != null) _layers = initial['layers']!.toInt().clamp(1, 2);
    if (initial['construction_type'] != null) {
      final type = initial['construction_type']!.toInt();
      if (type == 1) _constructionType = GypsumConstructionType.wallLining;
      if (type == 2) _constructionType = GypsumConstructionType.partition;
      if (type == 3) _constructionType = GypsumConstructionType.ceiling;
    }
    if (initial['gkl_type'] != null) {
      final type = initial['gkl_type']!.toInt();
      if (type == 1) _gklType = GypsumGKLType.standard;
      if (type == 2) _gklType = GypsumGKLType.moisture;
      if (type == 3) _gklType = GypsumGKLType.fire;
    }
  }

  /// Использует domain layer для расчёта
  _GypsumResult _calculate() {
    final inputs = <String, double>{
      'inputMode': 0.0, // Только режим "По площади"
      'area': _area,
      'constructionType': _constructionType.index.toDouble(),
      'gklType': _gklType.index.toDouble(),
      'thickness': _thickness.index.toDouble(),
      'sheetSize': _sheetSize.index.toDouble(),
      'layers': _layers.toDouble(),
      'useInsulation': _useInsulation ? 1.0 : 0.0,
      'wallShape': _wallShape.index.toDouble(),
    };

    final result = _calculator(inputs, []);
    final gypsumResult = _GypsumResult.fromCalculatorResult(result.values, _sheetSize);

    // Применяем множитель формы стены к профилю
    if (_wallShape != WallShape.rectangular) {
      final m = _wallShape.profileMultiplier;
      return _GypsumResult(
        area: gypsumResult.area,
        gklSheets: gypsumResult.gklSheets,
        sheetArea: gypsumResult.sheetArea,
        sheetSizeName: gypsumResult.sheetSizeName,
        constructionType: gypsumResult.constructionType,
        pnPieces: (gypsumResult.pnPieces * m).ceil(),
        pnMeters: gypsumResult.pnMeters * m,
        ppPieces: (gypsumResult.ppPieces * m).ceil(),
        ppMeters: gypsumResult.ppMeters * m,
        screwsTN25: gypsumResult.screwsTN25,
        screwsTN35: gypsumResult.screwsTN35,
        screwsLN: (gypsumResult.screwsLN * m).ceil(),
        dowels: (gypsumResult.dowels * m).ceil(),
        suspensions: (gypsumResult.suspensions * m).ceil(),
        connectors: (gypsumResult.connectors * m).ceil(),
        insulationArea: gypsumResult.insulationArea,
        sealingTape: gypsumResult.sealingTape * m,
        armatureTape: gypsumResult.armatureTape,
        fillerKg: gypsumResult.fillerKg,
        primerLiters: gypsumResult.primerLiters,
        sheetWeight: gypsumResult.sheetWeight,
        totalWeight: gypsumResult.totalWeight,
      );
    }

    return gypsumResult;
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String? get calculatorId => 'gypsum';

  @override
  Map<String, dynamic>? getCurrentInputs() {
    return {
      'area': _area,
      'construction_type': (_constructionType.index + 1).toDouble(),
      'gkl_type': (_gklType.index + 1).toDouble(),
      'thickness': _thickness.index.toDouble(),
      'sheet_size': _sheetSize.index.toDouble(),
      'layers': _layers.toDouble(),
      'useInsulation': _useInsulation ? 1.0 : 0.0,
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${_loc.translate('gypsum.export.title')}');
    buffer.writeln('═' * 40);
    buffer.writeln();

    // Тип конструкции
    String constructionName;
    switch (_constructionType) {
      case GypsumConstructionType.wallLining:
        constructionName = _loc.translate('gypsum.construction.wall_lining');
        break;
      case GypsumConstructionType.partition:
        constructionName = _loc.translate('gypsum.construction.partition');
        break;
      case GypsumConstructionType.ceiling:
        constructionName = _loc.translate('gypsum.construction.ceiling');
        break;
    }
    buffer.writeln('${_loc.translate('gypsum.export.type')}: $constructionName');
    buffer.writeln('${_loc.translate('gypsum.export.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln();

    buffer.writeln(_loc.translate('gypsum.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('gypsum.export.gkl')} ${_result.sheetSizeName} ${_loc.translate('common.mm')}: ${_result.gklSheets} ${_loc.translate('common.pcs')}');

    if (_result.pnPieces > 0) {
      final String pnName = _constructionType == GypsumConstructionType.wallLining
          ? _loc.translate('gypsum.materials.pn_wall')
          : _constructionType == GypsumConstructionType.partition
              ? _loc.translate('gypsum.materials.pn_partition')
              : _loc.translate('gypsum.materials.pnp_ceiling');
      buffer.writeln('• ${_loc.translate('gypsum.export.profile')} $pnName: ${_result.pnPieces} ${_loc.translate('common.pcs')} ${_loc.translate('gypsum.fixings.profile_length')}');
    }

    if (_result.ppPieces > 0) {
      final String ppName = _constructionType == GypsumConstructionType.partition
          ? _loc.translate('gypsum.materials.ps_partition')
          : _loc.translate('gypsum.materials.pp_wall');
      buffer.writeln('• ${_loc.translate('gypsum.export.profile')} $ppName: ${_result.ppPieces} ${_loc.translate('common.pcs')} ${_loc.translate('gypsum.fixings.profile_length')}');
    }

    if (_result.insulationArea > 0) {
      buffer.writeln('• ${_loc.translate('gypsum.export.insulation')}: ${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    }

    buffer.writeln('• ${_loc.translate('gypsum.export.filler')}: ${_result.fillerKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}');
    buffer.writeln('• ${_loc.translate('gypsum.export.primer')}: ${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}');
    buffer.writeln();

    buffer.writeln(_loc.translate('gypsum.export.fixings_title'));
    buffer.writeln('─' * 40);
    if (_result.screwsTN25 > 0) {
      final formatted = ScrewFormatter.formatWithWeight(
        quantity: _result.screwsTN25,
        diameter: 3.5,
        length: 25,
      );
      buffer.writeln('• ${_loc.translate('gypsum.export.screws_gkl')} 3.5×25: $formatted');
    }
    if (_result.screwsTN35 > 0) {
      final formatted = ScrewFormatter.formatWithWeight(
        quantity: _result.screwsTN35,
        diameter: 3.5,
        length: 35,
      );
      buffer.writeln('• ${_loc.translate('gypsum.export.screws_gkl')} 3.5×35: $formatted');
    }
    if (_result.screwsLN > 0) {
      final formatted = ScrewFormatter.formatWithWeight(
        quantity: _result.screwsLN,
        diameter: 3.5,
        length: 9.5,
      );
      buffer.writeln('• ${_loc.translate('gypsum.export.screws_metal')} 3.5×9.5: $formatted');
    }
    if (_result.dowels > 0) {
      buffer.writeln('• ${_loc.translate('gypsum.export.dowels')}: ${_result.dowels} ${_loc.translate('common.pcs')}');
    }
    if (_result.suspensions > 0) {
      buffer.writeln('• ${_loc.translate('gypsum.export.suspensions')}: ${_result.suspensions} ${_loc.translate('common.pcs')}');
    }
    if (_result.connectors > 0) {
      buffer.writeln('• ${_loc.translate('gypsum.export.connectors')}: ${_result.connectors} ${_loc.translate('common.pcs')}');
    }
    if (_result.sealingTape > 0) {
      buffer.writeln('• ${_loc.translate('gypsum.export.sealing_tape')}: ${_result.sealingTape.toStringAsFixed(1)} ${_loc.translate('common.meters')}');
    }
    buffer.writeln('• ${_loc.translate('gypsum.export.armature_tape')}: ${_result.armatureTape.toStringAsFixed(1)} ${_loc.translate('common.meters')}');
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('gypsum.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate('gypsum.brand'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('gypsum.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('gypsum.summary.sheets').toUpperCase(),
            value: '${_result.gklSheets}',
            icon: Icons.dashboard,
          ),
          ResultItem(
            label: _loc.translate('gypsum.summary.profile').toUpperCase(),
            value: '${(_result.pnMeters + _result.ppMeters).toStringAsFixed(1)} ${_loc.translate('common.meters')}',
            icon: Icons.architecture,
          ),
        ],
      ),
      children: [
        _buildConstructionTypeSelector(),
        const SizedBox(height: 16),
        _buildGKLTypeSelector(),
        const SizedBox(height: 16),
        _buildThicknessSelector(),
        const SizedBox(height: 16),
        _buildSheetSizeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildWallShapeSelector(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildFixingsCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConstructionTypeSelector() {
    const accentColor = CalculatorColors.walls;
    return TypeSelectorGroup(
      options: [
        TypeSelectorOption(
          icon: Icons.border_outer,
          title: _loc.translate('gypsum.construction.wall_lining'),
          subtitle: _loc.translate('gypsum.construction.wall_lining_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.view_column,
          title: _loc.translate('gypsum.construction.partition'),
          subtitle: _loc.translate('gypsum.construction.partition_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.horizontal_rule,
          title: _loc.translate('gypsum.construction.ceiling'),
          subtitle: _loc.translate('gypsum.construction.ceiling_desc'),
        ),
      ],
      selectedIndex: _constructionType.index,
      onSelect: (index) {
        setState(() {
          _constructionType = GypsumConstructionType.values[index];
          _result = _calculate();
        });
      },
      accentColor: accentColor,
    );
  }

  Widget _buildGKLTypeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.gkl_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('gypsum.gkl_type.standard'),
              _loc.translate('gypsum.gkl_type.moisture'),
              _loc.translate('gypsum.gkl_type.fire'),
            ],
            selectedIndex: _gklType.index,
            onSelect: (index) {
              setState(() {
                _gklType = GypsumGKLType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThicknessSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.thickness.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('gypsum.thickness.t9_5'),
              _loc.translate('gypsum.thickness.t12_5'),
            ],
            selectedIndex: _thickness.index,
            onSelect: (index) {
              setState(() {
                _thickness = GypsumThickness.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSheetSizeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.sheet_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: [
              _loc.translate('gypsum.sheet_size.s2000x1200'),
              _loc.translate('gypsum.sheet_size.s2500x1200'),
              _loc.translate('gypsum.sheet_size.s2700x1200'),
              _loc.translate('gypsum.sheet_size.s3000x1200'),
            ],
            selectedIndex: _sheetSize.index,
            onSelect: (index) {
              setState(() {
                _sheetSize = GypsumSheetSize.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWallShapeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.wall_shape.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('gypsum.wall_shape.rectangular'),
              _loc.translate('gypsum.wall_shape.l_shaped'),
              _loc.translate('gypsum.wall_shape.complex'),
            ],
            selectedIndex: _wallShape.index,
            onSelect: (index) {
              setState(() {
                _wallShape = WallShape.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: CalculatorSliderField(
        label: _loc.translate('gypsum.label.area'),
        value: _area,
        min: 1,
        max: 500,
        divisions: 4990,
        suffix: _loc.translate('common.sqm'),
        accentColor: accentColor,
        onChanged: (v) {
          setState(() {
            _area = v;
            _update();
          });
        },
        decimalPlaces: 1,
      ),
    );
  }

  Widget _buildOptionsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.options.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          CalculatorSliderField(
            label: _loc.translate('gypsum.options.layers'),
            value: _layers.toDouble(),
            min: 1,
            max: 2,
            divisions: 1,
            suffix: _loc.translate('gypsum.options.layers_unit'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _layers = v.toInt();
                _update();
              });
            },
            decimalPlaces: 0,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.layers, color: CalculatorColors.walls, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _loc.translate('gypsum.options.insulation'),
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _useInsulation,
                onChanged: (v) {
                  setState(() {
                    _useInsulation = v;
                    _update();
                  });
                },
                activeTrackColor: accentColor.withValues(alpha: 0.5),
                activeThumbColor: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.walls;

    // Определяем названия профилей в зависимости от типа конструкции
    String pnProfileName;
    String ppProfileName;
    if (_result.constructionType == 1) {
      pnProfileName = _loc.translate('gypsum.materials.pn_wall');
      ppProfileName = _loc.translate('gypsum.materials.pp_wall');
    } else if (_result.constructionType == 2) {
      pnProfileName = _loc.translate('gypsum.materials.pn_partition');
      ppProfileName = _loc.translate('gypsum.materials.ps_partition');
    } else {
      pnProfileName = _loc.translate('gypsum.materials.pnp_ceiling');
      ppProfileName = _loc.translate('gypsum.materials.pp_ceiling');
    }

    // Формируем subtitle с размером и весом листа
    final sheetInfo = '${_result.sheetSizeName}, ${_result.sheetWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')}/${_loc.translate('gypsum.materials.sheet')}';
    // Для перегородки пояснить: ×2 = обшивка с обеих сторон
    final sheetSubtitle = _constructionType == GypsumConstructionType.partition
        ? '$sheetInfo • ${_loc.translate('gypsum.construction.partition_desc')}'
        : sheetInfo;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('gypsum.materials.gkl_sheets'),
        value: '${_result.gklSheets} ${_loc.translate('gypsum.materials.sheets_unit')}',
        subtitle: sheetSubtitle,
        icon: Icons.dashboard,
      ),
      MaterialItem(
        name: _loc.translate('gypsum.materials.total_weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('gypsum.materials.weight_info'),
        icon: Icons.fitness_center,
      ),
    ];

    if (_result.pnPieces > 0) {
      items.add(MaterialItem(
        name: pnProfileName,
        value: '${_result.pnPieces} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gypsum.fixings.profile_length'),
        icon: Icons.horizontal_rule,
      ));
    }

    if (_result.ppPieces > 0) {
      items.add(MaterialItem(
        name: ppProfileName,
        value: '${_result.ppPieces} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gypsum.fixings.profile_length'),
        icon: Icons.architecture,
      ));
    }

    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ));
    }

    items.addAll([
      MaterialItem(
        name: _loc.translate('gypsum.materials.filler'),
        value: '${_result.fillerKg.toStringAsFixed(1)} ${_loc.translate('gypsum.materials.kg')}',
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: _loc.translate('gypsum.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('gypsum.materials.liters')}',
        icon: Icons.water_drop,
      ),
    ]);

    return MaterialsCardModern(
      title: _loc.translate('gypsum.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildFixingsCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[];

    if (_result.screwsTN25 > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.screws_gkl_25'),
        value: ScrewFormatter.formatWithWeight(
          quantity: _result.screwsTN25,
          diameter: 3.5,
          length: 25,
        ),
        icon: Icons.hardware,
      ));
    }

    if (_result.screwsTN35 > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.screws_gkl_35'),
        value: ScrewFormatter.formatWithWeight(
          quantity: _result.screwsTN35,
          diameter: 3.5,
          length: 35,
        ),
        icon: Icons.hardware,
      ));
    }

    if (_result.screwsLN > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.screws_metal'),
        value: ScrewFormatter.formatWithWeight(
          quantity: _result.screwsLN,
          diameter: 3.5,
          length: 9.5,
        ),
        icon: Icons.hardware,
      ));
    }

    if (_result.dowels > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.dowels'),
        value: '${_result.dowels} ${_loc.translate('gypsum.fixings.pieces')}',
        icon: Icons.push_pin,
      ));
    }

    if (_result.suspensions > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.suspensions'),
        value: '${_result.suspensions} ${_loc.translate('gypsum.fixings.pieces')}',
        icon: Icons.architecture,
      ));
    }

    if (_result.connectors > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.connectors'),
        value: '${_result.connectors} ${_loc.translate('gypsum.fixings.pieces')}',
        icon: Icons.category,
      ));
    }

    if (_result.sealingTape > 0) {
      items.add(MaterialItem(
        name: _loc.translate('gypsum.fixings.sealing_tape'),
        value: '${_result.sealingTape.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('gypsum.fixings.armature_tape'),
      value: '${_result.armatureTape.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
      icon: Icons.grid_on,
    ));

    return MaterialsCardModern(
      title: _loc.translate('gypsum.fixings.title'),
      titleIcon: Icons.build,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.walls;
    final tips = <String>[
      _loc.translate('hint.gypsum.choose_gklv_for_wet'),
      _loc.translate('hint.gypsum.screw_depth_1mm'),
      _loc.translate('hint.gypsum.joints_offset'),
    ];

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
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
