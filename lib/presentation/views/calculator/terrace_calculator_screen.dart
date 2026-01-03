import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

enum TerraceFloorType { decking, tile, board }
enum TerraceRoofType { polycarbonate, profiledSheet, softRoof }

class _TerraceResult {
  final double area;
  final double deckingArea;
  final int tilesNeeded;
  final int deckingBoards;
  final double railingLength;
  final int railingPosts;
  final double roofArea;
  final int polycarbonateSheets;
  final int profiledSheets;
  final double roofingMaterial;
  final int roofPosts;
  final double foundationVolume;

  const _TerraceResult({
    required this.area,
    required this.deckingArea,
    required this.tilesNeeded,
    required this.deckingBoards,
    required this.railingLength,
    required this.railingPosts,
    required this.roofArea,
    required this.polycarbonateSheets,
    required this.profiledSheets,
    required this.roofingMaterial,
    required this.roofPosts,
    required this.foundationVolume,
  });
}

class TerraceCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const TerraceCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<TerraceCalculatorScreen> createState() =>
      _TerraceCalculatorScreenState();
}

class _TerraceCalculatorScreenState extends State<TerraceCalculatorScreen> {
  static const double _minArea = 4.0;
  static const double _maxArea = 200.0;

  double _area = 18.0;
  TerraceFloorType _floorType = TerraceFloorType.decking;
  bool _hasRailing = true;
  bool _hasRoof = false;
  TerraceRoofType _roofType = TerraceRoofType.polycarbonate;

  late _TerraceResult _result;
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

    if (initial['area'] != null) {
      _area = initial['area']!.clamp(_minArea, _maxArea);
    }
    if (initial['floorType'] != null) {
      final raw = initial['floorType']!.round().clamp(1, 3);
      _floorType = TerraceFloorType.values[raw - 1];
    }
    if (initial['railing'] != null) {
      _hasRailing = initial['railing']!.round() == 1;
    }
    if (initial['roof'] != null) {
      _hasRoof = initial['roof']!.round() == 1;
    }
    if (initial['roofType'] != null) {
      final raw = initial['roofType']!.round().clamp(1, 3);
      _roofType = TerraceRoofType.values[raw - 1];
    }
  }

  _TerraceResult _calculate() {
    final area = _area;

    double deckingArea = 0.0;
    int tilesNeeded = 0;
    int deckingBoards = 0;

    switch (_floorType) {
      case TerraceFloorType.decking:
        deckingArea = area * 1.1;
        break;
      case TerraceFloorType.tile:
        const tileArea = 0.25;
        tilesNeeded = (area / tileArea * 1.1).ceil();
        break;
      case TerraceFloorType.board:
        const boardArea = 0.1;
        deckingBoards = (area / boardArea * 1.1).ceil();
        break;
    }

    final perimeter = area > 0 ? sqrt(area) * 4 : 0.0;
    final railingLength = _hasRailing ? perimeter : 0.0;
    final railingPosts =
        _hasRailing && perimeter > 0 ? (perimeter / 2.0).ceil() : 0;

    double roofArea = 0.0;
    int polycarbonateSheets = 0;
    int profiledSheets = 0;
    double roofingMaterial = 0.0;
    int roofPosts = 0;
    double foundationVolume = 0.0;

    if (_hasRoof) {
      roofArea = area * 1.2;

      switch (_roofType) {
        case TerraceRoofType.polycarbonate:
          const sheetArea = 6.0;
          polycarbonateSheets = (roofArea / sheetArea * 1.1).ceil();
          break;
        case TerraceRoofType.profiledSheet:
          const sheetArea = 8.0;
          profiledSheets = (roofArea / sheetArea * 1.1).ceil();
          break;
        case TerraceRoofType.softRoof:
          roofingMaterial = roofArea * 1.1;
          break;
      }

      roofPosts = (area / 9.0).ceil();
      foundationVolume = roofPosts * 0.2 * 0.2 * 0.5;
    }

    return _TerraceResult(
      area: area,
      deckingArea: deckingArea,
      tilesNeeded: tilesNeeded,
      deckingBoards: deckingBoards,
      railingLength: railingLength,
      railingPosts: railingPosts,
      roofArea: roofArea,
      polycarbonateSheets: polycarbonateSheets,
      profiledSheets: profiledSheets,
      roofingMaterial: roofingMaterial,
      roofPosts: roofPosts,
      foundationVolume: foundationVolume,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _floorLabel() {
    return switch (_floorType) {
      TerraceFloorType.decking => 'Настил',
      TerraceFloorType.tile => 'Плитка',
      TerraceFloorType.board => 'Доска',
    };
  }

  String _floorValue() {
    return switch (_floorType) {
      TerraceFloorType.decking =>
        '${_result.deckingArea.toStringAsFixed(1)} м²',
      TerraceFloorType.tile => '${_result.tilesNeeded} шт',
      TerraceFloorType.board => '${_result.deckingBoards} шт',
    };
  }

  IconData _floorIcon() {
    return switch (_floorType) {
      TerraceFloorType.decking => Icons.deck,
      TerraceFloorType.tile => Icons.grid_on,
      TerraceFloorType.board => Icons.view_agenda,
    };
  }

  String _roofTypeLabel() {
    return switch (_roofType) {
      TerraceRoofType.polycarbonate => 'Поликарбонат',
      TerraceRoofType.profiledSheet => 'Профлист',
      TerraceRoofType.softRoof => 'Мягкая кровля',
    };
  }

  String _exportText() {
    final buffer = StringBuffer();
    buffer.writeln('Терраса / веранда — расчёт');
    buffer.writeln('Площадь: ${_result.area.toStringAsFixed(1)} м²');
    buffer.writeln('Покрытие: ${_floorLabel()}');
    switch (_floorType) {
      case TerraceFloorType.decking:
        buffer.writeln(
          'Террасная доска: ${_result.deckingArea.toStringAsFixed(1)} м²',
        );
        break;
      case TerraceFloorType.tile:
        buffer.writeln('Плитка: ${_result.tilesNeeded} шт');
        break;
      case TerraceFloorType.board:
        buffer.writeln('Настил: ${_result.deckingBoards} шт');
        break;
    }
    if (_hasRailing) {
      buffer.writeln(
        'Ограждение: ${_result.railingLength.toStringAsFixed(1)} м',
      );
      buffer.writeln('Столбы: ${_result.railingPosts} шт');
    }
    if (_hasRoof) {
      buffer.writeln('Кровля: ${_result.roofArea.toStringAsFixed(1)} м²');
      buffer.writeln('Тип кровли: ${_roofTypeLabel()}');
      if (_roofType == TerraceRoofType.polycarbonate) {
        buffer.writeln('Поликарбонат: ${_result.polycarbonateSheets} листов');
      } else if (_roofType == TerraceRoofType.profiledSheet) {
        buffer.writeln('Профлист: ${_result.profiledSheets} листов');
      } else {
        buffer.writeln(
          'Материал: ${_result.roofingMaterial.toStringAsFixed(1)} м²',
        );
      }
      buffer.writeln('Опорные столбы: ${_result.roofPosts} шт');
      buffer.writeln(
        'Бетон под опоры: ${_result.foundationVolume.toStringAsFixed(2)} м³',
      );
    }
    return buffer.toString();
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: _exportText(),
        subject: _loc.translate(widget.definition.titleKey),
      ),
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _exportText()));
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
    const accentColor = CalculatorColors.facade;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: _loc.translate('common.copy'),
          onPressed: _copy,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: _loc.translate('common.share'),
          onPressed: _share,
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('input.area'),
            value: '${_result.area.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _floorLabel(),
            value: _floorValue(),
            icon: _floorIcon(),
          ),
        ],
      ),
      children: [
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildFloorCard(),
        const SizedBox(height: 16),
        _buildRailingCard(),
        const SizedBox(height: 16),
        _buildRoofCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Площадь террасы',
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_area.toStringAsFixed(1)} м²',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
            ),
            child: Slider(
              value: _area,
              min: _minArea,
              max: _maxArea,
              divisions: ((_maxArea - _minArea) * 2).round(),
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('input.area'),
            value: _area,
            suffix: 'м²',
            minValue: _minArea,
            maxValue: _maxArea,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _area = value;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.floorType'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorWithIcons(
            options: const [
              ModeSelectorIconOption(label: 'Декинг', icon: Icons.deck),
              ModeSelectorIconOption(label: 'Плитка', icon: Icons.grid_on),
              ModeSelectorIconOption(label: 'Настил', icon: Icons.view_agenda),
            ],
            selectedIndex: _floorType.index,
            onSelect: (index) {
              setState(() {
                _floorType = TerraceFloorType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            'Запас 10% учтён в расчётах',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailingCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.railing'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              'Нужны перила/ограждение',
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Длина считается по периметру',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _hasRailing,
            onChanged: (value) {
              setState(() {
                _hasRailing = value;
                _update();
              });
            },
          ),
          if (_hasRailing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Периметр',
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_result.railingLength.toStringAsFixed(1)} м',
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_result.railingPosts} шт',
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoofCard() {
    const accentColor = CalculatorColors.facade;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.roof'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              'Нужна кровля',
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Учтём опоры и запас по площади',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _hasRoof,
            onChanged: (value) {
              setState(() {
                _hasRoof = value;
                _update();
              });
            },
          ),
          if (_hasRoof) ...[
            const SizedBox(height: 12),
            ModeSelectorWithIcons(
              options: const [
                ModeSelectorIconOption(
                  label: 'Поликарбонат',
                  icon: Icons.cloud_queue,
                ),
                ModeSelectorIconOption(
                  label: 'Профлист',
                  icon: Icons.table_chart,
                ),
                ModeSelectorIconOption(
                  label: 'Мягкая',
                  icon: Icons.layers,
                ),
              ],
              selectedIndex: _roofType.index,
              onSelect: (index) {
                setState(() {
                  _roofType = TerraceRoofType.values[index];
                  _update();
                });
              },
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Площадь кровли',
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_result.roofArea.toStringAsFixed(1)} м²',
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.facade;
    final items = <MaterialItem>[];

    switch (_floorType) {
      case TerraceFloorType.decking:
        items.add(MaterialItem(
          name: 'Террасная доска (декинг)',
          value: '${_result.deckingArea.toStringAsFixed(1)} м²',
          subtitle: 'с запасом 10%',
          icon: Icons.deck,
        ));
        break;
      case TerraceFloorType.tile:
        items.add(MaterialItem(
          name: 'Плитка для террасы',
          value: '${_result.tilesNeeded} шт',
          subtitle: 'с запасом 10%',
          icon: Icons.grid_on,
        ));
        break;
      case TerraceFloorType.board:
        items.add(MaterialItem(
          name: 'Доска настила',
          value: '${_result.deckingBoards} шт',
          subtitle: 'с запасом 10%',
          icon: Icons.view_agenda,
        ));
        break;
    }

    if (_hasRailing) {
      items.addAll([
        MaterialItem(
          name: 'Ограждение',
          value: '${_result.railingLength.toStringAsFixed(1)} м',
          subtitle: 'По периметру',
          icon: Icons.straighten,
        ),
        MaterialItem(
          name: 'Столбы ограждения',
          value: '${_result.railingPosts} шт',
          subtitle: 'Шаг 2 м',
          icon: Icons.flag,
        ),
      ]);
    }

    if (_hasRoof) {
      items.add(MaterialItem(
        name: 'Площадь кровли',
        value: '${_result.roofArea.toStringAsFixed(1)} м²',
        subtitle: '+20% к площади террасы',
        icon: Icons.roofing,
      ));

      if (_roofType == TerraceRoofType.polycarbonate) {
        items.add(MaterialItem(
          name: 'Поликарбонат',
          value: '${_result.polycarbonateSheets} листов',
          subtitle: '6 м² / лист',
          icon: Icons.cloud_queue,
        ));
      } else if (_roofType == TerraceRoofType.profiledSheet) {
        items.add(MaterialItem(
          name: 'Профлист',
          value: '${_result.profiledSheets} листов',
          subtitle: '8 м² / лист',
          icon: Icons.table_chart,
        ));
      } else {
        items.add(MaterialItem(
          name: 'Мягкая кровля',
          value: '${_result.roofingMaterial.toStringAsFixed(1)} м²',
          icon: Icons.layers,
        ));
      }

      items.addAll([
        MaterialItem(
          name: 'Опорные столбы кровли',
          value: '${_result.roofPosts} шт',
          subtitle: '1 столб на 9 м²',
          icon: Icons.vertical_align_bottom,
        ),
        MaterialItem(
          name: 'Бетон под опоры',
          value: '${_result.foundationVolume.toStringAsFixed(2)} м³',
          subtitle: '20×20×50 см / опору',
          icon: Icons.foundation,
        ),
      ]);
    }

    return MaterialsCardModern(
      title: _loc.translate('group.materials'),
      titleIcon: Icons.inventory_2,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    final hints = widget.definition.beforeHints;
    if (hints.isEmpty) return const SizedBox.shrink();

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
        HintsList(hints: hints),
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
