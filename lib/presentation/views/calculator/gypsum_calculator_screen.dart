import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../providers/constants_provider.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';
import '../../utils/screw_formatter.dart';

enum GypsumConstructionType { wallLining, partition, ceiling }
enum GypsumGKLType { standard, moisture, fire }
enum GypsumSheetSize { s2000x1200, s2500x1200, s2700x1200, s3000x1200 }
enum InputMode { byArea, byRoom }

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
  });
}

/// Helper class for accessing gypsum calculator constants with type safety and fallbacks
class _GypsumConstants {
  final CalculatorConstants? _data;

  const _GypsumConstants(this._data);

  T _get<T>(String constantKey, String valueKey, T defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value == null) return defaultValue;
    if (value is T) return value;
    if (T == double && value is int) return value.toDouble() as T;
    if (T == int && value is double) return value.toInt() as T;
    return defaultValue;
  }

  // Sheet sizes - returns area in m² for given sheet size
  double getSheetArea(GypsumSheetSize size) {
    final sizeMap = {
      GypsumSheetSize.s2000x1200: 's2000x1200',
      GypsumSheetSize.s2500x1200: 's2500x1200',
      GypsumSheetSize.s2700x1200: 's2700x1200',
      GypsumSheetSize.s3000x1200: 's3000x1200',
    };
    final defaultAreas = {
      GypsumSheetSize.s2000x1200: 2.4,
      GypsumSheetSize.s2500x1200: 3.0,
      GypsumSheetSize.s2700x1200: 3.24,
      GypsumSheetSize.s3000x1200: 3.6,
    };
    return _get('sheet_sizes', sizeMap[size]!, defaultAreas[size]!);
  }

  // GKL multipliers
  double getGklBaseMultiplier() => _get('gkl_multiplier', 'base', 1.05);
  double getGklPartitionMultiplier() => _get('gkl_multiplier', 'partition', 2.0);

  // Profile standard length
  double getProfileLength() => _get('profile_length', 'standard', 3.0);

  // Wall lining constants (облицовка стен)
  double getWallLiningPnMeters() => _get('wall_lining', 'pn_meters', 0.8);
  double getWallLiningPpMeters() => _get('wall_lining', 'pp_meters', 2.0);
  double getWallLiningSuspensions() => _get('wall_lining', 'suspensions', 1.3);
  double getWallLiningDowels() => _get('wall_lining', 'dowels', 1.6);
  int getWallLiningScrewsTN25() => _get<int>('wall_lining', 'screws_tn25', 34);
  int getWallLiningScrewsLN() => _get<int>('wall_lining', 'screws_ln', 4);
  double getWallLiningSealingTape() => _get('wall_lining', 'sealing_tape', 0.8);

  // Partition constants (перегородки)
  double getPartitionPnMeters() => _get('partition', 'pn_meters', 0.7);
  double getPartitionPpMeters() => _get('partition', 'pp_meters', 2.0);
  double getPartitionDowels() => _get('partition', 'dowels', 1.5);
  int getPartitionScrewsTN25() => _get<int>('partition', 'screws_tn25', 50);
  int getPartitionScrewsLN() => _get<int>('partition', 'screws_ln', 4);
  double getPartitionSealingTape() => _get('partition', 'sealing_tape', 1.2);

  // Ceiling constants (потолки)
  double getCeilingPnMeters() => _get('ceiling', 'pn_meters', 0.4);
  double getCeilingPpMeters() => _get('ceiling', 'pp_meters', 3.3);
  double getCeilingSuspensions() => _get('ceiling', 'suspensions', 0.7);
  double getCeilingConnectors() => _get('ceiling', 'connectors', 2.4);
  int getCeilingDowelsPerSuspension() => _get<int>('ceiling', 'dowels_per_suspension', 2);
  int getCeilingScrewsTN25() => _get<int>('ceiling', 'screws_tn25', 23);
  int getCeilingScrewsLN() => _get<int>('ceiling', 'screws_ln', 7);

  // Second layer constants
  int getSecondLayerScrewsTN35() => _get<int>('second_layer', 'screws_tn35', 17);
  int getSecondLayerPartitionMultiplier() => _get<int>('second_layer', 'partition_multiplier', 2);

  // Materials
  double getInsulationMargin() => _get('materials', 'insulation_margin', 1.05);
  double getArmatureTape() => _get('materials', 'armature_tape', 1.2);
  double getFillerStandard() => _get('materials', 'filler_standard', 0.3);
  double getFillerPartition() => _get('materials', 'filler_partition', 0.6);
  double getPrimer() => _get('materials', 'primer', 0.1);
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
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 4.0;
  double _width = 3.0;
  double _height = 2.7;
  int _layers = 1;
  bool _useInsulation = false;
  GypsumConstructionType _constructionType = GypsumConstructionType.wallLining;
  GypsumGKLType _gklType = GypsumGKLType.standard;
  GypsumSheetSize _sheetSize = GypsumSheetSize.s2500x1200;
  late _GypsumResult _result;
  late AppLocalizations _loc;
  late _GypsumConstants _constants;

  @override
  void initState() {
    super.initState();
    // Initialize constants from provider
    final constantsAsync = ref.read(calculatorConstantsProvider('gypsum'));
    _constants = _GypsumConstants(constantsAsync.value);
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

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }

    // Расчёт площади по размерам комнаты
    switch (_constructionType) {
      case GypsumConstructionType.wallLining:
        // Площадь стен: периметр × высота
        return (_length + _width) * 2 * _height;
      case GypsumConstructionType.partition:
        // Площадь перегородки: длина × высота
        return _length * _height;
      case GypsumConstructionType.ceiling:
        // Площадь потолка: длина × ширина
        return _length * _width;
    }
  }

  _GypsumResult _calculate() {
    // Получаем площадь в зависимости от режима ввода
    final calculatedArea = _getCalculatedArea();

    // Определяем площадь листа в зависимости от выбранного размера
    final sheetArea = _constants.getSheetArea(_sheetSize);
    String sheetSizeName;
    switch (_sheetSize) {
      case GypsumSheetSize.s2000x1200:
        sheetSizeName = '2000×1200';
        break;
      case GypsumSheetSize.s2500x1200:
        sheetSizeName = '2500×1200';
        break;
      case GypsumSheetSize.s2700x1200:
        sheetSizeName = '2700×1200';
        break;
      case GypsumSheetSize.s3000x1200:
        sheetSizeName = '3000×1200';
        break;
    }

    double gklMultiplier = _constants.getGklBaseMultiplier();

    if (_constructionType == GypsumConstructionType.partition) {
      gklMultiplier *= _constants.getGklPartitionMultiplier();
    }

    final gklArea = calculatedArea * _layers * gklMultiplier;
    final gklSheets = (gklArea / sheetArea).ceil();

    // Стандартная длина профиля
    final profileLength = _constants.getProfileLength();

    double pnMeters = 0;
    double ppMeters = 0;
    int pnPieces = 0;
    int ppPieces = 0;
    int screwsTN25 = 0;
    int screwsTN35 = 0;
    int screwsLN = 0;
    int dowels = 0;
    int suspensions = 0;
    int connectors = 0;
    double sealingTape = 0;

    if (_constructionType == GypsumConstructionType.wallLining) {
      pnMeters = calculatedArea * _constants.getWallLiningPnMeters();
      ppMeters = calculatedArea * _constants.getWallLiningPpMeters();
      pnPieces = (pnMeters / profileLength).ceil();
      ppPieces = (ppMeters / profileLength).ceil();
      suspensions = (calculatedArea * _constants.getWallLiningSuspensions()).ceil();
      dowels = (calculatedArea * _constants.getWallLiningDowels()).ceil();
      screwsTN25 = (calculatedArea * _constants.getWallLiningScrewsTN25()).ceil();
      screwsLN = (calculatedArea * _constants.getWallLiningScrewsLN()).ceil();
      sealingTape = calculatedArea * _constants.getWallLiningSealingTape();
    } else if (_constructionType == GypsumConstructionType.partition) {
      pnMeters = calculatedArea * _constants.getPartitionPnMeters();
      ppMeters = calculatedArea * _constants.getPartitionPpMeters();
      pnPieces = (pnMeters / profileLength).ceil();
      ppPieces = (ppMeters / profileLength).ceil();
      dowels = (calculatedArea * _constants.getPartitionDowels()).ceil();
      screwsTN25 = (calculatedArea * _constants.getPartitionScrewsTN25()).ceil();
      screwsLN = (calculatedArea * _constants.getPartitionScrewsLN()).ceil();
      sealingTape = calculatedArea * _constants.getPartitionSealingTape();
    } else if (_constructionType == GypsumConstructionType.ceiling) {
      pnMeters = calculatedArea * _constants.getCeilingPnMeters();
      ppMeters = calculatedArea * _constants.getCeilingPpMeters();
      pnPieces = (pnMeters / profileLength).ceil();
      ppPieces = (ppMeters / profileLength).ceil();
      suspensions = (calculatedArea * _constants.getCeilingSuspensions()).ceil();
      connectors = (calculatedArea * _constants.getCeilingConnectors()).ceil();
      dowels = (suspensions * _constants.getCeilingDowelsPerSuspension());
      screwsTN25 = (calculatedArea * _constants.getCeilingScrewsTN25()).ceil();
      screwsLN = (calculatedArea * _constants.getCeilingScrewsLN()).ceil();
    }

    if (_layers == 2) {
      final multiplier = _constructionType == GypsumConstructionType.partition
          ? _constants.getSecondLayerPartitionMultiplier()
          : 1;
      screwsTN35 = (calculatedArea * _constants.getSecondLayerScrewsTN35() * multiplier).ceil();
    }

    final insulationArea = _useInsulation ? calculatedArea * _constants.getInsulationMargin() : 0.0;
    final armatureTape = calculatedArea * _constants.getArmatureTape();
    final fillerKg = calculatedArea * (_constructionType == GypsumConstructionType.partition
        ? _constants.getFillerPartition()
        : _constants.getFillerStandard()) * _layers;
    final primerLiters = calculatedArea * _constants.getPrimer();

    return _GypsumResult(
      area: calculatedArea,
      gklSheets: gklSheets,
      sheetArea: sheetArea,
      sheetSizeName: sheetSizeName,
      constructionType: _constructionType.index + 1,
      pnPieces: pnPieces,
      pnMeters: pnMeters,
      ppPieces: ppPieces,
      ppMeters: ppMeters,
      screwsTN25: screwsTN25,
      screwsTN35: screwsTN35,
      screwsLN: screwsLN,
      dowels: dowels,
      suspensions: suspensions,
      connectors: connectors,
      insulationArea: insulationArea,
      sealingTape: sealingTape,
      armatureTape: armatureTape,
      fillerKg: fillerKg,
      primerLiters: primerLiters,
    );
  }

  void _update() => setState(() => _result = _calculate());

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
        _buildSheetSizeSelector(),
        const SizedBox(height: 16),
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea ? _buildAreaCard() : _buildRoomDimensionsCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildFixingsCard(),
        const SizedBox(height: 24),
        _buildTipsSection(),
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
              color: CalculatorColors.textPrimary,
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

  Widget _buildSheetSizeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.sheet_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('gypsum.input_mode.by_area'),
              _loc.translate('gypsum.input_mode.by_room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = InputMode.values[index];
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('gypsum.label.area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 1,
            max: 500,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDimensionsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('gypsum.room.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('gypsum.room.length'),
            value: _length,
            min: 1.0,
            max: 20.0,
            onChanged: (v) {
              setState(() {
                _length = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('gypsum.room.width'),
            value: _width,
            min: 1.0,
            max: 20.0,
            onChanged: (v) {
              setState(() {
                _width = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('gypsum.room.height'),
            value: _height,
            min: 2.0,
            max: 5.0,
            onChanged: (v) {
              setState(() {
                _height = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loc.translate('gypsum.room.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
              style: CalculatorDesignSystem.titleMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('gypsum.options.layers'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '$_layers ${_loc.translate('gypsum.options.layers_unit')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _layers.toDouble(),
            min: 1,
            max: 2,
            divisions: 1,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _layers = v.toInt();
                _update();
              });
            },
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
                      color: CalculatorColors.textSecondary,
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

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('gypsum.materials.gkl_sheets'),
        value: '${_result.gklSheets} ${_loc.translate('gypsum.materials.sheets_unit')}',
        subtitle: _result.sheetSizeName,
        icon: Icons.dashboard,
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

  Widget _buildTipsSection() {
    const hints = [
      CalculatorHint(type: HintType.important, messageKey: 'hint.gypsum.choose_gklv_for_wet'),
      CalculatorHint(type: HintType.tip, messageKey: 'hint.gypsum.screw_depth_1mm'),
      CalculatorHint(type: HintType.tip, messageKey: 'hint.gypsum.joints_offset'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _loc.translate('common.tips'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
        ),
        const HintsList(hints: hints),
      ],
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
