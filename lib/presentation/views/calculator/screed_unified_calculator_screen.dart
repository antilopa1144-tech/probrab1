import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_screed_unified.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип стяжки
enum ScreedType {
  cementSand('screed_unified.type.cement_sand', 'screed_unified.type.cement_sand_desc', Icons.foundation),
  semidry('screed_unified.type.semidry', 'screed_unified.type.semidry_desc', Icons.water_drop_outlined),
  concrete('screed_unified.type.concrete', 'screed_unified.type.concrete_desc', Icons.construction);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const ScreedType(this.nameKey, this.descKey, this.icon);
}

/// Способ приготовления
enum MaterialMethod {
  readyMix('screed_unified.method.ready_mix', 'screed_unified.method.ready_mix_desc', Icons.shopping_bag),
  selfMix('screed_unified.method.self_mix', 'screed_unified.method.self_mix_desc', Icons.handyman);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const MaterialMethod(this.nameKey, this.descKey, this.icon);
}

/// Марка готовой смеси
enum MixGrade {
  m300('screed_unified.grade.m300', 'screed_unified.grade.m300_desc'),
  m150('screed_unified.grade.m150', 'screed_unified.grade.m150_desc');

  final String nameKey;
  final String descKey;
  const MixGrade(this.nameKey, this.descKey);
}

/// Режим ввода площади
enum AreaInputMode { manual, room }

/// Результат расчёта для UI
class _ScreedResult {
  final double area;
  final double perimeter;
  final double volume;
  final double thickness;

  // Готовая смесь
  final double mixWeightKg;
  final double mixWeightTonnes;
  final int mixBags;

  // Самозамес
  final double cementKg;
  final int cementBags;
  final double sandKg;
  final double sandCbm;
  final double gravelKg;
  final double gravelCbm;

  // Дополнительные материалы
  final double meshArea;
  final double filmArea;
  final double tapeMeters;
  final int beaconsNeeded;

  // Флаги
  final bool thicknessWarning;

  const _ScreedResult({
    required this.area,
    required this.perimeter,
    required this.volume,
    required this.thickness,
    required this.mixWeightKg,
    required this.mixWeightTonnes,
    required this.mixBags,
    required this.cementKg,
    required this.cementBags,
    required this.sandKg,
    required this.sandCbm,
    required this.gravelKg,
    required this.gravelCbm,
    required this.meshArea,
    required this.filmArea,
    required this.tapeMeters,
    required this.beaconsNeeded,
    required this.thicknessWarning,
  });

  factory _ScreedResult.fromCalculatorResult(Map<String, double> values) {
    return _ScreedResult(
      area: values['area'] ?? 0,
      perimeter: values['perimeter'] ?? 0,
      volume: values['volume'] ?? 0,
      thickness: values['thickness'] ?? 0,
      mixWeightKg: values['mixWeightKg'] ?? 0,
      mixWeightTonnes: values['mixWeightTonnes'] ?? 0,
      mixBags: (values['mixBags'] ?? 0).toInt(),
      cementKg: values['cementKg'] ?? 0,
      cementBags: (values['cementBags'] ?? 0).toInt(),
      sandKg: values['sandKg'] ?? 0,
      sandCbm: values['sandCbm'] ?? 0,
      gravelKg: values['gravelKg'] ?? 0,
      gravelCbm: values['gravelCbm'] ?? 0,
      meshArea: values['meshArea'] ?? 0,
      filmArea: values['filmArea'] ?? 0,
      tapeMeters: values['tapeMeters'] ?? 0,
      beaconsNeeded: (values['beaconsNeeded'] ?? 0).toInt(),
      thicknessWarning: (values['thicknessWarning'] ?? 0) > 0,
    );
  }
}

/// Объединённый калькулятор стяжки пола.
///
/// Объединяет функциональность калькуляторов "Стяжка" и "ЦПС/Стяжка":
/// - Выбор типа стяжки: ЦПС, полусухая, бетонная
/// - Выбор способа: готовая смесь или самозамес
/// - Расчёт всех необходимых материалов
/// - Современный UI с подсказками
class ScreedUnifiedCalculatorScreen extends ConsumerStatefulWidget {
  const ScreedUnifiedCalculatorScreen({super.key});

  @override
  ConsumerState<ScreedUnifiedCalculatorScreen> createState() => _ScreedUnifiedCalculatorScreenState();
}

class _ScreedUnifiedCalculatorScreenState extends ConsumerState<ScreedUnifiedCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('screed_unified.title');

  // Domain layer calculator
  final _calculator = CalculateScreedUnified();

  // Параметры
  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _thickness = 50.0;
  double _bagWeight = 40.0;

  // Выборы
  ScreedType _screedType = ScreedType.cementSand;
  MaterialMethod _materialMethod = MaterialMethod.readyMix;
  MixGrade _mixGrade = MixGrade.m300;
  AreaInputMode _inputMode = AreaInputMode.manual;

  // Опции
  bool _needMesh = true;
  bool _needFilm = true;
  bool _needTape = true;
  bool _needBeacons = true;

  late _ScreedResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.flooring;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _ScreedResult _calculate() {
    final inputs = <String, double>{
      'inputMode': _inputMode == AreaInputMode.manual ? 0.0 : 1.0,
      'thickness': _thickness,
      'screedType': _screedType.index.toDouble(),
      'materialType': _materialMethod.index.toDouble(),
      'mixGrade': _mixGrade.index.toDouble(),
      'bagWeight': _bagWeight,
      'needMesh': _needMesh ? 1.0 : 0.0,
      'needFilm': _needFilm ? 1.0 : 0.0,
      'needTape': _needTape ? 1.0 : 0.0,
      'needBeacons': _needBeacons ? 1.0 : 0.0,
    };

    if (_inputMode == AreaInputMode.manual) {
      inputs['area'] = _area;
    } else {
      inputs['roomWidth'] = _roomWidth;
      inputs['roomLength'] = _roomLength;
    }

    final result = _calculator(inputs, []);
    return _ScreedResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('screed_unified.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    // Параметры
    buffer.writeln('${_loc.translate('screed_unified.export.type')}: ${_loc.translate(_screedType.nameKey)}');
    buffer.writeln('${_loc.translate('screed_unified.export.method')}: ${_loc.translate(_materialMethod.nameKey)}');
    buffer.writeln('${_loc.translate('screed_unified.export.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('screed_unified.export.thickness')}: ${_result.thickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}');
    buffer.writeln('${_loc.translate('screed_unified.export.volume')}: ${_result.volume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}');
    buffer.writeln();

    // Материалы
    buffer.writeln(_loc.translate('screed_unified.export.materials_title'));
    buffer.writeln('─' * 40);

    if (_materialMethod == MaterialMethod.readyMix) {
      buffer.writeln('${_loc.translate(_mixGrade.nameKey)}: ${_result.mixBags} ${_loc.translate('common.pcs')} (${_result.mixWeightKg.toStringAsFixed(0)} ${_loc.translate('common.kg')})');
    } else {
      buffer.writeln('${_loc.translate('screed_unified.materials.cement')}: ${_result.cementBags} ${_loc.translate('common.pcs')} (${_result.cementKg.toStringAsFixed(0)} ${_loc.translate('common.kg')})');
      buffer.writeln('${_loc.translate('screed_unified.materials.sand')}: ${_result.sandCbm.toStringAsFixed(2)} ${_loc.translate('common.cbm')}');
      if (_screedType == ScreedType.concrete) {
        buffer.writeln('${_loc.translate('screed_unified.materials.gravel')}: ${_result.gravelCbm.toStringAsFixed(2)} ${_loc.translate('common.cbm')}');
      }
    }

    if (_needMesh) {
      buffer.writeln('${_loc.translate('screed_unified.materials.mesh')}: ${_result.meshArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    }
    if (_needFilm) {
      buffer.writeln('${_loc.translate('screed_unified.materials.film')}: ${_result.filmArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    }
    if (_needTape) {
      buffer.writeln('${_loc.translate('screed_unified.materials.tape')}: ${_result.tapeMeters.toStringAsFixed(1)} ${_loc.translate('common.meters')}');
    }
    if (_needBeacons) {
      buffer.writeln('${_loc.translate('screed_unified.materials.beacons')}: ${_result.beaconsNeeded} ${_loc.translate('common.pcs')}');
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('screed_unified.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('screed_unified.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: _buildResultHeader(),
      children: [
        _buildScreedTypeSelector(),
        const SizedBox(height: 16),
        _buildMaterialMethodSelector(),
        const SizedBox(height: 16),
        if (_materialMethod == MaterialMethod.readyMix) ...[
          _buildMixGradeSelector(),
          const SizedBox(height: 16),
        ],
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
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

  CalculatorResultHeader _buildResultHeader() {
    final results = <ResultItem>[
      ResultItem(
        label: _loc.translate('screed_unified.result.area').toUpperCase(),
        value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.straighten,
      ),
      ResultItem(
        label: _loc.translate('screed_unified.result.volume').toUpperCase(),
        value: '${_result.volume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
        icon: Icons.view_in_ar,
      ),
    ];

    if (_materialMethod == MaterialMethod.readyMix) {
      results.add(ResultItem(
        label: _loc.translate('screed_unified.result.mix').toUpperCase(),
        value: '${_result.mixBags} ${_loc.translate('common.pcs')}',
        icon: Icons.shopping_bag,
      ));
    } else {
      results.add(ResultItem(
        label: _loc.translate('screed_unified.result.cement').toUpperCase(),
        value: '${_result.cementBags} ${_loc.translate('common.pcs')}',
        icon: Icons.inventory_2,
      ));
    }

    return CalculatorResultHeader(
      accentColor: _accentColor,
      results: results,
    );
  }

  Widget _buildScreedTypeSelector() {
    return TypeSelectorGroup(
      options: ScreedType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _screedType.index,
      onSelect: (index) {
        setState(() {
          _screedType = ScreedType.values[index];
          // Бетонная стяжка только самозамес
          if (_screedType == ScreedType.concrete) {
            _materialMethod = MaterialMethod.selfMix;
          }
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildMaterialMethodSelector() {
    // Для бетонной стяжки скрываем селектор — только самозамес
    if (_screedType == ScreedType.concrete) {
      return _card(
        child: Row(
          children: [
            Icon(MaterialMethod.selfMix.icon, color: _accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loc.translate(MaterialMethod.selfMix.nameKey),
                    style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
                  ),
                  Text(
                    _loc.translate('screed_unified.concrete_only_self_mix'),
                    style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('screed_unified.method_title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: MaterialMethod.values.map((m) => _loc.translate(m.nameKey)).toList(),
            selectedIndex: _materialMethod.index,
            onSelect: (index) {
              setState(() {
                _materialMethod = MaterialMethod.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_materialMethod.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMixGradeSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('screed_unified.grade_title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: MixGrade.values.map((g) => _loc.translate(g.nameKey)).toList(),
            selectedIndex: _mixGrade.index,
            onSelect: (index) {
              setState(() {
                _mixGrade = MixGrade.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_mixGrade.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 16),
          CalculatorTextField(
            label: _loc.translate('screed_unified.bag_weight'),
            value: _bagWeight,
            onChanged: (v) { setState(() { _bagWeight = v; _update(); }); },
            suffix: _loc.translate('common.kg'),
            accentColor: _accentColor,
            minValue: 25,
            maxValue: 50,
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
              _loc.translate('screed_unified.mode.manual'),
              _loc.translate('screed_unified.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = AreaInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == AreaInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('screed_unified.label.area'),
      value: _area,
      min: 5,
      max: 200,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('screed_unified.label.width'),
                value: _roomWidth,
                onChanged: (v) { setState(() { _roomWidth = v; _update(); }); },
                suffix: _loc.translate('common.meters'),
                accentColor: _accentColor,
                minValue: 0.5,
                maxValue: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('screed_unified.label.length'),
                value: _roomLength,
                onChanged: (v) { setState(() { _roomLength = v; _update(); }); },
                suffix: _loc.translate('common.meters'),
                accentColor: _accentColor,
                minValue: 0.5,
                maxValue: 30,
              ),
            ),
          ],
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
                _loc.translate('screed_unified.label.floor_area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
              ),
              Text(
                '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThicknessCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('screed_unified.label.thickness'),
            value: _thickness,
            min: 10,
            max: 150,
            divisions: 28,
            suffix: _loc.translate('common.mm'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _thickness = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('screed_unified.thickness_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
          if (_result.thicknessWarning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 18, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loc.translate('screed_unified.thickness_warning'),
                      style: TextStyle(fontSize: 12, color: Colors.red[900], fontWeight: FontWeight.w500),
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

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('screed_unified.options_title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 8),
          _buildOptionSwitch(
            title: _loc.translate('screed_unified.option.mesh'),
            subtitle: _loc.translate('screed_unified.option.mesh_desc'),
            value: _needMesh,
            onChanged: (v) { setState(() { _needMesh = v; _update(); }); },
          ),
          _buildOptionSwitch(
            title: _loc.translate('screed_unified.option.film'),
            subtitle: _loc.translate('screed_unified.option.film_desc'),
            value: _needFilm,
            onChanged: (v) { setState(() { _needFilm = v; _update(); }); },
          ),
          _buildOptionSwitch(
            title: _loc.translate('screed_unified.option.tape'),
            subtitle: _loc.translate('screed_unified.option.tape_desc'),
            value: _needTape,
            onChanged: (v) { setState(() { _needTape = v; _update(); }); },
          ),
          _buildOptionSwitch(
            title: _loc.translate('screed_unified.option.beacons'),
            subtitle: _loc.translate('screed_unified.option.beacons_desc'),
            value: _needBeacons,
            onChanged: (v) { setState(() { _needBeacons = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
      subtitle: Text(subtitle, style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
      value: value,
      activeTrackColor: _accentColor,
      onChanged: onChanged,
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_materialMethod == MaterialMethod.readyMix) {
      // Готовая смесь
      items.add(MaterialItem(
        name: _loc.translate(_mixGrade.nameKey),
        value: '${_result.mixBags} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.mixWeightKg.toStringAsFixed(0)} ${_loc.translate('common.kg')} (${_result.mixWeightTonnes.toStringAsFixed(2)} ${_loc.translate('common.ton')})',
        icon: Icons.shopping_bag,
      ));
    } else {
      // Самозамес
      items.add(MaterialItem(
        name: _loc.translate('screed_unified.materials.cement'),
        value: '${_result.cementBags} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.cementKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.inventory_2,
      ));
      items.add(MaterialItem(
        name: _loc.translate('screed_unified.materials.sand'),
        value: '${_result.sandCbm.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
        subtitle: '${_result.sandKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.grain,
      ));
      if (_screedType == ScreedType.concrete && _result.gravelCbm > 0) {
        items.add(MaterialItem(
          name: _loc.translate('screed_unified.materials.gravel'),
          value: '${_result.gravelCbm.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
          subtitle: '${_result.gravelKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
          icon: Icons.bubble_chart,
        ));
      }
    }

    // Дополнительные материалы
    if (_needMesh && _result.meshArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('screed_unified.materials.mesh'),
        value: '${_result.meshArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('screed_unified.materials.mesh_desc'),
        icon: Icons.grid_on,
      ));
    }

    if (_needFilm && _result.filmArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('screed_unified.materials.film'),
        value: '${_result.filmArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('screed_unified.materials.film_desc'),
        icon: Icons.layers,
      ));
    }

    if (_needTape && _result.tapeMeters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('screed_unified.materials.tape'),
        value: '${_result.tapeMeters.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('screed_unified.materials.tape_desc'),
        icon: Icons.linear_scale,
      ));
    }

    if (_needBeacons && _result.beaconsNeeded > 0) {
      items.add(MaterialItem(
        name: _loc.translate('screed_unified.materials.beacons'),
        value: '${_result.beaconsNeeded} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('screed_unified.materials.beacons_desc'),
        icon: Icons.architecture,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('screed_unified.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    // Советы по типу стяжки
    switch (_screedType) {
      case ScreedType.cementSand:
        tips.add(_loc.translate('screed_unified.tip.cement_sand_1'));
        tips.add(_loc.translate('screed_unified.tip.cement_sand_2'));
        break;
      case ScreedType.semidry:
        tips.add(_loc.translate('screed_unified.tip.semidry_1'));
        tips.add(_loc.translate('screed_unified.tip.semidry_2'));
        break;
      case ScreedType.concrete:
        tips.add(_loc.translate('screed_unified.tip.concrete_1'));
        tips.add(_loc.translate('screed_unified.tip.concrete_2'));
        break;
    }

    // Советы по способу
    if (_materialMethod == MaterialMethod.readyMix) {
      tips.add(_loc.translate('screed_unified.tip.ready_mix'));
    } else {
      tips.add(_loc.translate('screed_unified.tip.self_mix'));
    }

    tips.add(_loc.translate('screed_unified.tip.common'));

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
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
