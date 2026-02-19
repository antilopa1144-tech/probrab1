import '../../data/models/price_item.dart';
import '../services/room_area_service.dart';
import 'base_calculator.dart';
import 'calculate_laminate.dart';
import 'calculate_paint_universal.dart';
import 'calculate_plaster.dart';
import 'calculate_putty.dart';
import 'calculate_tile.dart';
import 'calculate_wallpaper.dart';
import 'calculator_usecase.dart';

/// Комплексный калькулятор ремонта комнаты.
///
/// Принимает размеры комнаты и набор типов работ,
/// внутри вызывает соответствующие подкалькуляторы
/// и объединяет их результаты с префиксами.
///
/// ## Флаги работ (0=выключено, 1=включено):
/// - `doPlaster` — штукатурка стен
/// - `doPutty` — шпаклёвка стен
/// - `doPaintWalls` — покраска стен
/// - `doWallpaper` — обои на стены
/// - `doPaintCeiling` — покраска потолка
/// - `doLaminate` — ламинат на пол
/// - `doTile` — плитка на пол
///
/// ## Ключи результатов:
/// Базовые площади: `floorArea`, `wallAreaGross`, `wallAreaNet`, `ceilingArea`, `perimeter`
/// Результаты штукатурки: `walls_plaster_plasterBags`, `walls_plaster_primerLiters`, ...
/// Результаты шпаклёвки: `walls_putty_puttyNeeded`, ...
/// Результаты покраски стен: `walls_paint_paintLiters`, ...
/// Результаты обоев: `walls_wallpaper_rollsNeeded`, ...
/// Результаты покраски потолка: `ceiling_paint_paintLiters`, ...
/// Результаты ламината: `floor_laminate_packsNeeded`, ...
/// Результаты плитки: `floor_tile_tilesNeeded`, ...
class CalculateRoom extends BaseCalculator {
  final _plaster = CalculatePlaster();
  final _putty = CalculatePutty();
  final _paint = CalculatePaintUniversal();
  final _wallpaper = CalculateWallpaper();
  final _laminate = CalculateLaminate();
  final _tile = CalculateTile();
  final _roomService = RoomAreaService();

  @override
  CalculatorResult calculate(Map<String, double> inputs, List<PriceItem> priceList) {
    // --- Размеры комнаты ---
    final length = getInput(inputs, 'length', defaultValue: 5.0, minValue: 1.0, maxValue: 50.0);
    final width = getInput(inputs, 'width', defaultValue: 4.0, minValue: 1.0, maxValue: 50.0);
    final height = getInput(inputs, 'height', defaultValue: 2.7, minValue: 2.0, maxValue: 5.0);
    final doorsCount = getIntInput(inputs, 'doorsCount', defaultValue: 1, minValue: 0, maxValue: 5);
    final windowsCount = getIntInput(inputs, 'windowsCount', defaultValue: 1, minValue: 0, maxValue: 10);

    // --- Флаги работ ---
    final doPlaster = (inputs['doPlaster'] ?? 0) == 1.0;
    final doPutty = (inputs['doPutty'] ?? 0) == 1.0;
    final doPaintWalls = (inputs['doPaintWalls'] ?? 0) == 1.0;
    final doWallpaper = (inputs['doWallpaper'] ?? 0) == 1.0;
    final doPaintCeiling = (inputs['doPaintCeiling'] ?? 0) == 1.0;
    final doLaminate = (inputs['doLaminate'] ?? 0) == 1.0;
    final doTile = (inputs['doTile'] ?? 0) == 1.0;

    // --- Параметры подкалькуляторов ---
    final plasterThickness = getInput(inputs, 'plasterThickness', defaultValue: 10.0, minValue: 5.0, maxValue: 50.0);
    final plasterType = getIntInput(inputs, 'plasterType', defaultValue: 1, minValue: 1, maxValue: 2);
    final puttyQuality = getIntInput(inputs, 'puttyQuality', defaultValue: 2, minValue: 1, maxValue: 3);
    final paintLayers = getIntInput(inputs, 'paintLayers', defaultValue: 2, minValue: 1, maxValue: 4);
    final laminatePackArea = getInput(inputs, 'laminatePackArea', defaultValue: 2.0, minValue: 0.5, maxValue: 3.0);
    final tileSizeRoom = getInput(inputs, 'tileSizeRoom', defaultValue: 60.0, minValue: 10.0, maxValue: 200.0);

    // --- Расчёт площадей ---
    final room = _roomService.calculateRoom(length: length, width: width, height: height);

    // Стандартные размеры проёмов: дверь 0.8×2.0м, окно 1.4×1.3м
    final doorArea = doorsCount * 1.6;   // 0.8 × 2.0
    final windowArea = windowsCount * 1.82; // 1.4 × 1.3
    final openingsArea = doorArea + windowArea;
    final wallAreaNet = (room.totalWallArea - openingsArea).clamp(0.0, room.totalWallArea);

    final values = <String, double>{
      'floorArea': room.floorArea,
      'wallAreaGross': room.totalWallArea,
      'wallAreaNet': wallAreaNet,
      'ceilingArea': room.ceilingArea,
      'perimeter': room.perimeter,
      'openingsArea': openingsArea,
    };

    // --- Стены: Штукатурка ---
    if (doPlaster && wallAreaNet > 0) {
      final result = _plaster.call({
        'area': wallAreaNet,
        'thickness': plasterThickness,
        'type': plasterType.toDouble(),
        'substrateType': 1.0,
        'wallEvenness': 1.0,
      }, priceList);
      _mergeResults(values, result.values, 'walls_plaster');
    }

    // --- Стены: Шпаклёвка ---
    if (doPutty && wallAreaNet > 0) {
      final result = _putty.call({
        'area': wallAreaNet,
        'type': 2.0, // финишная шпаклёвка
        'qualityClass': puttyQuality.toDouble(),
      }, priceList);
      _mergeResults(values, result.values, 'walls_putty');
    }

    // --- Стены: Покраска ---
    if (doPaintWalls && wallAreaNet > 0) {
      final result = _paint.call({
        'paintType': 0.0,    // стены
        'inputMode': 0.0,    // по площади
        'wallArea': wallAreaNet,
        'ceilingArea': 0.0,
        'doorsWindows': 0.0, // проёмы уже вычтены из wallAreaNet
        'layers': paintLayers.toDouble(),
        'surfacePrep': 1.0,
        'colorIntensity': 1.0,
        'consumption': 0.11,
        'reserve': 10.0,
      }, priceList);
      _mergeResults(values, result.values, 'walls_paint');
    }

    // --- Стены: Обои ---
    if (doWallpaper && wallAreaNet > 0) {
      final result = _wallpaper.call({
        'inputMode': 0.0,     // по размерам комнаты
        'length': length,
        'width': width,
        'wallHeight': height,
        'windowsArea': windowArea,
        'doorsArea': doorArea,
        'rollSize': 1.0,  // стандарт 0.53×10м
        'rapport': 0.0,
        'wallpaperType': 1.0,
      }, priceList);
      _mergeResults(values, result.values, 'walls_wallpaper');
    }

    // --- Потолок: Покраска ---
    if (doPaintCeiling && room.ceilingArea > 0) {
      final result = _paint.call({
        'paintType': 1.0,  // потолок
        'inputMode': 0.0,  // по площади
        'wallArea': 0.0,
        'ceilingArea': room.ceilingArea,
        'doorsWindows': 0.0,
        'layers': 2.0,
        'surfacePrep': 1.0,
        'colorIntensity': 1.0,
        'consumption': 0.11,
        'reserve': 10.0,
      }, priceList);
      _mergeResults(values, result.values, 'ceiling_paint');
    }

    // --- Пол: Ламинат ---
    if (doLaminate && room.floorArea > 0) {
      final result = _laminate.call({
        'inputMode': 1.0, // по площади
        'area': room.floorArea,
        'packArea': laminatePackArea,
        'layoutPattern': 2.0,
        'underlayType': 3.0,
        'laminateClass': 32.0,
        'laminateThickness': 8.0,
        'doorThresholds': doorsCount.toDouble(),
      }, priceList);
      _mergeResults(values, result.values, 'floor_laminate');
    }

    // --- Пол: Плитка ---
    if (doTile && room.floorArea > 0) {
      final result = _tile.call({
        'inputMode': 1.0, // по площади
        'area': room.floorArea,
        'tileSize': tileSizeRoom,
        'jointWidth': 3.0,
        'layoutPattern': 1.0,
        'roomComplexity': 1.0,
      }, priceList);
      _mergeResults(values, result.values, 'floor_tile');
    }

    return createResult(values: values, decimals: 2);
  }

  /// Объединяет результаты подкалькулятора в общий словарь с префиксом.
  void _mergeResults(
    Map<String, double> target,
    Map<String, double> source,
    String prefix,
  ) {
    for (final entry in source.entries) {
      target['${prefix}_${entry.key}'] = entry.value;
    }
  }
}
