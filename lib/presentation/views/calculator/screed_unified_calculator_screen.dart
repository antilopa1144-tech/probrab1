import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_screed_unified.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип сухой смеси
enum ScreedMixType {
  cps('screed_unified.mix_type.cps', 'screed_unified.mix_type.cps_desc', Icons.grain),
  peskobeton('screed_unified.mix_type.peskobeton', 'screed_unified.mix_type.peskobeton_desc', Icons.foundation);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const ScreedMixType(this.nameKey, this.descKey, this.icon);
}

/// Марки ЦПС
enum CpsMarka {
  m100('screed_unified.cps.m100', 'screed_unified.cps.m100_desc', '15 кг/м²/см'),
  m150('screed_unified.cps.m150', 'screed_unified.cps.m150_desc', '17 кг/м²/см'),
  m200('screed_unified.cps.m200', 'screed_unified.cps.m200_desc', '18 кг/м²/см');

  final String nameKey;
  final String descKey;
  final String consumption;
  const CpsMarka(this.nameKey, this.descKey, this.consumption);
}

/// Марки Пескобетона
enum PeskobetonMarka {
  m200('screed_unified.peskobeton.m200', 'screed_unified.peskobeton.m200_desc', '19 кг/м²/см'),
  m300('screed_unified.peskobeton.m300', 'screed_unified.peskobeton.m300_desc', '20 кг/м²/см'),
  m400('screed_unified.peskobeton.m400', 'screed_unified.peskobeton.m400_desc', '22 кг/м²/см');

  final String nameKey;
  final String descKey;
  final String consumption;
  const PeskobetonMarka(this.nameKey, this.descKey, this.consumption);
}

/// Режим ввода площади
enum AreaInputMode { manual, room }

/// Результат расчёта для UI
class _ScreedResult {
  final double area;
  final double perimeter;
  final double volume;
  final double thickness;
  final double mixWeightKg;
  final double mixWeightTonnes;
  final int mixBags;
  final double consumption;
  final double meshArea;
  final double filmArea;
  final double tapeMeters;
  final int beaconsNeeded;
  final bool thicknessWarning;
  final bool typeThicknessWarning;

  const _ScreedResult({
    required this.area,
    required this.perimeter,
    required this.volume,
    required this.thickness,
    required this.mixWeightKg,
    required this.mixWeightTonnes,
    required this.mixBags,
    required this.consumption,
    required this.meshArea,
    required this.filmArea,
    required this.tapeMeters,
    required this.beaconsNeeded,
    required this.thicknessWarning,
    required this.typeThicknessWarning,
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
      consumption: values['consumption'] ?? 0,
      meshArea: values['meshArea'] ?? 0,
      filmArea: values['filmArea'] ?? 0,
      tapeMeters: values['tapeMeters'] ?? 0,
      beaconsNeeded: (values['beaconsNeeded'] ?? 0).toInt(),
      thicknessWarning: (values['thicknessWarning'] ?? 0) > 0,
      typeThicknessWarning: (values['typeThicknessWarning'] ?? 0) > 0,
    );
  }
}

/// Калькулятор стяжки пола (ЦПС / Пескобетон).
///
/// Современный калькулятор для расчёта сухих смесей:
/// - ЦПС (цементно-песчаная смесь): М100, М150, М200
/// - Пескобетон: М200, М300, М400
///
/// Особенности:
/// - Расход по СП 29.13330.2011
/// - Рекомендации по маркам в зависимости от толщины
/// - Расчёт дополнительных материалов
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
  ScreedMixType _mixType = ScreedMixType.cps;
  CpsMarka _cpsMarka = CpsMarka.m150;
  PeskobetonMarka _peskobetonMarka = PeskobetonMarka.m300;
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
      'mixType': _mixType.index.toDouble(),
      'cpsMarka': _cpsMarka.index.toDouble(),
      'peskobetonMarka': _peskobetonMarka.index.toDouble(),
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

  /// Получить рекомендуемую марку для текущей толщины
  String _getRecommendedMarka() {
    return CalculateScreedUnified.getRecommendedMarka(_mixType.index, _thickness);
  }

  /// Проверить, выбрана ли рекомендуемая марка
  bool _isRecommendedMarka() {
    final recommended = _getRecommendedMarka();
    if (_mixType == ScreedMixType.cps) {
      return _cpsMarka.nameKey.contains(recommended.replaceAll('М', 'm'));
    } else {
      return _peskobetonMarka.nameKey.contains(recommended.replaceAll('М', 'm'));
    }
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('screed_unified.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    // Параметры
    final mixTypeName = _loc.translate(_mixType.nameKey);
    final markaName = _mixType == ScreedMixType.cps
        ? _loc.translate(_cpsMarka.nameKey)
        : _loc.translate(_peskobetonMarka.nameKey);

    buffer.writeln('${_loc.translate('screed_unified.export.mix_type')}: $mixTypeName $markaName');
    buffer.writeln('${_loc.translate('screed_unified.export.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('screed_unified.export.thickness')}: ${_result.thickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}');
    buffer.writeln('${_loc.translate('screed_unified.export.volume')}: ${_result.volume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}');
    buffer.writeln();

    // Материалы
    buffer.writeln(_loc.translate('screed_unified.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('$markaName: ${_result.mixBags} ${_loc.translate('common.pcs')} (${_result.mixWeightKg.toStringAsFixed(0)} ${_loc.translate('common.kg')})');

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
        _buildMixTypeSelector(),
        const SizedBox(height: 16),
        _buildMarkaSelector(),
        const SizedBox(height: 16),
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
    final markaName = _mixType == ScreedMixType.cps
        ? _loc.translate(_cpsMarka.nameKey)
        : _loc.translate(_peskobetonMarka.nameKey);

    return CalculatorResultHeader(
      accentColor: _accentColor,
      results: [
        ResultItem(
          label: _loc.translate('screed_unified.result.area').toUpperCase(),
          value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
          icon: Icons.straighten,
        ),
        ResultItem(
          label: markaName.toUpperCase(),
          value: '${_result.mixBags} ${_loc.translate('common.pcs')}',
          icon: Icons.shopping_bag,
        ),
        ResultItem(
          label: _loc.translate('screed_unified.result.weight').toUpperCase(),
          value: '${_result.mixWeightTonnes.toStringAsFixed(2)} ${_loc.translate('common.ton')}',
          icon: Icons.scale,
        ),
      ],
    );
  }

  Widget _buildMixTypeSelector() {
    return TypeSelectorGroup(
      options: ScreedMixType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _mixType.index,
      onSelect: (index) {
        setState(() {
          _mixType = ScreedMixType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildMarkaSelector() {
    final recommended = _getRecommendedMarka();
    final isRecommended = _isRecommendedMarka();

    if (_mixType == ScreedMixType.cps) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _loc.translate('screed_unified.marka_title'),
                    style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
                  ),
                ),
                if (!isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '★ $recommended',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TypeSelectorGroup(
              options: CpsMarka.values.map((m) => TypeSelectorOption(
                icon: Icons.inventory_2,
                title: _loc.translate(m.nameKey),
                subtitle: m.consumption,
              )).toList(),
              selectedIndex: _cpsMarka.index,
              onSelect: (index) {
                setState(() {
                  _cpsMarka = CpsMarka.values[index];
                  _update();
                });
              },
              accentColor: _accentColor,
            ),
            const SizedBox(height: 12),
            Text(
              _loc.translate(_cpsMarka.descKey),
              style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildBagWeightField(),
          ],
        ),
      );
    } else {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _loc.translate('screed_unified.marka_title'),
                    style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
                  ),
                ),
                if (!isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '★ $recommended',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TypeSelectorGroup(
              options: PeskobetonMarka.values.map((m) => TypeSelectorOption(
                icon: Icons.inventory_2,
                title: _loc.translate(m.nameKey),
                subtitle: m.consumption,
              )).toList(),
              selectedIndex: _peskobetonMarka.index,
              onSelect: (index) {
                setState(() {
                  _peskobetonMarka = PeskobetonMarka.values[index];
                  _update();
                });
              },
              accentColor: _accentColor,
            ),
            const SizedBox(height: 12),
            Text(
              _loc.translate(_peskobetonMarka.descKey),
              style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildBagWeightField(),
          ],
        ),
      );
    }
  }

  Widget _buildBagWeightField() {
    final bagWeights = [25.0, 40.0, 50.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate('screed_unified.bag_weight'),
          style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: bagWeights.map((weight) {
            final isSelected = _bagWeight == weight;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: weight != bagWeights.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _bagWeight = weight;
                      _update();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accentColor.withValues(alpha: 0.15)
                          : CalculatorColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _accentColor : CalculatorColors.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${weight.toInt()}',
                          style: CalculatorDesignSystem.titleLarge.copyWith(
                            color: isSelected ? _accentColor : CalculatorColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        Text(
                          _loc.translate('common.kg'),
                          style: CalculatorDesignSystem.bodySmall.copyWith(
                            color: isSelected ? _accentColor : CalculatorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
    final minThickness = _mixType == ScreedMixType.cps ? 20.0 : 30.0;
    final showTypeWarning = _thickness < minThickness;

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
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: CalculatorColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _loc.translate('screed_unified.thickness_hint'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
                ),
              ),
            ],
          ),
          if (_result.thicknessWarning || showTypeWarning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      showTypeWarning
                          ? _loc.translate('screed_unified.thickness_type_warning')
                              .replaceFirst('{min}', minThickness.toStringAsFixed(0))
                              .replaceFirst('{type}', _loc.translate(_mixType.nameKey))
                          : _loc.translate('screed_unified.thickness_warning'),
                      style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w500),
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
    final markaName = _mixType == ScreedMixType.cps
        ? _loc.translate(_cpsMarka.nameKey)
        : _loc.translate(_peskobetonMarka.nameKey);

    final items = <MaterialItem>[
      MaterialItem(
        name: '${_loc.translate(_mixType.nameKey)} $markaName',
        value: '${_result.mixBags} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.mixWeightKg.toStringAsFixed(0)} ${_loc.translate('common.kg')} (${_result.mixWeightTonnes.toStringAsFixed(2)} ${_loc.translate('common.ton')})',
        icon: Icons.shopping_bag,
      ),
    ];

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

    // Советы по типу смеси
    if (_mixType == ScreedMixType.cps) {
      tips.add(_loc.translate('screed_unified.tip.cps_1'));
      tips.add(_loc.translate('screed_unified.tip.cps_2'));
    } else {
      tips.add(_loc.translate('screed_unified.tip.peskobeton_1'));
      tips.add(_loc.translate('screed_unified.tip.peskobeton_2'));
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
