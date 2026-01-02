import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

enum InputMode { byArea, byDimensions }

enum HeatingSystemType {
  electricMat(
    'Электрический мат',
    'Под плитку, керамогранит',
    'Простой монтаж, быстрый прогрев',
    Icons.grid_on,
  ),
  electricCable(
    'Электрический кабель',
    'Универсальный, для сложных форм',
    'Гибкая укладка, любые конфигурации',
    Icons.cable,
  ),
  infraredFilm(
    'ИК плёночный',
    'Под ламинат, линолеум',
    'Сухой монтаж, быстрая установка',
    Icons.view_module,
  ),
  waterBased(
    'Водяной',
    'Экономичный, для частного дома',
    'Низкие расходы на отопление',
    Icons.waves,
  );

  final String name;
  final String subtitle;
  final String advantage;
  final IconData icon;
  const HeatingSystemType(this.name, this.subtitle, this.advantage, this.icon);
}

enum RoomType {
  bathroom('Ванная / санузел', 180, 'Высокая влажность, комфорт', 150),
  living('Жилая комната', 120, 'Основное или дополнительное отопление', 150),
  kitchen('Кухня', 130, 'Среднее тепловыделение', 150),
  balcony('Балкон / лоджия', 200, 'Большие теплопотери', 100);

  final String name;
  final int powerPerM2; // Вт/м² для электрического
  final String description; // Пояснение для пользователя
  final int pipeStep; // мм шаг укладки для водяного
  const RoomType(this.name, this.powerPerM2, this.description, this.pipeStep);
}

class _HeatingResult {
  final double area;
  final HeatingSystemType systemType;
  final RoomType roomType;
  final double heatingArea; // Фактическая площадь обогрева (70-80% от общей)

  // Общие параметры
  final int totalPower; // Вт
  final bool needsThermostat;
  final bool needsInsulation;

  // Электрический мат/кабель
  final double? matArea; // м²
  final double? cableLength; // м

  // ИК плёнка
  final double? filmArea; // м²
  final int? contactClips;

  // Водяной
  final double? pipeLength; // м
  final int? loopCount; // количество контуров
  final int? collectorOutputs;
  final double? insulationArea; // м²
  final double? screedVolume; // м³

  // Общие материалы
  final double thermostatCount;
  final double sensorCount;
  final double corrugatedTubeLength; // м для датчика

  const _HeatingResult({
    required this.area,
    required this.systemType,
    required this.roomType,
    required this.heatingArea,
    required this.totalPower,
    required this.needsThermostat,
    required this.needsInsulation,
    this.matArea,
    this.cableLength,
    this.filmArea,
    this.contactClips,
    this.pipeLength,
    this.loopCount,
    this.collectorOutputs,
    this.insulationArea,
    this.screedVolume,
    required this.thermostatCount,
    required this.sensorCount,
    required this.corrugatedTubeLength,
  });
}

class _MaterialItem {
  final String name;
  final String value;
  final String? subtitle;
  final IconData icon;

  const _MaterialItem({
    required this.name,
    required this.value,
    this.subtitle,
    required this.icon,
  });
}

class UnderfloorHeatingCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const UnderfloorHeatingCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<UnderfloorHeatingCalculatorScreen> createState() =>
      _UnderfloorHeatingCalculatorScreenState();
}

class _UnderfloorHeatingCalculatorScreenState
    extends State<UnderfloorHeatingCalculatorScreen> {
  InputMode _inputMode = InputMode.byArea;
  double _area = 15.0;
  double _length = 4.0;
  double _width = 3.75;
  HeatingSystemType _systemType = HeatingSystemType.electricMat;
  RoomType _roomType = RoomType.living;
  bool _addInsulation = false;
  double _usefulAreaPercent = 72.0; // Процент полезной площади (50-90%)
  late _HeatingResult _result;
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

  _HeatingResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Площадь обогрева = настраиваемый % от общей (минус мебель, сантехника)
    final heatingArea = calculatedArea * (_usefulAreaPercent / 100);

    // Мощность
    final totalPower = (heatingArea * _roomType.powerPerM2).round();

    // Общие материалы
    const thermostatCount = 1.0;
    const sensorCount = 1.0;
    const corrugatedTubeLength = 2.5; // метров для датчика

    double? matArea;
    double? cableLength;
    double? filmArea;
    int? contactClips;
    double? pipeLength;
    int? loopCount;
    int? collectorOutputs;
    double? insulationArea;
    double? screedVolume;

    switch (_systemType) {
      case HeatingSystemType.electricMat:
        // Нагревательный мат продаётся готовыми комплектами по площади
        matArea = heatingArea;
        break;

      case HeatingSystemType.electricCable:
        // Кабель: длина зависит от мощности кабеля (обычно 17-20 Вт/м)
        const cablePowerPerMeter = 18.0; // Вт/м
        cableLength = totalPower / cablePowerPerMeter;
        break;

      case HeatingSystemType.infraredFilm:
        // ИК плёнка укладывается полосами шириной 0.5 или 1.0 м
        // Используем ширину 0.5м как наиболее распространённую
        filmArea = heatingArea;
        // Рассчитываем количество полос: площадь / ширина полосы / длину комнаты
        // Упрощённо: 1 полоса на каждые 2-3 м² при типичных размерах комнат
        final filmStrips = (filmArea / 2.5).ceil();
        // На каждую полосу: 2 контактных зажима (фаза + ноль на каждый конец)
        contactClips = (filmStrips * 2).toInt();
        break;

      case HeatingSystemType.waterBased:
        // Водяной: расчёт трубы по шагу укладки
        final stepM = _roomType.pipeStep / 1000; // мм в метры
        final pipePerM2 = 1 / stepM; // метров трубы на м²
        pipeLength = heatingArea * pipePerM2 * 1.15; // +15% на подводку

        // Количество контуров (макс 100-120м на контур)
        loopCount = (pipeLength / 100).ceil();
        collectorOutputs = loopCount;

        // Теплоизоляция обязательна для водяного
        insulationArea = calculatedArea;

        // Стяжка: 30мм над трубой (мин. по СП) + 16мм труба + 30мм под трубой = 76мм
        // Рекомендуемая толщина 75-80мм для надёжного распределения тепла
        screedVolume = calculatedArea * 0.08;
        break;
    }

    // Теплоизоляция (опционально для электрических, обязательна для водяного)
    if (_addInsulation && _systemType != HeatingSystemType.waterBased) {
      insulationArea = calculatedArea;
    }

    return _HeatingResult(
      area: calculatedArea,
      systemType: _systemType,
      roomType: _roomType,
      heatingArea: heatingArea,
      totalPower: totalPower,
      needsThermostat: true,
      needsInsulation: _addInsulation || _systemType == HeatingSystemType.waterBased,
      matArea: matArea,
      cableLength: cableLength,
      filmArea: filmArea,
      contactClips: contactClips,
      pipeLength: pipeLength,
      loopCount: loopCount,
      collectorOutputs: collectorOutputs,
      insulationArea: insulationArea,
      screedVolume: screedVolume,
      thermostatCount: thermostatCount,
      sensorCount: sensorCount,
      corrugatedTubeLength: corrugatedTubeLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 РАСЧЁТ ТЁПЛОГО ПОЛА');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('Площадь помещения: ${_result.area.toStringAsFixed(1)} м²');
    buffer.writeln('Площадь обогрева: ${_result.heatingArea.toStringAsFixed(1)} м²');
    buffer.writeln('Тип системы: ${_result.systemType.name}');
    buffer.writeln('Помещение: ${_result.roomType.name}');
    buffer.writeln('Мощность: ${_result.totalPower} Вт');
    buffer.writeln();

    buffer.writeln('📦 МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        buffer.writeln('• Нагревательный мат: ${_result.matArea!.toStringAsFixed(1)} м² (${_result.totalPower} Вт)');
        break;
      case HeatingSystemType.electricCable:
        buffer.writeln('• Нагревательный кабель: ${_result.cableLength!.toStringAsFixed(1)} м (${_result.totalPower} Вт)');
        buffer.writeln('• Монтажная лента: ${(_result.heatingArea * 2).toStringAsFixed(0)} м');
        break;
      case HeatingSystemType.infraredFilm:
        buffer.writeln('• ИК плёнка: ${_result.filmArea!.toStringAsFixed(1)} м²');
        buffer.writeln('• Контактные зажимы: ${_result.contactClips} шт');
        buffer.writeln('• Изоляция контактов: ${_result.contactClips} шт');
        buffer.writeln('• Теплоотражающая подложка: ${_result.area.toStringAsFixed(1)} м²');
        break;
      case HeatingSystemType.waterBased:
        buffer.writeln('• Труба PE-RT 16мм: ${_result.pipeLength!.toStringAsFixed(0)} м');
        buffer.writeln('• Коллектор: ${_result.collectorOutputs} выходов');
        buffer.writeln('• Контуров: ${_result.loopCount}');
        buffer.writeln('• Теплоизоляция ПСБ-35 (50мм): ${_result.insulationArea!.toStringAsFixed(1)} м²');
        buffer.writeln('• Демпферная лента: ${(_result.area * 0.4).toStringAsFixed(0)} м');
        buffer.writeln('• Крепёж (скобы): ${(_result.heatingArea * 10).toStringAsFixed(0)} шт');
        buffer.writeln('• Стяжка: ${_result.screedVolume!.toStringAsFixed(2)} м³');
        break;
    }

    buffer.writeln('• Терморегулятор: ${_result.thermostatCount.toStringAsFixed(0)} шт');
    buffer.writeln('• Датчик температуры: ${_result.sensorCount.toStringAsFixed(0)} шт');
    buffer.writeln('• Гофротруба для датчика: ${_result.corrugatedTubeLength.toStringAsFixed(1)} м');

    if (_result.insulationArea != null && _result.systemType != HeatingSystemType.waterBased) {
      buffer.writeln('• Теплоизоляция: ${_result.insulationArea!.toStringAsFixed(1)} м²');
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln('Создано с помощью Калькулятора Стройматериалов');

    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(
      ShareParams(text: text, subject: 'Расчёт тёплого пола'),
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
    const accentColor = CalculatorColors.engineering;

    return CalculatorScaffold(
      title: 'Тёплый пол',
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
            label: 'ПЛОЩАДЬ',
            value: '${_result.heatingArea.toStringAsFixed(0)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'МОЩНОСТЬ',
            value: '${(_result.totalPower / 1000).toStringAsFixed(1)} кВт',
            icon: Icons.bolt,
          ),
          ResultItem(
            label: _result.systemType == HeatingSystemType.waterBased ? 'ТРУБА' : 'СИСТЕМА',
            value: _result.systemType == HeatingSystemType.waterBased
                ? '${_result.pipeLength!.toStringAsFixed(0)} м'
                : _result.systemType == HeatingSystemType.electricMat
                    ? '${_result.matArea!.toStringAsFixed(1)} м²'
                    : _result.systemType == HeatingSystemType.electricCable
                        ? '${_result.cableLength!.toStringAsFixed(0)} м'
                        : '${_result.filmArea!.toStringAsFixed(1)} м²',
            icon: Icons.thermostat,
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
        _buildSystemTypeSelector(),
        const SizedBox(height: 16),
        _buildRoomTypeSelector(),
        const SizedBox(height: 16),
        _buildUsefulAreaSlider(),
        const SizedBox(height: 16),
        if (_systemType != HeatingSystemType.waterBased) _buildInsulationToggle(),
        if (_systemType != HeatingSystemType.waterBased) const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildAdditionalInfoCard(),
        const SizedBox(height: 24),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Режим ввода',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
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
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Площадь помещения',
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          Slider(
            value: _area,
            min: 1,
            max: 100,
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
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Размеры помещения',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Длина',
            value: _length,
            min: 0.5,
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
            label: 'Ширина',
            value: _width,
            min: 0.5,
            max: 20.0,
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
              children: [
                Expanded(
                  child: Text(
                    'Площадь помещения',
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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

  Widget _buildSystemTypeSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип системы',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...HeatingSystemType.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _systemType == type;

            return Padding(
              padding: EdgeInsets.only(bottom: index < HeatingSystemType.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _systemType = type;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : CalculatorColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? accentColor : CalculatorColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.subtitle,
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Text(
                                '✓ ${type.advantage}',
                                style: CalculatorDesignSystem.bodySmall.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип помещения',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Автоматически определяет требуемую мощность',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...RoomType.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _roomType == type;

            return Padding(
              padding: EdgeInsets.only(bottom: index < RoomType.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _roomType = type;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${type.description} • ${type.powerPerM2} Вт/м²',
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUsefulAreaSlider() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Площадь обогрева',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_usefulAreaPercent.round()}%',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Процент площади без мебели и техники',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: _usefulAreaPercent,
              min: 50,
              max: 90,
              divisions: 8,
              onChanged: (value) {
                setState(() {
                  _usefulAreaPercent = value;
                  _update();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '50% (много мебели)',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '90% (мало мебели)',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsulationToggle() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Теплоизоляция',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Для 1 этажа, над подвалом',
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _addInsulation,
            onChanged: (value) {
              setState(() {
                _addInsulation = value;
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
    const accentColor = CalculatorColors.engineering;

    final materials = <_MaterialItem>[];

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        materials.add(_MaterialItem(
          name: 'Нагревательный мат',
          value: '${_result.matArea!.toStringAsFixed(1)} м²',
          subtitle: '${_result.totalPower} Вт',
          icon: Icons.grid_on,
        ));
        break;

      case HeatingSystemType.electricCable:
        materials.addAll([
          _MaterialItem(
            name: 'Нагревательный кабель',
            value: '${_result.cableLength!.toStringAsFixed(0)} м',
            subtitle: '${_result.totalPower} Вт',
            icon: Icons.cable,
          ),
          _MaterialItem(
            name: 'Монтажная лента',
            value: '${(_result.heatingArea * 2).toStringAsFixed(0)} м',
            icon: Icons.straighten,
          ),
        ]);
        break;

      case HeatingSystemType.infraredFilm:
        materials.addAll([
          _MaterialItem(
            name: 'ИК плёнка',
            value: '${_result.filmArea!.toStringAsFixed(1)} м²',
            icon: Icons.view_module,
          ),
          _MaterialItem(
            name: 'Контактные зажимы',
            value: '${_result.contactClips} шт',
            icon: Icons.link,
          ),
          _MaterialItem(
            name: 'Изоляция контактов',
            value: '${_result.contactClips} шт',
            icon: Icons.bolt,
          ),
          _MaterialItem(
            name: 'Теплоотражающая подложка',
            value: '${_result.area.toStringAsFixed(1)} м²',
            icon: Icons.layers,
          ),
        ]);
        break;

      case HeatingSystemType.waterBased:
        materials.addAll([
          _MaterialItem(
            name: 'Труба PE-RT 16мм',
            value: '${_result.pipeLength!.toStringAsFixed(0)} м',
            icon: Icons.timeline,
          ),
          _MaterialItem(
            name: 'Коллектор',
            value: '${_result.collectorOutputs} вых.',
            icon: Icons.device_hub,
          ),
          _MaterialItem(
            name: 'Контуров',
            value: '${_result.loopCount} шт',
            icon: Icons.loop,
          ),
          _MaterialItem(
            name: 'Теплоизоляция ПСБ-35',
            value: '${_result.insulationArea!.toStringAsFixed(1)} м²',
            subtitle: '50 мм',
            icon: Icons.layers,
          ),
          _MaterialItem(
            name: 'Демпферная лента',
            value: '${(_result.area * 0.4).toStringAsFixed(0)} м',
            icon: Icons.straighten,
          ),
          _MaterialItem(
            name: 'Крепёж (скобы)',
            value: '${(_result.heatingArea * 10).toStringAsFixed(0)} шт',
            icon: Icons.push_pin,
          ),
          _MaterialItem(
            name: 'Стяжка',
            value: '${_result.screedVolume!.toStringAsFixed(2)} м³',
            icon: Icons.foundation,
          ),
        ]);
        break;
    }

    // Общие материалы
    materials.addAll([
      _MaterialItem(
        name: 'Терморегулятор',
        value: '${_result.thermostatCount.toStringAsFixed(0)} шт',
        icon: Icons.thermostat,
      ),
      _MaterialItem(
        name: 'Датчик температуры',
        value: '${_result.sensorCount.toStringAsFixed(0)} шт',
        icon: Icons.sensors,
      ),
      _MaterialItem(
        name: 'Гофротруба',
        value: '${_result.corrugatedTubeLength.toStringAsFixed(1)} м',
        subtitle: 'для датчика',
        icon: Icons.sensor_door,
      ),
    ]);

    if (_result.insulationArea != null && _result.systemType != HeatingSystemType.waterBased) {
      materials.add(_MaterialItem(
        name: 'Теплоизоляция',
        value: '${_result.insulationArea!.toStringAsFixed(1)} м²',
        icon: Icons.layers,
      ));
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(Icons.construction, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Материалы',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Список материалов
          ...materials.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == materials.length - 1;
            return _buildMaterialRow(item, accentColor, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(_MaterialItem item, Color accentColor, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Название и подзаголовок
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: CalculatorDesignSystem.bodySmall.copyWith(
                          color: CalculatorColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Значение
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.value,
                  style: CalculatorDesignSystem.titleSmall.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: CalculatorColors.textSecondary.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    const accentColor = CalculatorColors.engineering;

    // Примерное энергопотребление (8 часов в день, 120 дней в сезон)
    final monthlyConsumption = (_result.totalPower / 1000) * 8 * 30; // кВт⋅ч
    final seasonConsumption = monthlyConsumption * 4; // 4 месяца

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Дополнительная информация',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.bolt,
            label: 'Мощность системы',
            value: '${(_result.totalPower / 1000).toStringAsFixed(2)} кВт',
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.heat_pump,
            label: 'Площадь обогрева',
            value: '${_result.heatingArea.toStringAsFixed(1)} м²',
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              '${_usefulAreaPercent.round()}% от общей площади (без мебели и сантехники)',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_month,
            label: 'Расход в месяц',
            value: '~${monthlyConsumption.toStringAsFixed(0)} кВт⋅ч',
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Расход за сезон',
            value: '~${seasonConsumption.toStringAsFixed(0)} кВт⋅ч',
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'При работе 8 часов в день, 4 месяца',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: CalculatorDesignSystem.bodyMedium.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final hints = <CalculatorHint>[];

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        hints.addAll([
          const CalculatorHint(
            type: HintType.important,
            message: 'Поверхность пола должна быть ровной. Перепад высоты не более 5мм на 2м.',
          ),
          const CalculatorHint(
            type: HintType.tip,
            message: 'Используйте программируемый терморегулятор для экономии до 30% электроэнергии.',
          ),
          const CalculatorHint(
            type: HintType.tip,
            message: 'Проверьте сопротивление кабеля до и после укладки — оно должно соответствовать паспорту.',
          ),
        ]);
        break;
      case HeatingSystemType.electricCable:
        hints.addAll([
          const CalculatorHint(
            type: HintType.important,
            message: 'Шаг укладки кабеля должен быть 10-15 см. Не допускайте пересечения витков.',
          ),
          const CalculatorHint(
            type: HintType.tip,
            message: 'Используйте монтажную ленту для фиксации кабеля с равномерным шагом.',
          ),
          const CalculatorHint(
            type: HintType.warning,
            message: 'Кабель нельзя резать и укорачивать! Выбирайте секцию под вашу площадь.',
          ),
        ]);
        break;
      case HeatingSystemType.infraredFilm:
        hints.addAll([
          const CalculatorHint(
            type: HintType.important,
            message: 'Под ИК плёнку обязательна теплоотражающая подложка (не фольга!).',
          ),
          const CalculatorHint(
            type: HintType.tip,
            message: 'Полосы плёнки подключайте параллельно для равномерного нагрева.',
          ),
          const CalculatorHint(
            type: HintType.warning,
            message: 'Тщательно изолируйте все контакты битумной лентой с двух сторон.',
          ),
        ]);
        break;
      case HeatingSystemType.waterBased:
        hints.addAll([
          const CalculatorHint(
            type: HintType.important,
            message: 'Перед заливкой стяжки обязательно проведите опрессовку системы (6 бар, 24 часа).',
          ),
          const CalculatorHint(
            type: HintType.tip,
            message: 'Используйте трубу с кислородным барьером (PE-RT или PEX-a) для долговечности.',
          ),
          const CalculatorHint(
            type: HintType.tip,
            message: 'Стяжка должна сохнуть минимум 28 дней. Включать систему можно только после полного высыхания.',
          ),
        ]);
        break;
    }

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
