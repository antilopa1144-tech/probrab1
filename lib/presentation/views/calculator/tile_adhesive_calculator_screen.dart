import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

enum InputMode { byDimensions, byArea }
enum BagWeight { kg20, kg25 }
enum SurfaceType { wall, floor }

enum TileType {
  mosaic(6, 0.6, 'Мозаика / мелкая'),
  ceramic(8, 0.55, 'Керамическая плитка'),
  porcelain(10, 0.55, 'Керамогранит'),
  largeFormat(12, 0.8, 'Крупноформат');

  final int notchSize; // Размер зуба шпателя (мм)
  final double coefficient; // Коэффициент прижатия и нанесения
  final String name;
  const TileType(this.notchSize, this.coefficient, this.name);
}

enum AdhesiveBrand {
  ceresitCM11(1.5, 'Ceresit CM 11', [25]),
  ceresitCM12(1.6, 'Ceresit CM 12', [25]),
  ceresitCM14(1.8, 'Ceresit CM 14', [25]),
  ceresitCM17(1.8, 'Ceresit CM 17', [25]),
  unis21(1.4, 'Unis 21 (UniPlus)', [25]),
  unisPlus(1.5, 'Unis Плюс', [25]),
  unis2000(1.6, 'Unis 2000', [25]),
  unisGranit(1.7, 'Unis Гранит', [25]),
  unisBelix(1.6, 'Unis Белфикс', [20, 25]),
  knaufFliesen(1.5, 'Knauf Флизен', [25]),
  knaufFlex(1.6, 'Knauf Флекс', [25]),
  litokolX11(1.4, 'Litokol X11', [25]),
  litokolK80(1.6, 'Litokol K80', [25]),
  volmaCeramic(1.5, 'Волма Керамик', [25]),
  average(1.5, 'Средний расход', [20, 25]);

  final double baseConsumption; // Базовый расход (кг/м²/мм)
  final String name;
  final List<int> availableBagSizes;
  const AdhesiveBrand(this.baseConsumption, this.name, this.availableBagSizes);

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
    extends State<TileAdhesiveCalculatorScreen> {
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
    if (initial['length'] != null) {
      _length = initial['length']!.clamp(0.1, 100.0);
    }
    if (initial['width'] != null) _width = initial['width']!.clamp(0.1, 100.0);
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _TileAdhesiveResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Правильная формула расчета плиточного клея:
    // Расход = Базовый_расход × Размер_зуба × Коэффициент × Коэффициент_поверхности

    final notchSize = _tileType.notchSize;
    final coefficient = _tileType.coefficient;
    final surfaceFactor = _surfaceType == SurfaceType.wall ? 1.1 : 1.0;

    // Расход клея на м² (кг/м²)
    final adhesiveConsumption =
        _adhesiveBrand.baseConsumption * notchSize * coefficient * surfaceFactor;

    // Общий вес с запасом +10%
    final totalWeight = calculatedArea * adhesiveConsumption * 1.1;

    // Вес мешка
    final bagWeightKg = _bagWeight == BagWeight.kg20 ? 20 : 25;

    // Количество мешков
    final bagsNeeded = (totalWeight / bagWeightKg).ceil();

    // Грунтовка (0.15 л/м²)
    final primerLiters = calculatedArea * 0.15;

    // Стандартные размеры плитки в зависимости от типа
    final tileWidth = _tileType == TileType.mosaic
        ? 10.0 // см
        : _tileType == TileType.ceramic
            ? 30.0
            : _tileType == TileType.porcelain
                ? 40.0
                : 60.0; // крупноформат

    final tileHeight = tileWidth; // квадратная плитка

    // Рассчитываем количество плиток на основе стандартного размера
    final tileAreaM2 = (tileWidth / 100) * (tileHeight / 100);
    final tilesCount = (calculatedArea / tileAreaM2).ceil();

    // Крестики для швов: ~5 шт на плитку
    final crossesNeeded = tilesCount * 5;

    // СВП (система выравнивания плитки): количество клипс зависит от размера плитки
    // Маленькая плитка (<20 см): 4 клипсы
    // Средняя плитка (20-40 см): 3 клипсы
    // Большая плитка (>40 см): 2 клипсы
    final avgTileSize = (tileWidth + tileHeight) / 2;
    final clipsPerTile = avgTileSize < 20 ? 4 : (avgTileSize <= 40 ? 3 : 2);
    final svpCount = _useSVP ? tilesCount * clipsPerTile : 0;

    // Расчет затирки (опционально)
    double? groutWeight;
    if (_calculateGrout) {
      // Стандартные параметры затирки
      const jointWidth = 3.0; // мм
      const jointDepth = 2.0; // мм
      // Формула: (Длина + Ширина) / (Длина × Ширина) × Ширина_шва × Глубина_шва × Плотность × Площадь
      // Плотность затирки ~1.6 кг/дм³
      const groutDensity = 1.6; // кг/дм³
      final groutConsumptionPerM2 =
          ((tileWidth + tileHeight) / (tileWidth * tileHeight)) *
          jointWidth *
          jointDepth *
          groutDensity;
      groutWeight = calculatedArea * groutConsumptionPerM2 * 1.1; // +10% запас
    }

    // Гидроизоляция (опционально)
    double? waterproofingWeight;
    if (_useWaterproofing) {
      // 2 слоя по 0.4 кг/м²
      waterproofingWeight = calculatedArea * 0.4 * 2;
    }

    return _TileAdhesiveResult(
      area: calculatedArea,
      tileType: _tileType,
      brand: _adhesiveBrand,
      surfaceType: _surfaceType,
      notchSize: notchSize,
      adhesiveConsumption: adhesiveConsumption,
      totalWeight: totalWeight,
      bagsNeeded: bagsNeeded,
      bagWeight: bagWeightKg,
      primerLiters: primerLiters,
      crossesNeeded: crossesNeeded,
      useSVP: _useSVP,
      svpCount: svpCount,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      groutWeight: groutWeight,
      waterproofingWeight: waterproofingWeight,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 РАСЧЁТ МАТЕРИАЛОВ ДЛЯ УКЛАДКИ ПЛИТКИ');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('Площадь: ${_result.area.toStringAsFixed(1)} м²');
    buffer.writeln('Тип плитки: ${_result.tileType.name}');
    buffer.writeln('Размер плитки: ${_result.tileWidth.toStringAsFixed(0)}×${_result.tileHeight.toStringAsFixed(0)} см');
    buffer.writeln('Размер зуба шпателя: ${_result.notchSize} мм');
    buffer.writeln('Поверхность: ${_result.surfaceType == SurfaceType.wall ? "Стена" : "Пол"}');
    buffer.writeln();

    buffer.writeln('📦 МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('• Плиточный клей: ${_result.bagsNeeded} ${_loc.translate('tile_adhesive.materials.bags_unit')} по ${_result.bagWeight} кг');
    buffer.writeln('• Расход: ${_result.adhesiveConsumption.toStringAsFixed(2)} кг/м²');
    buffer.writeln('• Общий вес: ${_result.totalWeight.toStringAsFixed(1)} кг');
    buffer.writeln('• Грунтовка: ${_result.primerLiters.toStringAsFixed(1)} л');
    if (_result.groutWeight != null) {
      buffer.writeln('• Затирка: ${_result.groutWeight!.toStringAsFixed(2)} кг');
    }
    if (_result.waterproofingWeight != null) {
      buffer.writeln('• Гидроизоляция: ${_result.waterproofingWeight!.toStringAsFixed(1)} кг (2 слоя)');
    }
    buffer.writeln('• Крестики: ${_result.crossesNeeded} шт');
    if (_result.useSVP) {
      buffer.writeln('• СВП (клипсы + клинья): ${_result.svpCount} шт');
    }
    buffer.writeln();

    buffer.writeln('🛠 ИНСТРУМЕНТЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('• Зубчатый шпатель: ${_result.notchSize} мм');
    buffer.writeln('• Ёмкость для замешивания');
    buffer.writeln('• Миксер строительный');
    buffer.writeln();

    buffer.writeln('═' * 40);
    buffer.writeln('Создано с помощью Калькулятора Стройматериалов');

    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(
      ShareParams(text: text, subject: 'Расчёт материалов для укладки плитки'),
    );
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('tile_adhesive.title'),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('tile_adhesive.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('tile_adhesive.summary.bags').toUpperCase(),
            value: '${_result.bagsNeeded}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('tile_adhesive.summary.consumption').toUpperCase(),
            value: '${_result.adhesiveConsumption.toStringAsFixed(1)} кг/м²',
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
        _buildTipsSection(),
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
              color: CalculatorColors.textPrimary,
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('tile_adhesive.label.area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '${_area.toStringAsFixed(1)} м²',
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

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
                    color: CalculatorColors.textSecondary,
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} м²',
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
              '${value.toStringAsFixed(1)} м',
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

  Widget _buildSurfaceTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('tile_adhesive.surface_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('tile_adhesive.tile_type.subtitle'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: TileType.values.map((type) => type.name).toList(),
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options:
                AdhesiveBrand.values.map((brand) => brand.name).toList(),
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
              color: CalculatorColors.textPrimary,
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
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.svp.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
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
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.grout.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
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
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('tile_adhesive.waterproofing.subtitle'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
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

    final results = <ResultRowItem>[
      ResultRowItem(
        label: _loc.translate('tile_adhesive.materials.adhesive'),
        value:
            '${_result.bagsNeeded} ${_loc.translate('tile_adhesive.materials.bags_unit')} × ${_result.bagWeight} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.shopping_bag,
      ),
      ResultRowItem(
        label: _loc.translate('tile_adhesive.materials.consumption'),
        value:
            '${_result.adhesiveConsumption.toStringAsFixed(2)} ${_loc.translate('tile_adhesive.materials.kg_per_m2')}',
        icon: Icons.info_outline,
      ),
      ResultRowItem(
        label: _loc.translate('tile_adhesive.materials.total_weight'),
        value:
            '${_result.totalWeight.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg')}',
        icon: Icons.scale,
      ),
      ResultRowItem(
        label: _loc.translate('tile_adhesive.materials.primer'),
        value:
            '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.liters')}',
        icon: Icons.water_drop,
      ),
      if (_result.groutWeight != null)
        ResultRowItem(
          label: _loc.translate('tile_adhesive.materials.grout'),
          value:
              '${_result.groutWeight!.toStringAsFixed(2)} ${_loc.translate('tile_adhesive.materials.kg')}',
          icon: Icons.gradient,
        ),
      if (_result.waterproofingWeight != null)
        ResultRowItem(
          label: _loc.translate('tile_adhesive.materials.waterproofing'),
          value:
              '${_result.waterproofingWeight!.toStringAsFixed(1)} ${_loc.translate('tile_adhesive.materials.kg')}',
          icon: Icons.water,
        ),
      ResultRowItem(
        label: _loc.translate('tile_adhesive.materials.crosses'),
        value:
            '${_result.crossesNeeded} ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.add,
      ),
      if (_result.useSVP)
        ResultRowItem(
          label: _loc.translate('tile_adhesive.materials.svp'),
          value:
              '${_result.svpCount} ${_loc.translate('tile_adhesive.materials.pieces')}',
          icon: Icons.construction,
        ),
    ];

    return ResultCardLight(
      title: _loc.translate('tile_adhesive.materials.title'),
      titleIcon: Icons.construction,
      results: results,
      accentColor: accentColor,
    );
  }

  Widget _buildToolsCard() {
    const accentColor = CalculatorColors.interior;

    final results = <ResultRowItem>[
      ResultRowItem(
        label: _loc.translate('tile_adhesive.tools.notched_trowel'),
        value: '${_result.notchSize} мм',
        icon: Icons.handyman,
      ),
      ResultRowItem(
        label: _loc.translate('tile_adhesive.tools.mixing_container'),
        value: '1 ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.shopping_basket,
      ),
      ResultRowItem(
        label: _loc.translate('tile_adhesive.tools.mixer'),
        value: '1 ${_loc.translate('tile_adhesive.materials.pieces')}',
        icon: Icons.blender,
      ),
    ];

    return ResultCardLight(
      title: _loc.translate('tile_adhesive.tools.title'),
      titleIcon: Icons.build_circle,
      results: results,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    const hints = [
      CalculatorHint(
        type: HintType.important,
        messageKey: 'hint.tile_adhesive.surface_preparation',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tile_adhesive.notch_size',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tile_adhesive.mixing',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.tile_adhesive.application',
      ),
      CalculatorHint(
        type: HintType.warning,
        messageKey: 'hint.tile_adhesive.working_time',
      ),
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
