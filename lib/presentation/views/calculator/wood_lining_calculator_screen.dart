import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

/// Типы вагонки
enum LiningType {
  standard('Стандарт', 'Обычная вагонка', 88.0, 3.0, Icons.view_agenda),
  euro('Евровагонка', 'С вентиляционными канавками', 96.0, 2.5, Icons.view_stream),
  blockHouse('Блок-хаус', 'Имитация бревна', 140.0, 2.0, Icons.circle_outlined),
  imitationBar('Имитация бруса', 'Прямой профиль', 140.0, 3.0, Icons.crop_square);

  final String name;
  final String description;
  final double width; // мм (полезная ширина)
  final double length; // м (стандартная длина доски)
  final IconData icon;

  const LiningType(this.name, this.description, this.width, this.length, this.icon);
}

/// Породы дерева
enum WoodSpecies {
  pine('Сосна', 'Доступная, универсальная'),
  spruce('Ель', 'Светлая, мягкая'),
  larch('Лиственница', 'Влагостойкая, прочная'),
  cedar('Кедр', 'Ароматная, элитная'),
  aspen('Осина', 'Для бань и саун'),
  alder('Ольха', 'Красивая текстура'),
  oak('Дуб', 'Премиум качество');

  final String name;
  final String description;

  const WoodSpecies(this.name, this.description);
}

/// Направление монтажа
enum MountingDirection {
  vertical('Вертикально', 'Визуально увеличивает высоту', Icons.vertical_distribute, '40×20'),
  horizontal('Горизонтально', 'Визуально расширяет пространство', Icons.horizontal_distribute, '40×20'),
  diagonal('Диагонально', 'Декоративный вариант', Icons.rotate_right, '40×20');

  final String name;
  final String hint;
  final IconData icon;
  final String battenSize;

  const MountingDirection(this.name, this.hint, this.icon, this.battenSize);
}

/// Тип крепления
enum FasteningType {
  klyaymery('Кляймеры', 'Скрытое крепление', 20),
  nails('Гвозди', 'Финишные гвозди', 25),
  screws('Саморезы', 'Надёжное крепление', 20);

  final String name;
  final String description;
  final int piecesPerM2;

  const FasteningType(this.name, this.description, this.piecesPerM2);
}

/// Тип финишного покрытия
enum FinishType {
  varnish('Лак', 0.15),
  oil('Масло', 0.12),
  wax('Воск', 0.1),
  stain('Морилка', 0.1);

  final String name;
  final double consumption; // л/м²

  const FinishType(this.name, this.consumption);
}

class _WoodLiningResult {
  final double area;
  final double liningArea;
  final int liningPieces;
  final double battenLength;
  final int fasteners;
  final double antiseptic;
  final double finish;
  final double insulation;
  final double vaporBarrier;
  final double vaporBarrierWeight;

  const _WoodLiningResult({
    required this.area,
    required this.liningArea,
    required this.liningPieces,
    required this.battenLength,
    required this.fasteners,
    required this.antiseptic,
    required this.finish,
    required this.insulation,
    required this.vaporBarrier,
    required this.vaporBarrierWeight,
  });
}

enum InputMode { byArea, byDimensions }

class WoodLiningCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const WoodLiningCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<WoodLiningCalculatorScreen> createState() =>
      _WoodLiningCalculatorScreenState();
}

class _WoodLiningCalculatorScreenState extends State<WoodLiningCalculatorScreen> {
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  double _height = 2.5;

  LiningType _liningType = LiningType.standard;
  WoodSpecies _woodSpecies = WoodSpecies.pine;
  MountingDirection _mountingDirection = MountingDirection.vertical;
  FasteningType _fasteningType = FasteningType.klyaymery;
  double _reserve = 10.0;

  bool _useInsulation = false;
  double _insulationThickness = 50.0;
  bool _useVaporBarrier = false;
  bool _useAntiseptic = true;
  bool _useFinish = false;
  FinishType _finishType = FinishType.varnish;

  late _WoodLiningResult _result;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final inputs = widget.initialInputs;
    if (inputs == null) return;

    _inputMode = (inputs['inputMode'] ?? 1) == 0 ? InputMode.byDimensions : InputMode.byArea;
    _area = inputs['area']?.clamp(1.0, 500.0) ?? 20.0;
    _length = inputs['length']?.clamp(0.1, 50.0) ?? 5.0;
    _width = inputs['width']?.clamp(0.1, 50.0) ?? 4.0;
    _height = inputs['height']?.clamp(2.0, 5.0) ?? 2.5;
    _reserve = inputs['reserve']?.clamp(5.0, 20.0) ?? 10.0;
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _WoodLiningResult _calculate() {
    final calculatedArea = _getCalculatedArea();
    if (calculatedArea <= 0) {
      return const _WoodLiningResult(
        area: 0,
        liningArea: 0,
        liningPieces: 0,
        battenLength: 0,
        fasteners: 0,
        antiseptic: 0,
        finish: 0,
        insulation: 0,
        vaporBarrier: 0,
        vaporBarrierWeight: 0,
      );
    }

    // Вагонка с запасом (используем только пользовательский запас)
    final liningArea = calculatedArea * (1 + _reserve / 100);
    final boardAreaM2 = _liningType.length * (_liningType.width / 1000);
    final liningPieces = (liningArea / boardAreaM2).ceil();

    // Обрешётка
    double battenLength;
    if (_mountingDirection == MountingDirection.vertical) {
      final battenCount = (_height / 0.5).ceil();
      final perimeterLength = _inputMode == InputMode.byArea
          ? math.sqrt(calculatedArea) * 4
          : 2 * (_length + _width);
      battenLength = battenCount * perimeterLength * 1.1;
    } else if (_mountingDirection == MountingDirection.horizontal) {
      final battenCount = _inputMode == InputMode.byArea
          ? (math.sqrt(calculatedArea) * 4 / 0.5).ceil()
          : ((_length + _width) * 2 / 0.5).ceil();
      battenLength = battenCount * _height * 1.1;
    } else {
      final battenCount = _inputMode == InputMode.byArea
          ? (math.sqrt(calculatedArea) * 4 / 0.5).ceil()
          : ((_length + _width) * 2 / 0.5).ceil();
      battenLength = battenCount * _height * 1.3;
    }

    // Крепёж
    final fasteners = (liningArea * _fasteningType.piecesPerM2).ceil();

    // Антисептик
    final antiseptic = _useAntiseptic ? calculatedArea * 0.2 * 1.1 : 0.0;

    // Финишное покрытие
    final finish = _useFinish ? calculatedArea * _finishType.consumption * 1.1 : 0.0;

    // Утеплитель
    final insulation = _useInsulation ? calculatedArea * 1.1 : 0.0;

    // Пароизоляция (20% на нахлёсты)
    final vaporBarrier = _useVaporBarrier ? calculatedArea * 1.2 : 0.0;
    final vaporBarrierWeight = vaporBarrier * 0.15;

    return _WoodLiningResult(
      area: calculatedArea,
      liningArea: liningArea,
      liningPieces: liningPieces,
      battenLength: battenLength,
      fasteners: fasteners,
      antiseptic: antiseptic,
      finish: finish,
      insulation: insulation,
      vaporBarrier: vaporBarrier,
      vaporBarrierWeight: vaporBarrierWeight,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _exportText() {
    final buffer = StringBuffer();
    buffer.writeln('📊 РАСЧЁТ ВАГОНКИ\n');
    buffer.writeln('Площадь: ${_result.area.toStringAsFixed(2)} м²');
    buffer.writeln('Тип: ${_liningType.name}');
    buffer.writeln('Порода: ${_woodSpecies.name}');
    buffer.writeln('Направление: ${_mountingDirection.name}\n');
    buffer.writeln('─────────────────────');
    buffer.writeln('ОСНОВНЫЕ МАТЕРИАЛЫ:');
    buffer.writeln('• Вагонка: ${_result.liningArea.toStringAsFixed(2)} м² (${_result.liningPieces} шт)');
    buffer.writeln('• Обрешётка: ${_result.battenLength.toStringAsFixed(1)} м.п.');
    buffer.writeln('• Крепёж: ${_result.fasteners} шт (${_fasteningType.name})');
    if (_useAntiseptic) {
      buffer.writeln('\nЗАЩИТА:');
      buffer.writeln('• Антисептик: ${_result.antiseptic.toStringAsFixed(2)} л');
    }
    if (_useFinish) {
      buffer.writeln('• ${_finishType.name}: ${_result.finish.toStringAsFixed(2)} л');
    }
    if (_useInsulation || _useVaporBarrier) {
      buffer.writeln('\nИЗОЛЯЦИЯ:');
      if (_useInsulation) {
        buffer.writeln('• Утеплитель: ${_result.insulation.toStringAsFixed(2)} м²');
      }
      if (_useVaporBarrier) {
        buffer.writeln('• Пароизоляция: ${_result.vaporBarrier.toStringAsFixed(2)} м²');
      }
    }
    buffer.writeln('\n─────────────────────');
    buffer.writeln('Запас: ${_reserve.toInt()}%');
    buffer.writeln('\n✨ Расчёт выполнен в ProRab');
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
    const accentColor = CalculatorColors.walls;

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
            label: 'ПЛОЩАДЬ',
            value: '${_result.area.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'ВАГОНКА',
            value: '${_result.liningPieces} шт',
            icon: Icons.carpenter,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildLiningTypeCard(),
        const SizedBox(height: 16),
        _buildWoodSpeciesCard(),
        const SizedBox(height: 16),
        _buildMountingDirectionCard(),
        const SizedBox(height: 16),
        _buildFasteningCard(),
        const SizedBox(height: 16),
        _buildFinishCard(),
        const SizedBox(height: 16),
        _buildReserveCard(),
        const SizedBox(height: 16),
        _buildOptionalMaterialsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildHints(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: ModeSelector(
        options: const ['По площади', 'По размерам'],
        selectedIndex: _inputMode.index,
        onSelect: (index) {
          setState(() {
            _inputMode = InputMode.values[index];
            _update();
          });
        },
        accentColor: accentColor,
      ),
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_inputMode == InputMode.byArea) ...[
            _buildSliderField(
              label: 'Площадь стен',
              value: _area,
              min: 1.0,
              max: 500.0,
              suffix: 'м²',
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ] else ...[
            _buildSliderField(
              label: 'Длина',
              value: _length,
              min: 0.1,
              max: 50.0,
              suffix: 'м',
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _length = v;
                  _update();
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Ширина',
              value: _width,
              min: 0.1,
              max: 50.0,
              suffix: 'м',
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _width = v;
                  _update();
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          _buildSliderField(
            label: 'Высота помещения',
            value: _height,
            min: 2.0,
            max: 5.0,
            suffix: 'м',
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _height = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiningTypeCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип вагонки',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<LiningType>(
            options: LiningType.values,
            minItemWidth: 220,
            minItemHeight: 96,
            itemBuilder: (type) {
              final isSelected = _liningType == type;
              return TypeSelectorCardCompact(
                icon: type.icon,
                title: type.name,
                subtitle: type.description,
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _liningType = type;
                    _update();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ширина: ${_liningType.width.toInt()} мм, длина: ${_liningType.length} м',
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodSpeciesCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Порода дерева',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<WoodSpecies>(
            options: WoodSpecies.values,
            minItemWidth: 170,
            itemBuilder: (species) {
              final isSelected = _woodSpecies == species;
              return TypeSelectorCardCompact(
                icon: Icons.nature,
                title: species.name,
                subtitle: species.description,
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _woodSpecies = species;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMountingDirectionCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Направление монтажа',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<MountingDirection>(
            options: MountingDirection.values,
            minItemWidth: 220,
            minItemHeight: 96,
            itemBuilder: (direction) {
              final isSelected = _mountingDirection == direction;
              return TypeSelectorCardCompact(
                icon: direction.icon,
                title: direction.name,
                subtitle: direction.hint,
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _mountingDirection = direction;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFasteningCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип крепления',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<FasteningType>(
            options: FasteningType.values,
            minItemWidth: 200,
            itemBuilder: (type) {
              final isSelected = _fasteningType == type;
              return TypeSelectorCardCompact(
                icon: Icons.construction,
                title: type.name,
                subtitle: type.description,
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _fasteningType = type;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinishCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Финишное покрытие',
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
            title: const Text(
              'Использовать финиш',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _useFinish ? _finishType.name : 'Не используется',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useFinish,
            onChanged: (v) {
              setState(() {
                _useFinish = v;
                _update();
              });
            },
          ),
          if (_useFinish) ...[
            const SizedBox(height: 8),
            _buildOptionGrid<FinishType>(
              options: FinishType.values,
              minItemWidth: 160,
              itemBuilder: (finish) {
                final isSelected = _finishType == finish;
                return TypeSelectorCardCompact(
                  icon: Icons.format_paint,
                  title: finish.name,
                  isSelected: isSelected,
                  accentColor: accentColor,
                  onTap: () {
                    setState(() {
                      _finishType = finish;
                      _update();
                    });
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReserveCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: _buildSliderField(
        label: 'Запас на обрезку',
        value: _reserve,
        min: 5.0,
        max: 20.0,
        suffix: '%',
        accentColor: accentColor,
        onChanged: (v) {
          setState(() {
            _reserve = v;
            _update();
          });
        },
      ),
    );
  }

  Widget _buildOptionalMaterialsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дополнительные материалы',
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
            title: const Text(
              'Утеплитель',
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _useInsulation ? 'Минвата ${_insulationThickness.toInt()} мм' : 'Не используется',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useInsulation,
            onChanged: (v) {
              setState(() {
                _useInsulation = v;
                _update();
              });
            },
          ),
          if (_useInsulation) ...[
            const SizedBox(height: 8),
            _buildSliderField(
              label: 'Толщина утеплителя',
              value: _insulationThickness,
              min: 50.0,
              max: 200.0,
              suffix: 'мм',
              divisions: 3,
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _insulationThickness = v;
                  _update();
                });
              },
            ),
          ],
          const Divider(),
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
            title: const Text('Пароизоляция', style: CalculatorDesignSystem.bodyMedium),
            subtitle: Text(
              _useVaporBarrier ? 'Мембрана ~0.15 кг/м²' : 'Не используется',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useVaporBarrier,
            onChanged: (v) {
              setState(() {
                _useVaporBarrier = v;
                _update();
              });
            },
          ),
          const Divider(),
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
            title: const Text('Антисептик', style: CalculatorDesignSystem.bodyMedium),
            subtitle: Text(
              _useAntiseptic ? 'Расход ~0.2 л/м²' : 'Не используется',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _useAntiseptic,
            onChanged: (v) {
              setState(() {
                _useAntiseptic = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: 'Вагонка',
        value: '${_result.liningArea.toStringAsFixed(1)} м²',
        subtitle: '${_result.liningPieces} шт',
        icon: Icons.view_agenda,
      ),
      MaterialItem(
        name: 'Обрешётка',
        value: '${_result.battenLength.toStringAsFixed(0)} м.п.',
        subtitle: 'Брус ${_mountingDirection.battenSize}',
        icon: Icons.view_stream,
      ),
      MaterialItem(
        name: 'Крепёж',
        value: '${_result.fasteners} шт',
        subtitle: _fasteningType.name,
        icon: Icons.construction,
      ),
    ];

    if (_useAntiseptic) {
      items.add(MaterialItem(
        name: 'Антисептик',
        value: '${_result.antiseptic.toStringAsFixed(1)} л',
        subtitle: 'Расход 0.2 л/м²',
        icon: Icons.shield_outlined,
      ));
    }

    if (_useFinish) {
      items.add(MaterialItem(
        name: _finishType.name,
        value: '${_result.finish.toStringAsFixed(1)} л',
        subtitle: 'Расход ${_finishType.consumption} л/м²',
        icon: Icons.format_paint,
      ));
    }

    if (_useInsulation) {
      items.add(MaterialItem(
        name: 'Утеплитель',
        value: '${_result.insulation.toStringAsFixed(1)} м²',
        subtitle: 'Минвата ${_insulationThickness.toInt()} мм',
        icon: Icons.waves,
      ));
    }

    if (_useVaporBarrier) {
      items.add(MaterialItem(
        name: 'Пароизоляция',
        value: '${_result.vaporBarrier.toStringAsFixed(1)} м²',
        subtitle: '~${_result.vaporBarrierWeight.toStringAsFixed(1)} кг',
        icon: Icons.shield,
      ));
    }

    return MaterialsCardModern(
      title: 'Необходимые материалы',
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildOptionGrid<T>({
    required List<T> options,
    required double minItemWidth,
    double minItemHeight = 88,
    required Widget Function(T option) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final maxWidth = constraints.maxWidth;
        final targetColumns = math.max(
          1,
          ((maxWidth + spacing) / (minItemWidth + spacing)).floor(),
        ).toInt();
        final columns = math.max(1, math.min(options.length, targetColumns)).toInt();
        final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options
              .map((option) => SizedBox(
                    width: itemWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minItemHeight),
                      child: itemBuilder(option),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildHints() {
    return const HintsList(
      hints: [
        CalculatorHint(
          type: HintType.important,
          messageKey: 'hint.wood.surface_preparation',
        ),
        CalculatorHint(
          type: HintType.tip,
          messageKey: 'hint.wood.batten_installation',
        ),
        CalculatorHint(
          type: HintType.tip,
          messageKey: 'hint.wood.lining_installation',
        ),
        CalculatorHint(
          type: HintType.warning,
          messageKey: 'hint.wood.moisture_control',
        ),
        CalculatorHint(
          type: HintType.tip,
          messageKey: 'hint.wood.finish_application',
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    int? divisions,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(value < 10 ? 1 : 0)} $suffix',
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
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions ?? ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: label,
          value: value,
          suffix: suffix,
          minValue: min,
          maxValue: max,
          decimalPlaces: value < 10 ? 1 : 0,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: CalculatorDesignSystem.cardPadding,
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
