import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип ленточного фундамента
enum StripFoundationType {
  monolithic(
    'strip_calc.type.monolithic',
    'strip_calc.type.monolithic_desc',
    Icons.view_module,
  ),
  prefab(
    'strip_calc.type.prefab',
    'strip_calc.type.prefab_desc',
    Icons.view_agenda,
  ),
  shallow(
    'strip_calc.type.shallow',
    'strip_calc.type.shallow_desc',
    Icons.layers,
  ),
  deep(
    'strip_calc.type.deep',
    'strip_calc.type.deep_desc',
    Icons.foundation,
  );

  final String nameKey;
  final String descKey;
  final IconData icon;
  const StripFoundationType(this.nameKey, this.descKey, this.icon);
}

class _StripResult {
  final double perimeter;
  final double stripVolume;
  final double concreteVolume;
  final double rebarWeight;
  final double formworkArea;
  final double waterproofingArea;
  final double insulationArea;
  final double sandVolume;
  final double gravelVolume;
  final int fbsBlocksCount;

  const _StripResult({
    required this.perimeter,
    required this.stripVolume,
    required this.concreteVolume,
    required this.rebarWeight,
    required this.formworkArea,
    required this.waterproofingArea,
    required this.insulationArea,
    required this.sandVolume,
    required this.gravelVolume,
    required this.fbsBlocksCount,
  });
}

/// Калькулятор ленточного фундамента
class StripFoundationCalculatorScreen extends ConsumerStatefulWidget {
  const StripFoundationCalculatorScreen({super.key});

  @override
  ConsumerState<StripFoundationCalculatorScreen> createState() =>
      _StripFoundationCalculatorScreenState();
}

class _StripFoundationCalculatorScreenState
    extends ConsumerState<StripFoundationCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('strip_calc.title');

  bool _isDark = false;
  // Размеры дома
  double _houseLength = 10.0;
  double _houseWidth = 8.0;

  // Размеры ленты
  double _stripWidth = 0.4; // метры
  double _stripHeight = 0.8; // метры

  // Тип и опции
  StripFoundationType _foundationType = StripFoundationType.monolithic;
  bool _needWaterproof = true;
  bool _needInsulation = false;
  bool _hasInternalWalls = true;
  double _internalWallsLength = 8.0;

  late _StripResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.foundation;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _StripResult _calculate() {
    // Расчёт периметра
    double perimeter = 2 * (_houseLength + _houseWidth);
    if (_hasInternalWalls) {
      perimeter += _internalWallsLength;
    }

    // Объём ленты
    final stripVolume = perimeter * _stripWidth * _stripHeight;

    // Бетон (с запасом 5%)
    double concreteVolume = stripVolume * 1.05;

    // Для сборного фундамента бетон только на швы
    int fbsBlocksCount = 0;
    if (_foundationType == StripFoundationType.prefab) {
      // Стандартный ФБС 2400x600x580мм = 0.84 м³
      const fbsVolume = 2.4 * 0.6 * 0.58;
      fbsBlocksCount = (stripVolume / fbsVolume).ceil();
      concreteVolume = fbsBlocksCount * 0.02; // раствор на швы
    }

    // Арматура: ~80 кг на м³ бетона для монолитного
    double rebarWeight = 0;
    if (_foundationType != StripFoundationType.prefab) {
      rebarWeight = stripVolume * 80;
    }

    // Опалубка: две стороны по высоте ленты
    final formworkArea =
        _foundationType != StripFoundationType.prefab ? perimeter * _stripHeight * 2 : 0.0;

    // Гидроизоляция: дно + стены
    final waterproofingArea =
        _needWaterproof ? perimeter * (_stripWidth + _stripHeight * 2) * 1.1 : 0.0;

    // Утепление: только внешние стены
    final insulationArea =
        _needInsulation ? 2 * (_houseLength + _houseWidth) * _stripHeight * 1.1 : 0.0;

    // Подушка: песок 15см, щебень 10см
    final cushionArea = perimeter * (_stripWidth + 0.2); // +20см по бокам
    final sandVolume = cushionArea * 0.15;
    final gravelVolume = cushionArea * 0.10;

    return _StripResult(
      perimeter: perimeter,
      stripVolume: stripVolume,
      concreteVolume: concreteVolume,
      rebarWeight: rebarWeight,
      formworkArea: formworkArea,
      waterproofingArea: waterproofingArea,
      insulationArea: insulationArea,
      sandVolume: sandVolume,
      gravelVolume: gravelVolume,
      fbsBlocksCount: fbsBlocksCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('strip_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc
        .translate('strip_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_foundationType.nameKey)));
    buffer.writeln(_loc
        .translate('strip_calc.export.perimeter')
        .replaceFirst('{value}', _result.perimeter.toStringAsFixed(1)));
    buffer.writeln(_loc
        .translate('strip_calc.export.dimensions')
        .replaceFirst('{width}', (_stripWidth * 100).toStringAsFixed(0))
        .replaceFirst('{height}', (_stripHeight * 100).toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln(_loc.translate('strip_calc.export.materials'));
    buffer.writeln('─' * 40);

    if (_foundationType == StripFoundationType.prefab) {
      buffer.writeln(_loc
          .translate('strip_calc.export.fbs')
          .replaceFirst('{value}', _result.fbsBlocksCount.toString()));
    } else {
      buffer.writeln(_loc
          .translate('strip_calc.export.concrete')
          .replaceFirst('{value}', _result.concreteVolume.toStringAsFixed(1)));
      buffer.writeln(_loc
          .translate('strip_calc.export.rebar')
          .replaceFirst('{value}', _result.rebarWeight.toStringAsFixed(0)));
      buffer.writeln(_loc
          .translate('strip_calc.export.formwork')
          .replaceFirst('{value}', _result.formworkArea.toStringAsFixed(1)));
    }

    buffer.writeln(_loc
        .translate('strip_calc.export.sand')
        .replaceFirst('{value}', _result.sandVolume.toStringAsFixed(1)));
    buffer.writeln(_loc
        .translate('strip_calc.export.gravel')
        .replaceFirst('{value}', _result.gravelVolume.toStringAsFixed(1)));

    if (_needWaterproof) {
      buffer.writeln(_loc
          .translate('strip_calc.export.waterproof')
          .replaceFirst('{value}', _result.waterproofingArea.toStringAsFixed(1)));
    }
    if (_needInsulation) {
      buffer.writeln(_loc
          .translate('strip_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('strip_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('strip_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('strip_calc.result.perimeter').toUpperCase(),
            value:
                '${_result.perimeter.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
            icon: Icons.crop_square,
          ),
          if (_foundationType == StripFoundationType.prefab)
            ResultItem(
              label: _loc.translate('strip_calc.result.fbs').toUpperCase(),
              value:
                  '${_result.fbsBlocksCount} ${_loc.translate('common.pcs')}',
              icon: Icons.view_agenda,
            )
          else
            ResultItem(
              label: _loc.translate('strip_calc.result.concrete').toUpperCase(),
              value:
                  '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
              icon: Icons.view_in_ar,
            ),
          if (_foundationType != StripFoundationType.prefab)
            ResultItem(
              label: _loc.translate('strip_calc.result.rebar').toUpperCase(),
              value:
                  '${_result.rebarWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
              icon: Icons.grid_4x4,
            ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildHouseDimensionsCard(),
        const SizedBox(height: 16),
        _buildStripDimensionsCard(),
        const SizedBox(height: 16),
        _buildInternalWallsCard(),
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

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: StripFoundationType.values
          .map((type) => TypeSelectorOption(
                icon: type.icon,
                title: _loc.translate(type.nameKey),
                subtitle: _loc.translate(type.descKey),
              ))
          .toList(),
      selectedIndex: _foundationType.index,
      onSelect: (index) {
        setState(() {
          _foundationType = StripFoundationType.values[index];
          // Для мелкозаглубленного ограничиваем высоту
          if (_foundationType == StripFoundationType.shallow &&
              _stripHeight > 0.7) {
            _stripHeight = 0.5;
          }
          // Для заглубленного минимальная высота
          if (_foundationType == StripFoundationType.deep &&
              _stripHeight < 1.0) {
            _stripHeight = 1.2;
          }
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildHouseDimensionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('strip_calc.house_dimensions'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('strip_calc.house_length'),
                  value: _houseLength,
                  onChanged: (v) {
                    setState(() {
                      _houseLength = v;
                      _update();
                    });
                  },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 4,
                  maxValue: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('strip_calc.house_width'),
                  value: _houseWidth,
                  onChanged: (v) {
                    setState(() {
                      _houseWidth = v;
                      _update();
                    });
                  },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 4,
                  maxValue: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripDimensionsCard() {
    // Ограничения в зависимости от типа
    double minHeight = 0.3;
    double maxHeight = 1.5;
    String hint = _loc.translate('strip_calc.dimensions_hint');

    switch (_foundationType) {
      case StripFoundationType.shallow:
        minHeight = 0.3;
        maxHeight = 0.7;
        hint = _loc.translate('strip_calc.shallow_hint');
        break;
      case StripFoundationType.deep:
        minHeight = 1.0;
        maxHeight = 2.0;
        hint = _loc.translate('strip_calc.deep_hint');
        break;
      default:
        break;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('strip_calc.strip_dimensions'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          // Ширина ленты
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('strip_calc.strip_width'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${(_stripWidth * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _stripWidth * 100,
            min: 25,
            max: 60,
            divisions: 7,
            activeColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _stripWidth = v / 100;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          // Высота ленты
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('strip_calc.strip_height'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${(_stripHeight * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _stripHeight.clamp(minHeight, maxHeight) * 100,
            min: minHeight * 100,
            max: maxHeight * 100,
            divisions: ((maxHeight - minHeight) * 10).round(),
            activeColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _stripHeight = v / 100;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalWallsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('strip_calc.internal_walls'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('strip_calc.internal_walls_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _hasInternalWalls,
            activeTrackColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _hasInternalWalls = v;
                _update();
              });
            },
          ),
          if (_hasInternalWalls) ...[
            const SizedBox(height: 12),
            CalculatorTextField(
              label: _loc.translate('strip_calc.internal_walls_length'),
              value: _internalWallsLength,
              onChanged: (v) {
                setState(() {
                  _internalWallsLength = v;
                  _update();
                });
              },
              suffix: _loc.translate('common.meters'),
              accentColor: _accentColor,
              minValue: 0,
              maxValue: 50,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('strip_calc.option.waterproof'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('strip_calc.option.waterproof_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _needWaterproof,
            activeTrackColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _needWaterproof = v;
                _update();
              });
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('strip_calc.option.insulation'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            subtitle: Text(
              _loc.translate('strip_calc.option.insulation_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _needInsulation,
            activeTrackColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _needInsulation = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_foundationType == StripFoundationType.prefab) {
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.fbs'),
        value: '${_result.fbsBlocksCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('strip_calc.materials.fbs_desc'),
        icon: Icons.view_agenda,
      ));
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.mortar'),
        value:
            '${_result.concreteVolume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('strip_calc.materials.mortar_desc'),
        icon: Icons.opacity,
      ));
    } else {
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.concrete'),
        value:
            '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('strip_calc.materials.concrete_desc'),
        icon: Icons.view_in_ar,
      ));
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.rebar'),
        value:
            '${_result.rebarWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('strip_calc.materials.rebar_desc'),
        icon: Icons.grid_4x4,
      ));
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.formwork'),
        value:
            '${_result.formworkArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('strip_calc.materials.formwork_desc'),
        icon: Icons.view_sidebar,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('strip_calc.materials.sand'),
      value:
          '${_result.sandVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
      subtitle: _loc.translate('strip_calc.materials.sand_desc'),
      icon: Icons.grain,
    ));

    items.add(MaterialItem(
      name: _loc.translate('strip_calc.materials.gravel'),
      value:
          '${_result.gravelVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
      subtitle: _loc.translate('strip_calc.materials.gravel_desc'),
      icon: Icons.circle,
    ));

    if (_needWaterproof && _result.waterproofingArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.waterproof'),
        value:
            '${_result.waterproofingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('strip_calc.materials.waterproof_desc'),
        icon: Icons.water_drop,
      ));
    }

    if (_needInsulation && _result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('strip_calc.materials.insulation'),
        value:
            '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('strip_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('strip_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_foundationType) {
      case StripFoundationType.monolithic:
        tips.addAll([
          _loc.translate('strip_calc.tip.monolithic_1'),
          _loc.translate('strip_calc.tip.monolithic_2'),
        ]);
        break;
      case StripFoundationType.prefab:
        tips.addAll([
          _loc.translate('strip_calc.tip.prefab_1'),
          _loc.translate('strip_calc.tip.prefab_2'),
        ]);
        break;
      case StripFoundationType.shallow:
        tips.addAll([
          _loc.translate('strip_calc.tip.shallow_1'),
          _loc.translate('strip_calc.tip.shallow_2'),
        ]);
        break;
      case StripFoundationType.deep:
        tips.addAll([
          _loc.translate('strip_calc.tip.deep_1'),
          _loc.translate('strip_calc.tip.deep_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('strip_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
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
