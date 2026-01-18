import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_laminate_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Способ укладки ламината
enum LaminatePattern {
  straight('laminate_calc.pattern.straight', 'laminate_calc.pattern.straight_desc', Icons.view_stream),
  diagonal('laminate_calc.pattern.diagonal', 'laminate_calc.pattern.diagonal_desc', Icons.rotate_right);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LaminatePattern(this.nameKey, this.descKey, this.icon);
}

/// Класс износостойкости ламината (AC rating)
enum LaminateClass {
  ac3('laminate_calc.class.ac3', 'laminate_calc.class.ac3_desc'),
  ac4('laminate_calc.class.ac4', 'laminate_calc.class.ac4_desc'),
  ac5('laminate_calc.class.ac5', 'laminate_calc.class.ac5_desc'),
  ac6('laminate_calc.class.ac6', 'laminate_calc.class.ac6_desc');

  final String nameKey;
  final String descKey;
  const LaminateClass(this.nameKey, this.descKey);
}

/// Вид (тип) ламината
enum LaminateType {
  hdf('laminate_calc.type.hdf', 'laminate_calc.type.hdf_desc'),
  spc('laminate_calc.type.spc', 'laminate_calc.type.spc_desc'),
  hpl('laminate_calc.type.hpl', 'laminate_calc.type.hpl_desc');

  final String nameKey;
  final String descKey;
  const LaminateType(this.nameKey, this.descKey);
}

enum LaminateInputMode { manual, room }

/// Режим ввода площади упаковки
enum PackAreaInputMode { preset, dimensions, custom }

/// Пресеты упаковок популярных брендов
enum LaminatePackagePreset {
  quickStep('laminate_calc.preset.quick_step', 1220, 184, 9),
  kronospan('laminate_calc.preset.kronospan', 1380, 193, 8),
  tarkett('laminate_calc.preset.tarkett', 1292, 194, 7),
  egger('laminate_calc.preset.egger', 1292, 193, 9),
  vinilam('laminate_calc.preset.vinilam', 1220, 180, 10),
  berry('laminate_calc.preset.berry_alloc', 1210, 190, 8);

  final String nameKey;
  final int lengthMm;
  final int widthMm;
  final int boardsPerPack;

  const LaminatePackagePreset(this.nameKey, this.lengthMm, this.widthMm, this.boardsPerPack);

  /// Площадь упаковки в м²
  double get packArea => (lengthMm * widthMm * boardsPerPack) / 1000000;
}

/// Результат расчёта ламината
class _LaminateResult {
  final double area;
  final double areaWithWaste;
  final int packsNeeded;
  final double packArea;
  final double underlayArea;
  final int underlayRolls;
  final double plinthLength;
  final int plinthPieces;

  const _LaminateResult({
    required this.area,
    required this.areaWithWaste,
    required this.packsNeeded,
    required this.packArea,
    required this.underlayArea,
    required this.underlayRolls,
    required this.plinthLength,
    required this.plinthPieces,
  });

  factory _LaminateResult.fromCalculatorResult(Map<String, double> values) {
    return _LaminateResult(
      area: values['area'] ?? 0,
      areaWithWaste: values['areaWithWaste'] ?? 0,
      packsNeeded: (values['packsNeeded'] ?? 0).toInt(),
      packArea: values['packArea'] ?? 2.4,
      underlayArea: values['underlayArea'] ?? 0,
      underlayRolls: (values['underlayRolls'] ?? 0).toInt(),
      plinthLength: values['plinthLength'] ?? 0,
      plinthPieces: (values['plinthPieces'] ?? 0).toInt(),
    );
  }
}

class LaminateCalculatorScreen extends ConsumerStatefulWidget {
  const LaminateCalculatorScreen({super.key});

  @override
  ConsumerState<LaminateCalculatorScreen> createState() => _LaminateCalculatorScreenState();
}

class _LaminateCalculatorScreenState extends ConsumerState<LaminateCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('laminate_calc.title');

  // Domain layer calculator
  final _calculator = CalculateLaminateV2();

  // Состояние
  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _packArea = 2.4; // м² в упаковке

  LaminatePattern _pattern = LaminatePattern.straight;
  LaminateClass _laminateClass = LaminateClass.ac4;
  LaminateType _laminateType = LaminateType.hdf;
  LaminateInputMode _inputMode = LaminateInputMode.manual;

  // Режим ввода площади упаковки
  PackAreaInputMode _packAreaMode = PackAreaInputMode.preset;
  LaminatePackagePreset _selectedPreset = LaminatePackagePreset.quickStep;

  // Кастомные размеры досок
  double _boardLength = 1220.0; // мм
  double _boardWidth = 184.0; // мм
  int _boardsPerPack = 9;

  bool _needUnderlay = true;
  bool _needPlinth = true;

  late _LaminateResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _updatePackArea();
    _result = _calculate();
  }

  /// Обновляет площадь упаковки в зависимости от режима
  void _updatePackArea() {
    switch (_packAreaMode) {
      case PackAreaInputMode.preset:
        _packArea = _selectedPreset.packArea;
        // Синхронизируем размеры досок для отображения в режиме "Размеры"
        _boardLength = _selectedPreset.lengthMm.toDouble();
        _boardWidth = _selectedPreset.widthMm.toDouble();
        _boardsPerPack = _selectedPreset.boardsPerPack;
        break;
      case PackAreaInputMode.dimensions:
        _packArea = (_boardLength * _boardWidth * _boardsPerPack) / 1000000;
        break;
      case PackAreaInputMode.custom:
        // Площадь задана вручную, ничего не делаем
        break;
    }
  }

  /// Использует domain layer для расчёта
  _LaminateResult _calculate() {
    final inputs = <String, double>{
      'pattern': _pattern.index.toDouble(),
      'packArea': _packArea,
      'needUnderlay': _needUnderlay ? 1.0 : 0.0,
      'needPlinth': _needPlinth ? 1.0 : 0.0,
      'laminateClass': _laminateClass.index.toDouble(),
      'laminateType': _laminateType.index.toDouble(),
    };

    // Передаём либо площадь, либо размеры комнаты
    if (_inputMode == LaminateInputMode.manual) {
      inputs['area'] = _area;
    } else {
      inputs['roomWidth'] = _roomWidth;
      inputs['roomLength'] = _roomLength;
    }

    final result = _calculator(inputs, []);
    return _LaminateResult.fromCalculatorResult(result.values);
  }

  /// Процент отходов для экспорта
  double _getWastePercent() {
    return _pattern == LaminatePattern.straight ? 0.05 : 0.15;
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('laminate_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('laminate_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('laminate_calc.export.pattern')
        .replaceFirst('{value}', _loc.translate(_pattern.nameKey)));
    buffer.writeln(_loc.translate('laminate_calc.export.waste')
        .replaceFirst('{value}', (_getWastePercent() * 100).toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln(_loc.translate('laminate_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('laminate_calc.export.packs')
        .replaceFirst('{value}', _result.packsNeeded.toString())
        .replaceFirst('{area}', _result.packArea.toStringAsFixed(1)));
    if (_needUnderlay) {
      buffer.writeln(_loc.translate('laminate_calc.export.underlay')
          .replaceFirst('{value}', _result.underlayRolls.toString()));
    }
    if (_needPlinth) {
      buffer.writeln(_loc.translate('laminate_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('laminate_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('laminate_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('laminate_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('laminate_calc.result.packs').toUpperCase(),
            value: '${_result.packsNeeded}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('laminate_calc.result.total_area').toUpperCase(),
            value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
        ],
      ),
      children: [
        _buildPatternSelector(),
        const SizedBox(height: 16),
        _buildClassSelector(),
        const SizedBox(height: 16),
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildPackageCard(),
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

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_pattern) {
      case LaminatePattern.straight:
        tips.addAll([
          _loc.translate('laminate_calc.tip.straight_1'),
          _loc.translate('laminate_calc.tip.straight_2'),
        ]);
        break;
      case LaminatePattern.diagonal:
        tips.addAll([
          _loc.translate('laminate_calc.tip.diagonal_1'),
          _loc.translate('laminate_calc.tip.diagonal_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('laminate_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildPatternSelector() {
    return TypeSelectorGroup(
      options: LaminatePattern.values.map((p) => TypeSelectorOption(
        icon: p.icon,
        title: _loc.translate(p.nameKey),
        subtitle: _loc.translate(p.descKey),
      )).toList(),
      selectedIndex: _pattern.index,
      onSelect: (index) {
        setState(() {
          _pattern = LaminatePattern.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildClassSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('laminate_calc.section.class'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: LaminateClass.values.map((c) => _loc.translate(c.nameKey)).toList(),
            selectedIndex: _laminateClass.index,
            onSelect: (index) {
              setState(() {
                _laminateClass = LaminateClass.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_laminateClass.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('laminate_calc.section.type'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: LaminateType.values.map((t) => _loc.translate(t.nameKey)).toList(),
            selectedIndex: _laminateType.index,
            onSelect: (index) {
              setState(() {
                _laminateType = LaminateType.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_laminateType.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('laminate_calc.mode.manual'),
              _loc.translate('laminate_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = LaminateInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == LaminateInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('laminate_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) {
        setState(() {
          _area = v;
          _update();
        });
      },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('laminate_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('laminate_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('laminate_calc.label.floor_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('laminate_calc.section.package'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('laminate_calc.pack_mode.preset'),
              _loc.translate('laminate_calc.pack_mode.dimensions'),
              _loc.translate('laminate_calc.pack_mode.custom'),
            ],
            selectedIndex: _packAreaMode.index,
            onSelect: (index) {
              setState(() {
                _packAreaMode = PackAreaInputMode.values[index];
                _updatePackArea();
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 16),
          if (_packAreaMode == PackAreaInputMode.preset) _buildPresetInput(),
          if (_packAreaMode == PackAreaInputMode.dimensions) _buildDimensionsInput(),
          if (_packAreaMode == PackAreaInputMode.custom) _buildCustomInput(),
        ],
      ),
    );
  }

  Widget _buildPresetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate('laminate_calc.pack_mode.preset_hint'),
          style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...LaminatePackagePreset.values.map((preset) {
          final isSelected = _selectedPreset == preset;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPreset = preset;
                  // Обновляем размеры досок при выборе пресета для синхронизации
                  _boardLength = preset.lengthMm.toDouble();
                  _boardWidth = preset.widthMm.toDouble();
                  _boardsPerPack = preset.boardsPerPack;
                  _updatePackArea();
                  _update();
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? _accentColor.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _accentColor : CalculatorColors.textSecondary.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loc.translate(preset.nameKey),
                            style: CalculatorDesignSystem.bodyMedium.copyWith(
                              color: CalculatorColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${preset.lengthMm}×${preset.widthMm} мм, ${preset.boardsPerPack} ${_loc.translate('common.pcs')}',
                            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${preset.packArea.toStringAsFixed(2)} ${_loc.translate('common.sqm')}',
                      style: CalculatorDesignSystem.bodyLarge.copyWith(
                        color: isSelected ? _accentColor : CalculatorColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDimensionsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate('laminate_calc.pack_mode.dimensions_hint'),
          style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('laminate_calc.label.board_length'),
                value: _boardLength,
                onChanged: (v) {
                  setState(() {
                    _boardLength = v;
                    _updatePackArea();
                    _update();
                  });
                },
                suffix: _loc.translate('common.mm'),
                accentColor: _accentColor,
                minValue: 300,
                maxValue: 2000,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('laminate_calc.label.board_width'),
                value: _boardWidth,
                onChanged: (v) {
                  setState(() {
                    _boardWidth = v;
                    _updatePackArea();
                    _update();
                  });
                },
                suffix: _loc.translate('common.mm'),
                accentColor: _accentColor,
                minValue: 100,
                maxValue: 300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: _loc.translate('laminate_calc.label.boards_per_pack'),
          value: _boardsPerPack.toDouble(),
          onChanged: (v) {
            setState(() {
              _boardsPerPack = v.toInt();
              _updatePackArea();
              _update();
            });
          },
          suffix: _loc.translate('common.pcs'),
          accentColor: _accentColor,
          minValue: 1,
          maxValue: 20,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('laminate_calc.label.pack_area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
              ),
              Text(
                '${_packArea.toStringAsFixed(2)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate('laminate_calc.pack_mode.custom_hint'),
          style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
        ),
        const SizedBox(height: 12),
        CalculatorSliderField(
          label: _loc.translate('laminate_calc.label.pack_area'),
          value: _packArea,
          min: 1.0,
          max: 4.0,
          divisions: 30,
          suffix: _loc.translate('common.sqm'),
          accentColor: _accentColor,
          decimalPlaces: 2,
          onChanged: (v) {
            setState(() {
              _packArea = v;
              _update();
            });
          },
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('laminate_calc.option.underlay'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('laminate_calc.option.underlay_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needUnderlay,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needUnderlay = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('laminate_calc.option.plinth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('laminate_calc.option.plinth_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPlinth,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPlinth = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('laminate_calc.materials.laminate'),
        value: '${_result.packsNeeded} ${_loc.translate('laminate_calc.unit.packs')}',
        subtitle: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ),
    ];

    if (_needUnderlay && _result.underlayRolls > 0) {
      items.add(MaterialItem(
        name: _loc.translate('laminate_calc.materials.underlay'),
        value: '${_result.underlayRolls} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.underlayArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.view_agenda,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('laminate_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('laminate_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
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
