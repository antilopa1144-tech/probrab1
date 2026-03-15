import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/usecases/calculate_tile_glue.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum InputMode { byDimensions, byArea }
enum BagWeight { kg20, kg25 }
enum SurfaceType { wall, floor }

enum TileType {
  mosaic(6, 0.6, 'tile_adhesive.tile_type.mosaic'),
  ceramic(8, 0.55, 'tile_adhesive.tile_type.ceramic'),
  porcelain(10, 0.55, 'tile_adhesive.tile_type.porcelain'),
  largeFormat(12, 0.8, 'tile_adhesive.tile_type.large_format');

  final int notchSize; // Размер зуба шпателя (мм)
  final double coefficient; // Коэффициент прижатия и нанесения
  final String nameKey;
  const TileType(this.notchSize, this.coefficient, this.nameKey);
}

enum AdhesiveBrand {
  // Ceresit (Henkel) — полная актуальная линейка
  ceresitCM9(1.2, 'Ceresit CM 9', [25]),
  ceresitCM11Pro(1.5, 'Ceresit CM 11 Pro', [25]),
  ceresitCM12(1.6, 'Ceresit CM 12', [25]),
  ceresitCM14(1.8, 'Ceresit CM 14 Extra', [25]),
  ceresitCM16(1.9, 'Ceresit CM 16 Flex', [25]),
  ceresitCM17(1.4, 'Ceresit CM 17 Super Flex', [25]),
  // Unis — актуальная линейка
  unis21(1.4, 'Unis 21 (UniPlus)', [25]),
  unisPlus(1.5, 'Unis Плюс', [25]),
  unis2000(1.6, 'Unis 2000', [25]),
  unisGranit(1.7, 'Unis Гранит', [25]),
  unisBelix(1.6, 'Unis Белфикс', [20, 25]),
  unisU300(1.2, 'Unis U-300 MaxiFlex', [25]),
  // Knauf — актуальная линейка
  knaufFliesen(1.5, 'Knauf Флизен', [25]),
  knaufFlex(1.6, 'Knauf Флекс', [25]),
  knaufMarmor(1.5, 'Knauf Мрамор', [25]),
  // Litokol — актуальная линейка
  litokolX11(1.4, 'Litokol X11', [25]),
  litokolK80(1.6, 'Litokol K80', [25]),
  litokolHyperflex(1.2, 'Litokol Hyperflex K100', [20]),
  // Weber-Vetonit
  weberEasyFix(1.5, 'Weber.Vetonit Easy Fix', [25]),
  weberUltraFix(1.4, 'Weber.Vetonit Ultra Fix', [25]),
  weberProfi(1.6, 'Weber.Vetonit Profi Plus', [25]),
  // Mapei
  mapeiKeraflexMaxi(1.5, 'Mapei Keraflex Maxi', [25]),
  mapeiKerabond(1.3, 'Mapei Kerabond', [25]),
  // Bergauf
  bergaufKeramik(1.4, 'Bergauf Keramik', [25]),
  bergaufMaxi(1.5, 'Bergauf Keramik Maxi', [25]),
  // Волма, Старатели, Основит
  volmaCeramic(1.5, 'Волма Керамик', [25]),
  volmaMulti(1.6, 'Волма Мультиклей', [25]),
  starateliPlus(1.4, 'Старатели Плюс', [25]),
  osnovitMaxiplix(1.5, 'Основит Мастпликс', [25]),
  average(1.5, 'average', [20, 25], localizedNameKey: 'common.average_consumption');

  final double baseConsumption; // Базовый расход (кг/м²/мм)
  final String name;
  final List<int> availableBagSizes;
  final String? localizedNameKey;
  const AdhesiveBrand(this.baseConsumption, this.name, this.availableBagSizes, {this.localizedNameKey});

  String localizedName(AppLocalizations loc) => localizedNameKey != null ? loc.translate(localizedNameKey!) : name;

  bool hasBagSize(int size) => availableBagSizes.contains(size);
  int get defaultBagSize => availableBagSizes.first;
  bool get hasMultipleSizes => availableBagSizes.length > 1;
}

class _TileAdhesiveResult {
  final double area;
  final TileType tileType;
  final AdhesiveBrand brand;
  final SurfaceType surfaceType;
  final int notchSize;
  final double adhesiveConsumption; // кг/м²
  final double totalWeight;
  final int bagsNeeded;
  final int bagWeight;
  final double primerLiters;
  final int crossesNeeded;
  final bool useSVP;
  final int svpCount;
  final double tileWidth;
  final double tileHeight;
  final double? groutWeight;
  final double? waterproofingWeight;

  const _TileAdhesiveResult({
    required this.area,
    required this.tileType,
    required this.brand,
    required this.surfaceType,
    required this.notchSize,
    required this.adhesiveConsumption,
    required this.totalWeight,
    required this.bagsNeeded,
    required this.bagWeight,
    required this.primerLiters,
    required this.crossesNeeded,
    required this.useSVP,
    required this.svpCount,
    required this.tileWidth,
    required this.tileHeight,
    this.groutWeight,
    this.waterproofingWeight,
  });
}

class TileAdhesiveCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const TileAdhesiveCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<TileAdhesiveCalculatorScreen> createState() =>
      _TileAdhesiveCalculatorScreenState();
}

class _TileAdhesiveCalculatorScreenState
    extends State<TileAdhesiveCalculatorScreen> with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('tile_adhesive.export.subject');
  bool _isDark = false;
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  TileType _tileType = TileType.ceramic;
  AdhesiveBrand _adhesiveBrand = AdhesiveBrand.average;
  BagWeight _bagWeight = BagWeight.kg25;
  SurfaceType _surfaceType = SurfaceType.wall;
  bool _useSVP = false;
  bool _calculateGrout = false;
  bool _useWaterproofing = false;
  late _TileAdhesiveResult _result;
  late AppLocalizations _loc;
  final CalculateTileGlue _calculator = CalculateTileGlue();


  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['inputMode'] != null) {
      final inputMode = initial['inputMode']!.round().clamp(0, 1);
      _inputMode = InputMode.values[inputMode];
    }
    if (initial['area'] != null) {
      _area = initial['area']!.clamp(1.0, 1000.0);
      if (!initial.containsKey('length') && !initial.containsKey('width')) {
        _inputMode = InputMode.byArea;
      }
    }
    if (initial['length'] != null) {
      _length = initial['length']!.clamp(0.1, 100.0);
      _inputMode = InputMode.byDimensions;
    }
    if (initial['width'] != null) {
      _width = initial['width']!.clamp(0.1, 100.0);
      _inputMode = InputMode.byDimensions;
    }
    if (initial['tileType'] != null) {
      _tileType = TileType.values[initial['tileType']!.round().clamp(0, TileType.values.length - 1)];
    }
    if (initial['adhesiveBrand'] != null) {
      _adhesiveBrand = AdhesiveBrand.values[initial['adhesiveBrand']!.round().clamp(0, AdhesiveBrand.values.length - 1)];
    }
    if (initial['surfaceType'] != null) {
      _surfaceType = SurfaceType.values[initial['surfaceType']!.round().clamp(0, SurfaceType.values.length - 1)];
    }
    if ((initial['useSVP'] ?? 0) > 0) _useSVP = true;
    if ((initial['calculateGrout'] ?? 0) > 0) _calculateGrout = true;
    if ((initial['useWaterproofing'] ?? 0) > 0) _useWaterproofing = true;
    if (initial['bagWeight'] != null) {
      final requestedBagWeight = initial['bagWeight']!.round();
      if (_adhesiveBrand.hasBagSize(requestedBagWeight)) {
        _bagWeight = requestedBagWeight == 20 ? BagWeight.kg20 : BagWeight.kg25;
      }
    }
    final currentBagWeight = _bagWeight == BagWeight.kg20 ? 20 : 25;
    if (!_adhesiveBrand.hasBagSize(currentBagWeight)) {
      _bagWeight = _adhesiveBrand.defaultBagSize == 20 ? BagWeight.kg20 : BagWeight.kg25;
    }
  }

  Map<String, double> _buildCalculationInputs() {
    return {
      'inputMode': _inputMode.index.toDouble(),
      'area': _area,
      'length': _length,
      'width': _width,
      'tileType': _tileType.index.toDouble(),
      'adhesiveBrand': _adhesiveBrand.index.toDouble(),
      'bagWeight': (_bagWeight == BagWeight.kg20 ? 20 : 25).toDouble(),
      'surfaceType': _surfaceType.index.toDouble(),
      'useSVP': _useSVP ? 1.0 : 0.0,
      'calculateGrout': _calculateGrout ? 1.0 : 0.0,
      'useWaterproofing': _useWaterproofing ? 1.0 : 0.0,
    };
  }

  _TileAdhesiveResult _calculate() {
    final values = _calculator(_buildCalculationInputs(), const []).values;
    final bagWeightKg = (values['bagWeight'] ?? (_bagWeight == BagWeight.kg20 ? 20 : 25)).round();

    return _TileAdhesiveResult(
      area: values['area'] ?? 0,
      tileType: _tileType,
      brand: _adhesiveBrand,
      surfaceType: _surfaceType,
      notchSize: (values['notchSize'] ?? _tileType.notchSize.toDouble()).round(),
      adhesiveConsumption: values['consumptionPerM2'] ?? 0,
      totalWeight: values['glueNeeded'] ?? 0,
      bagsNeeded: (values['bagsNeeded'] ?? 0).round(),
      bagWeight: bagWeightKg,
      primerLiters: values['primerNeeded'] ?? 0,
      crossesNeeded: (values['crossesNeeded'] ?? 0).round(),
      useSVP: _useSVP,
      svpCount: (values['svpCount'] ?? 0).round(),
      tileWidth: values['tileWidth'] ?? 30,
      tileHeight: values['tileHeight'] ?? 30,
      groutWeight: _calculateGrout ? values['groutWeight'] : null,
      waterproofingWeight: _useWaterproofing ? values['waterproofingWeight'] : null,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('tile_adhesive.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln(_loc.translate('tile_adhesive.export.area').replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('tile_adhesive.export.tile_type').replaceFirst('{value}', _loc.translate(_result.tileType.nameKey)));
    buffer.writeln(_loc.translate('tile_adhesive.export.tile_size')
        .replaceFirst('{width}', _result.tileWidth.toStringAsFixed(0))
        .replaceFirst('{height}', _result.tileHeight.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('tile_adhesive.export.notch_size').replaceFirst('{value}', _result.notchSize.toString()));
    final surfaceKey = _result.surfaceType == SurfaceType.wall
        ? 'tile_adhesive.export.surface_wall'
        : 'tile_adhesive.export.surface_floor';
    buffer.writeln(_loc.translate('tile_adhesive.export.surface').replaceFirst('{value}', _loc.translate(surfaceKey)));
    buffer.writeln();

    buffer.writeln(_loc.translate('tile_adhesive.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.adhesive_line').replaceFirst('{bags}', _result.bagsNeeded.toString()).replaceFirst('{weight}', _result.bagWeight.toString())}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.consumption_line').replaceFirst('{value}', _result.adhesiveConsumption.toStringAsFixed(2))}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.total_weight_line').replaceFirst('{value}', _result.totalWeight.toStringAsFixed(1))}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.primer_line').replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1))}');
    if (_result.groutWeight != null) {
      buffer.writeln('• ${_loc.translate('tile_adhesive.export.grout_line').replaceFirst('{value}', _result.groutWeight!.toStringAsFixed(2))}');
    }
    if (_result.waterproofingWeight != null) {
      buffer.writeln('• ${_loc.translate('tile_adhesive.export.waterproofing_line').replaceFirst('{value}', _result.waterproofingWeight!.toStringAsFixed(1))}');
    }
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.crosses_line').replaceFirst('{value}', _result.crossesNeeded.toString())}');
    if (_result.useSVP) {
      buffer.writeln('• ${_loc.translate('tile_adhesive.export.svp_line').replaceFirst('{value}', _result.svpCount.toString())}');
    }
    buffer.writeln();

    buffer.writeln(_loc.translate('tile_adhesive.export.tools_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.trowel_line').replaceFirst('{value}', _result.notchSize.toString())}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.container_line')}');
    buffer.writeln('• ${_loc.translate('tile_adhesive.export.mixer_line')}');
    buffer.writeln();

    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('tile_adhesive.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('tile_adhesive.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('tile_adhesive.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('tile_adhesive.summary.bags').toUpperCase(),
            value: '${_result.bagsNeeded}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('tile_adhesive.summary.consumption').toUpperCase(),
            value: '${_result.adhesiveConsumption.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg_per_m2')}',
            icon: Icons.scale,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea
            ? _buildAreaCard()
            : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildSurfaceTypeSelector(),
        const SizedBox(height: 16),
        _buildTileTypeSelector(),
        const SizedBox(height: 16),
        _buildAdhesiveBrandSelector(),
        if (_adhesiveBrand.hasMultipleSizes) ...[
          const SizedBox(height: 16),
          _buildBagWeightSelector(),
        ],
        const SizedBox(height: 16),
        _buildSVPToggle(),
        const SizedBox(height: 16),
        _buildGroutToggle(),
        const SizedBox(height: 16),
        _buildWaterproofingToggle(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildToolsCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('tile_adhesive.input_mode.by_dimensions'),
              _loc.translate('tile_adhesive.input_mode.by_area'),
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
    const accentColor = CalculatorColors.interior;
    return _card(
      child: CalculatorSliderField(
        label: _loc.translate('tile_adhesive.label.area'),
        value: _area,
        min: 1,
        max: 500,
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

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('tile_adhesive.dimensions.length'),
            value: _length,
            min: 0.5,
            max: 50.0,
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
            label: _loc.translate('tile_adhesive.dimensions.width'),
            value: _width,
            min: 0.5,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _width = v;
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
                  _loc.translate('tile_adhesive.dimensions.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
                Text(
                  '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
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
    return CalculatorSliderField(
      label: label,
      value: value,
      min: min,
      max: max,
      divisions: ((max - min) * 10).toInt(),
      suffix: _loc.translate('common.meters'),
      accentColor: accentColor,
      onChanged: onChanged,
      decimalPlaces: 1,
    );
  }

  Widget _buildSurfaceTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.surface_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('tile_adhesive.surface_type.wall'),
              _loc.translate('tile_adhesive.surface_type.floor'),
            ],
            selectedIndex: _surfaceType.index,
            onSelect: (index) {
              setState(() {
                _surfaceType = SurfaceType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTileTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.tile_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('tile_adhesive.tile_type.subtitle'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: TileType.values.map((type) => _loc.translate(type.nameKey)).toList(),
            selectedIndex: _tileType.index,
            onSelect: (index) {
              setState(() {
                _tileType = TileType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAdhesiveBrandSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.brand.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options:
                AdhesiveBrand.values.map((brand) => brand.localizedName(_loc)).toList(),
            selectedIndex: _adhesiveBrand.index,
            onSelect: (index) {
              setState(() {
                _adhesiveBrand = AdhesiveBrand.values[index];
                // Автоматически устанавливаем доступный вес мешка
                final currentBagWeight = _bagWeight == BagWeight.kg20 ? 20 : 25;
                if (!_adhesiveBrand.hasBagSize(currentBagWeight)) {
                  _bagWeight = _adhesiveBrand.defaultBagSize == 20
                      ? BagWeight.kg20
                      : BagWeight.kg25;
                }
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBagWeightSelector() {
    if (!_adhesiveBrand.hasMultipleSizes) {
      return const SizedBox.shrink();
    }

    const accentColor = CalculatorColors.interior;
    final availableSizes = _adhesiveBrand.availableBagSizes;

    final options = <String>[];
    final indexMapping = <int, BagWeight>{};
    int currentMappedIndex = 0;

    for (var i = 0; i < BagWeight.values.length; i++) {
      final weight = BagWeight.values[i];
      final weightKg = weight == BagWeight.kg20 ? 20 : 25;

      if (availableSizes.contains(weightKg)) {
        options.add(_loc.translate('tile_adhesive.bag_weight.kg$weightKg'));
        indexMapping[currentMappedIndex] = weight;
        currentMappedIndex++;
      }
    }

    final currentWeightKg = _bagWeight == BagWeight.kg20 ? 20 : 25;
    final selectedIndex = availableSizes.indexOf(currentWeightKg);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.bag_weight.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: options,
            selectedIndex: selectedIndex.clamp(0, options.length - 1),
            onSelect: (index) {
              setState(() {
                _bagWeight = indexMapping[index]!;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSVPToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('tile_adhesive.svp.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.getTextPrimary(_isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.svp.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useSVP,
            onChanged: (value) {
              setState(() {
                _useSVP = value;
                _update();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGroutToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('tile_adhesive.grout.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.getTextPrimary(_isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.grout.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _calculateGrout,
            onChanged: (value) {
              setState(() {
                _calculateGrout = value;
                _update();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWaterproofingToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('tile_adhesive.waterproofing.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.getTextPrimary(_isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.waterproofing.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useWaterproofing,
            onChanged: (value) {
              setState(() {
                _useWaterproofing = value;
                _update();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.adhesive'),
        value: '${_result.bagsNeeded} ${_loc.translate('tile_adhesive.materials.bags_unit')}',
        subtitle: '× ${_result.bagWeight} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.consumption'),
        value: '${_result.adhesiveConsumption.toStringAsFixed(2)} ${_loc.translate('tile_adhesive.materials.kg_per_m2')}',
        icon: Icons.info_outline,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.total_weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.scale,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.liters')}',
        icon: Icons.water_drop,
      ),
    ];

    if (_result.groutWeight != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile_adhesive.materials.grout'),
        value: '${_result.groutWeight!.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.gradient,
      ));
    }

    if (_result.waterproofingWeight != null) {
      items.add(MaterialItem(
        name: _loc.translate('tile_adhesive.materials.waterproofing'),
        value: '${_result.waterproofingWeight!.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.water,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('tile_adhesive.materials.crosses'),
      value: '${_result.crossesNeeded} ${_loc.translate('tile_adhesive.materials.pieces')}',
      icon: Icons.add,
    ));

    if (_result.useSVP) {
      items.add(MaterialItem(
        name: _loc.translate('tile_adhesive.materials.svp'),
        value: '${_result.svpCount} ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.construction,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('tile_adhesive.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildToolsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('tile_adhesive.tools.notched_trowel'),
        value: '${_result.notchSize} ${_loc.translate('common.mm')}',
        icon: Icons.handyman,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.tools.mixing_container'),
        value: '1 ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.shopping_basket,
      ),
      MaterialItem(
        name: _loc.translate('tile_adhesive.tools.mixer'),
        value: '1 ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.blender,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('tile_adhesive.tools.title'),
      titleIcon: Icons.build_circle,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[];

    // Динамические предупреждения по бренду
    if (_adhesiveBrand == AdhesiveBrand.ceresitCM9 &&
        _tileType != TileType.mosaic &&
        _tileType != TileType.ceramic) {
      tips.add(_loc.translate('hint.tile_adhesive.cm9_small_tile_only'));
    }
    if (_adhesiveBrand == AdhesiveBrand.ceresitCM16) {
      tips.add(_loc.translate('hint.tile_adhesive.cm16_deformable'));
    }

    tips.addAll([
      _loc.translate('hint.tile_adhesive.surface_preparation'),
      _loc.translate('hint.tile_adhesive.notch_size'),
      _loc.translate('hint.tile_adhesive.mixing'),
      _loc.translate('hint.tile_adhesive.application'),
      _loc.translate('hint.tile_adhesive.working_time'),
    ]);

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



