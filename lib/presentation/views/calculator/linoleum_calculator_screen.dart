import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_linoleum_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип линолеума
enum LinoleumType {
  household('linoleum_calc.type.household', 'linoleum_calc.type.household_desc', Icons.home),
  semiCommercial('linoleum_calc.type.semi_commercial', 'linoleum_calc.type.semi_commercial_desc', Icons.business),
  commercial('linoleum_calc.type.commercial', 'linoleum_calc.type.commercial_desc', Icons.factory);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LinoleumType(this.nameKey, this.descKey, this.icon);
}

class _LinoleumResult {
  final double area;
  final double areaWithWaste;
  final double rollsNeeded;
  final double rollWidth;
  final double linearMeters;
  final double tapeLength;
  final double plinthLength;
  final int plinthPieces;
  final double marginCm;

  const _LinoleumResult({
    required this.area,
    required this.areaWithWaste,
    required this.rollsNeeded,
    required this.rollWidth,
    required this.linearMeters,
    required this.tapeLength,
    required this.plinthLength,
    required this.plinthPieces,
    required this.marginCm,
  });

  factory _LinoleumResult.fromCalculatorResult(Map<String, double> values) {
    return _LinoleumResult(
      area: values['area'] ?? 0,
      areaWithWaste: values['areaWithWaste'] ?? 0,
      rollsNeeded: values['rollsNeeded'] ?? 0,
      rollWidth: values['rollWidth'] ?? 3.0,
      linearMeters: values['linearMeters'] ?? 0,
      tapeLength: values['tapeLength'] ?? 0,
      plinthLength: values['plinthLength'] ?? 0,
      plinthPieces: (values['plinthPieces'] ?? 0).toInt(),
      marginCm: values['marginCm'] ?? 20.0,
    );
  }
}

class LinoleumCalculatorScreen extends ConsumerStatefulWidget {
  const LinoleumCalculatorScreen({super.key});

  @override
  ConsumerState<LinoleumCalculatorScreen> createState() => _LinoleumCalculatorScreenState();
}

class _LinoleumCalculatorScreenState extends ConsumerState<LinoleumCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('linoleum_calc.title');

  // Domain layer calculator
  final _calculator = CalculateLinoleumV2();

  // Размеры комнаты
  double _roomWidth = 4.0;
  double _roomLength = 5.0;

  // Параметры
  double _rollWidth = 3.0; // м
  double _marginCm = 20.0; // запас в см

  LinoleumType _linoleumType = LinoleumType.semiCommercial;
  bool _needPlinth = true;
  bool _needTape = true;

  late _LinoleumResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _LinoleumResult _calculate() {
    final inputs = <String, double>{
      'roomWidth': _roomWidth,
      'roomLength': _roomLength,
      'rollWidth': _rollWidth,
      'marginCm': _marginCm,
      'needTape': _needTape ? 1.0 : 0.0,
      'needPlinth': _needPlinth ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _LinoleumResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('linoleum_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln('Комната: ${_roomWidth.toStringAsFixed(1)} × ${_roomLength.toStringAsFixed(1)} м');
    buffer.writeln(_loc.translate('linoleum_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('linoleum_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_linoleumType.nameKey)));
    buffer.writeln('Запас: +${_marginCm.toStringAsFixed(0)} см');
    buffer.writeln();
    buffer.writeln(_loc.translate('linoleum_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('linoleum_calc.export.linoleum')
        .replaceFirst('{value}', _result.areaWithWaste.toStringAsFixed(1)));
    if (_needTape) {
      buffer.writeln(_loc.translate('linoleum_calc.export.tape')
          .replaceFirst('{value}', _result.tapeLength.toStringAsFixed(1)));
    }
    if (_needPlinth) {
      buffer.writeln(_loc.translate('linoleum_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('linoleum_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('linoleum_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('linoleum_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('linoleum_calc.result.linoleum').toUpperCase(),
            value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.layers,
          ),
          ResultItem(
            label: _loc.translate('linoleum_calc.result.plinth').toUpperCase(),
            value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
            icon: Icons.straighten,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildRoomDimensionsCard(),
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

    switch (_linoleumType) {
      case LinoleumType.household:
        tips.addAll([
          _loc.translate('linoleum_calc.tip.household_1'),
          _loc.translate('linoleum_calc.tip.household_2'),
        ]);
        break;
      case LinoleumType.semiCommercial:
        tips.addAll([
          _loc.translate('linoleum_calc.tip.semi_commercial_1'),
          _loc.translate('linoleum_calc.tip.semi_commercial_2'),
        ]);
        break;
      case LinoleumType.commercial:
        tips.addAll([
          _loc.translate('linoleum_calc.tip.commercial_1'),
          _loc.translate('linoleum_calc.tip.commercial_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('linoleum_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: LinoleumType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _linoleumType.index,
      onSelect: (index) {
        setState(() {
          _linoleumType = LinoleumType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildRoomDimensionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Размеры комнаты',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('linoleum_calc.label.width'),
                  value: _roomWidth,
                  onChanged: (v) {
                    setState(() {
                      _roomWidth = v;
                      _update();
                    });
                  },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 1,
                  maxValue: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('linoleum_calc.label.length'),
                  value: _roomLength,
                  onChanged: (v) {
                    setState(() {
                      _roomLength = v;
                      _update();
                    });
                  },
                  suffix: _loc.translate('common.meters'),
                  accentColor: _accentColor,
                  minValue: 1,
                  maxValue: 20,
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
                  _loc.translate('linoleum_calc.label.floor_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
                Text(
                  '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: _accentColor,
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

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Параметры',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Ширина рулона
          CalculatorSliderField(
            label: _loc.translate('linoleum_calc.label.roll_width'),
            value: _rollWidth,
            min: 2.0,
            max: 5.0,
            divisions: 6,
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            decimalPlaces: 1,
            onChanged: (v) {
              setState(() {
                _rollWidth = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 16),
          // Запас
          CalculatorSliderField(
            label: 'Запас по краям',
            value: _marginCm,
            min: 0,
            max: 50,
            divisions: 10,
            suffix: 'см',
            accentColor: _accentColor,
            decimalPlaces: 0,
            onChanged: (v) {
              setState(() {
                _marginCm = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          // Подсказка про запас
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _marginCm >= 20 ? Icons.check_circle : Icons.info_outline,
                  color: _marginCm >= 20 ? Colors.green : _accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _marginCm >= 20
                        ? 'Рекомендуемый запас для подрезки'
                        : 'Рекомендуется минимум 20 см',
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('linoleum_calc.option.tape'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _loc.translate('linoleum_calc.option.tape_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _needTape,
            activeTrackColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _needTape = v;
                _update();
              });
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _loc.translate('linoleum_calc.option.plinth'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _loc.translate('linoleum_calc.option.plinth_desc'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _needPlinth,
            activeTrackColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _needPlinth = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('linoleum_calc.materials.linoleum'),
        value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate(_linoleumType.nameKey),
        icon: Icons.layers,
      ),
      if (_result.linearMeters > 0)
        MaterialItem(
          name: _loc.translate('linoleum_calc.materials.linear_meters'),
          value: '${_result.linearMeters.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
          subtitle: '${_loc.translate('linoleum_calc.materials.roll_width')}: ${_result.rollWidth.toStringAsFixed(1)} м',
          icon: Icons.straighten,
        ),
    ];

    if (_needTape && _result.tapeLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('linoleum_calc.materials.tape'),
        value: '${_result.tapeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('linoleum_calc.materials.tape_desc'),
        icon: Icons.content_cut,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('linoleum_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('linoleum_calc.section.materials'),
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
