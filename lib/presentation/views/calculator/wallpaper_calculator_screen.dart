import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/usecases/calculate_wallpaper.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum InputMode { byArea, byRoom }
enum WallpaperRollSize { s053x10, s106x10, s106x25, custom }

/// Тип обоев — влияет на расход клея (сухая смесь, кг/м²)
enum WallpaperType {
  paper(1),
  vinyl(2),
  nonWoven(3);

  final int canonicalId;
  const WallpaperType(this.canonicalId);
}

class _WallpaperResult {
  final double area;
  final double wallsArea;
  final double deductedArea;
  final int rollsNeeded;
  final int stripsNeeded;
  final String rollSizeName;
  final double glueNeededKg;
  final double primerLiters;
  final double rollWidth;
  final double rollLength;

  const _WallpaperResult({
    required this.area,
    required this.wallsArea,
    required this.deductedArea,
    required this.rollsNeeded,
    required this.stripsNeeded,
    required this.rollSizeName,
    required this.glueNeededKg,
    required this.primerLiters,
    required this.rollWidth,
    required this.rollLength,
  });
}

class WallpaperCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const WallpaperCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<WallpaperCalculatorScreen> createState() => _WallpaperCalculatorScreenState();
}

class _WallpaperCalculatorScreenState extends State<WallpaperCalculatorScreen>
    with ExportableMixin {
  final CalculateWallpaper _calculator = CalculateWallpaper();

  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('wallpaper.export.subject');

  bool _isDark = false;
  InputMode _inputMode = InputMode.byRoom;
  double _area = 30.0;
  double _length = 4.0;
  double _width = 3.0;
  double _height = 2.7;
  double _windowsDoors = 3.0;
  int _rapport = 0;
  WallpaperRollSize _rollSize = WallpaperRollSize.s053x10;
  WallpaperType _wallpaperType = WallpaperType.vinyl;
  double _customWidth = 1.06;
  double _customLength = 10.0;
  late _WallpaperResult _result;
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

    if (initial['inputMode'] != null) {
      _inputMode = initial['inputMode']!.round() == 1
          ? InputMode.byArea
          : InputMode.byRoom;
    }
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) _length = initial['length']!.clamp(1.0, 20.0);
    if (initial['width'] != null) _width = initial['width']!.clamp(1.0, 20.0);
    final wallHeight = initial['wallHeight'] ?? initial['height'];
    if (wallHeight != null) _height = wallHeight.clamp(2.0, 5.0);
    if (initial['openingsArea'] != null) {
      _windowsDoors = initial['openingsArea']!.clamp(0.0, 50.0);
    } else {
      final windowsArea = initial['windowsArea'] ?? 0.0;
      final doorsArea = initial['doorsArea'] ?? 0.0;
      _windowsDoors = (windowsArea + doorsArea).clamp(0.0, 50.0);
    }
    if (initial['rapport'] != null) {
      _rapport = initial['rapport']!.round().clamp(0, 100);
    }
    if (initial['wallpaperType'] != null) {
      _wallpaperType = _resolveWallpaperType(initial['wallpaperType']!);
    }
    if (initial['rollSize'] != null) {
      _rollSize = _resolveRollSize(initial['rollSize']!.round());
    }
    if (initial['rollWidth'] != null) {
      _customWidth = initial['rollWidth']!.clamp(0.5, 2.0);
    }
    if (initial['rollLength'] != null) {
      _customLength = initial['rollLength']!.clamp(5.0, 50.0);
    }
  }

  WallpaperType _resolveWallpaperType(double rawValue) {
    final rounded = rawValue.round();
    if (rounded >= 1 && rounded <= WallpaperType.values.length) {
      return WallpaperType.values[rounded - 1];
    }
    return WallpaperType.values[rounded.clamp(0, WallpaperType.values.length - 1)];
  }

  WallpaperRollSize _resolveRollSize(int rawValue) {
    switch (rawValue) {
      case 0:
        return WallpaperRollSize.custom;
      case 2:
        return WallpaperRollSize.s106x10;
      case 3:
        return WallpaperRollSize.s106x25;
      default:
        return WallpaperRollSize.s053x10;
    }
  }

  Map<String, double> _selectedRollDimensions() {
    switch (_rollSize) {
      case WallpaperRollSize.s053x10:
        return {'rollWidth': 0.53, 'rollLength': 10.05, 'rollSize': 1.0};
      case WallpaperRollSize.s106x10:
        return {'rollWidth': 1.06, 'rollLength': 10.05, 'rollSize': 2.0};
      case WallpaperRollSize.s106x25:
        return {'rollWidth': 1.06, 'rollLength': 25.0, 'rollSize': 3.0};
      case WallpaperRollSize.custom:
        return {
          'rollWidth': _customWidth,
          'rollLength': _customLength,
          'rollSize': 0.0,
        };
    }
  }

  String _resolveRollSizeName(double rollWidth, double rollLength) {
    if ((rollWidth - 0.53).abs() < 0.001 && (rollLength - 10.05).abs() < 0.1) {
      return '0.53×10';
    }
    if ((rollWidth - 1.06).abs() < 0.001 && (rollLength - 10.05).abs() < 0.1) {
      return '1.06×10';
    }
    if ((rollWidth - 1.06).abs() < 0.001 && (rollLength - 25.0).abs() < 0.1) {
      return '1.06×25';
    }
    final lengthLabel = (rollLength - rollLength.roundToDouble()).abs() < 0.05
        ? rollLength.toStringAsFixed(0)
        : rollLength.toStringAsFixed(1);
    return '${rollWidth.toStringAsFixed(2)}×$lengthLabel';
  }

  Map<String, double> _buildCalculationInputs() {
    final roll = _selectedRollDimensions();
    return {
      'inputMode': _inputMode == InputMode.byRoom ? 0 : 1,
      'area': _area,
      'length': _length,
      'width': _width,
      'wallHeight': _height,
      'openingsArea': _windowsDoors,
      'rapport': _rapport.toDouble(),
      'wallpaperType': _wallpaperType.canonicalId.toDouble(),
      'rollSize': roll['rollSize']!,
      'rollWidth': roll['rollWidth']!,
      'rollLength': roll['rollLength']!,
      'reserveRolls': 0,
    };
  }

  static int _safeRound(dynamic value) {
    if (value == null) return 0;
    if (value is num && value.isFinite) return value.round();
    return 0;
  }

  _WallpaperResult _calculate() {
    final contract = _calculator.calculateCanonical(_buildCalculationInputs());
    final totals = contract.totals;
    final rollWidth = totals['rollWidth'] ?? _selectedRollDimensions()['rollWidth']!;
    final rollLength = totals['rollLength'] ?? _selectedRollDimensions()['rollLength']!;

    return _WallpaperResult(
      area: totals['netArea'] ?? 0,
      wallsArea: totals['wallArea'] ?? 0,
      deductedArea: totals['openingsArea'] ?? _windowsDoors,
      rollsNeeded: _safeRound(totals['rollsNeeded']),
      stripsNeeded: _safeRound(totals['stripsNeeded']),
      rollSizeName: _resolveRollSizeName(rollWidth, rollLength),
      glueNeededKg: totals['pasteNeededKg'] ?? 0,
      primerLiters: totals['primerNeededL'] ?? 0,
      rollWidth: rollWidth,
      rollLength: rollLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('wallpaper.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln(_loc.translate('wallpaper.export.walls_area')
        .replaceFirst('{value}', _result.wallsArea.toStringAsFixed(1)));
    if (_result.deductedArea > 0) {
      buffer.writeln(_loc.translate('wallpaper.export.deduction')
          .replaceFirst('{value}', _result.deductedArea.toStringAsFixed(1)));
      buffer.writeln(_loc.translate('wallpaper.export.gluing_area')
          .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    }
    if (_rapport > 0) {
      buffer.writeln(_loc.translate('wallpaper.export.rapport')
          .replaceFirst('{value}', _rapport.toString()));
    }
    buffer.writeln();

    buffer.writeln(_loc.translate('wallpaper.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('wallpaper.export.rolls_line')
        .replaceFirst('{size}', _result.rollSizeName)
        .replaceFirst('{value}', _result.rollsNeeded.toString()));
    buffer.writeln(_loc.translate('wallpaper.export.strips_line')
        .replaceFirst('{value}', _result.stripsNeeded.toString()));
    buffer.writeln(_loc.translate('wallpaper.export.glue_line')
        .replaceFirst('{value}', _result.glueNeededKg.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('wallpaper.export.primer_line')
        .replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1)));
    buffer.writeln();

    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('wallpaper.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('wallpaper.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('wallpaper.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('wallpaper.summary.rolls').toUpperCase(),
            value: '${_result.rollsNeeded}',
            icon: Icons.ballot,
          ),
          ResultItem(
            label: _loc.translate('wallpaper.summary.strips').toUpperCase(),
            value: '${_result.stripsNeeded}',
            icon: Icons.view_week,
          ),
        ],
      ),
      children: [
        _buildWallpaperTypeSelector(),
        const SizedBox(height: 16),
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea ? _buildAreaCard() : _buildRoomDimensionsCard(),
        const SizedBox(height: 16),
        _buildRollSizeSelector(),
        if (_rollSize == WallpaperRollSize.custom) ...[
          const SizedBox(height: 16),
          _buildCustomSizeCard(),
        ],
        const SizedBox(height: 16),
        _buildRapportCard(),
        const SizedBox(height: 16),
        _buildDeductionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 16),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWallpaperTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return TypeSelectorGroup(
      options: [
        TypeSelectorOption(
          icon: Icons.description,
          title: _loc.translate('wallpaper.type.paper'),
          subtitle: _loc.translate('wallpaper.type.paper_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.layers,
          title: _loc.translate('wallpaper.type.vinyl'),
          subtitle: _loc.translate('wallpaper.type.vinyl_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.texture,
          title: _loc.translate('wallpaper.type.non_woven'),
          subtitle: _loc.translate('wallpaper.type.non_woven_desc'),
        ),
      ],
      selectedIndex: _wallpaperType.index,
      onSelect: (index) {
        setState(() {
          _wallpaperType = WallpaperType.values[index];
          _update();
        });
      },
      accentColor: accentColor,
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('wallpaper.input_mode.by_room'),
              _loc.translate('wallpaper.input_mode.by_area'),
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
        label: _loc.translate('wallpaper.label.area'),
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
        decimalPlaces: 0,
      ),
    );
  }

  Widget _buildRoomDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.room.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('wallpaper.room.length'),
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
            label: _loc.translate('wallpaper.room.width'),
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
            label: _loc.translate('wallpaper.room.height'),
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
                  _loc.translate('wallpaper.room.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
                Text(
                  '${_result.wallsArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
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

  Widget _buildRollSizeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.roll_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: [
              _loc.translate('wallpaper.roll_size.s053x10'),
              _loc.translate('wallpaper.roll_size.s106x10'),
              _loc.translate('wallpaper.roll_size.s106x25'),
              _loc.translate('wallpaper.roll_size.custom'),
            ],
            selectedIndex: _rollSize.index,
            onSelect: (index) {
              setState(() {
                _rollSize = WallpaperRollSize.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSizeCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.custom_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('wallpaper.custom_size.width'),
            value: _customWidth,
            min: 0.5,
            max: 2.0,
            onChanged: (v) {
              setState(() {
                _customWidth = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('wallpaper.custom_size.length'),
            value: _customLength,
            min: 5.0,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _customLength = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRapportCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.rapport.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('wallpaper.rapport.subtitle'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          CalculatorSliderField(
            label: _rapport == 0
                ? _loc.translate('wallpaper.rapport.none')
                : _loc.translate('wallpaper.rapport.title'),
            value: _rapport.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            suffix: _loc.translate('common.cm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _rapport = v.toInt();
                _update();
              });
            },
            decimalPlaces: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.deductions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('wallpaper.deductions.subtitle'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 8),
          CalculatorSliderField(
            label: _loc.translate('wallpaper.deductions.title'),
            value: _windowsDoors,
            min: 0,
            max: 50,
            divisions: 100,
            suffix: _loc.translate('common.sqm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _windowsDoors = v;
                _update();
              });
            },
            decimalPlaces: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('wallpaper.materials.rolls'),
        value: '${_result.rollsNeeded} ${_loc.translate('wallpaper.materials.rolls_unit')}',
        subtitle: _result.rollSizeName,
        icon: Icons.ballot,
      ),
      MaterialItem(
        name: _loc.translate('wallpaper.materials.strips'),
        value: '${_result.stripsNeeded} ${_loc.translate('wallpaper.materials.strips_unit')}',
        icon: Icons.view_week,
      ),
      MaterialItem(
        name: _loc.translate('wallpaper.materials.glue'),
        value: _result.glueNeededKg < 1
            ? '${(_result.glueNeededKg * 1000).toStringAsFixed(0)} ${_loc.translate('common.gram_short')}'
            : '${_result.glueNeededKg.toStringAsFixed(1)} ${_loc.translate('wallpaper.materials.kg')}',
        icon: Icons.colorize,
      ),
      MaterialItem(
        name: _loc.translate('wallpaper.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('wallpaper.materials.liters')}',
        icon: Icons.water_drop,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('wallpaper.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[];

    switch (_wallpaperType) {
      case WallpaperType.paper:
        tips.add(_loc.translate('hint.wallpaper.paper_glue_on_strip'));
        tips.add(_loc.translate('hint.wallpaper.paper_soak_time'));
      case WallpaperType.vinyl:
        tips.add(_loc.translate('hint.wallpaper.vinyl_glue_on_wall'));
        tips.add(_loc.translate('hint.wallpaper.vinyl_wet_rooms'));
      case WallpaperType.nonWoven:
        tips.add(_loc.translate('hint.wallpaper.nonwoven_glue_on_wall'));
        tips.add(_loc.translate('hint.wallpaper.nonwoven_ventilation'));
    }

    tips.addAll([
      _loc.translate('hint.wallpaper.check_batch_number'),
      _loc.translate('hint.wallpaper.start_from_window'),
      _loc.translate('hint.wallpaper.temperature_humidity'),
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

