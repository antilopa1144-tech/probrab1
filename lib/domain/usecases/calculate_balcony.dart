import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор балкона/лоджии.
///
/// Нормативы:
/// - СНиП 2.01.07-85 "Нагрузки и воздействия"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь балкона/лоджии (м²)
/// - perimeter: периметр (м)
/// - height: высота ограждения (м), по умолчанию 1.1
/// - glazing: остекление (0 - нет, 1 - холодное, 2 - тёплое)
/// - insulation: утепление (0 - нет, 1 - да)
/// - floorType: тип пола (1 - плитка, 2 - наливной, 3 - дерево)
/// - wallFinish: отделка стен (1 - покраска, 2 - панели, 3 - плитка)
class CalculateBalcony implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final perimeter = inputs['perimeter'] ?? 0.0;
    final height = inputs['height'] ?? 1.1; // м
    final glazing = (inputs['glazing'] ?? 0.0).round();
    final insulation = (inputs['insulation'] ?? 0.0).round();
    final floorType = (inputs['floorType'] ?? 1.0).round();
    final wallFinish = (inputs['wallFinish'] ?? 1.0).round();

    // Площадь пола
    final floorArea = area;

    // Площадь стен (если периметр указан)
    final wallArea = perimeter > 0 ? perimeter * height : 0.0;

    // Площадь потолка
    final ceilingArea = area;

    // Остекление
    double glazingArea = 0.0;
    double glazingLength = 0.0;
    if (glazing > 0) {
      // Площадь остекления (примерно 70% от площади стен)
      glazingArea = wallArea * 0.7;
      // Длина остекления (периметр балкона)
      glazingLength = perimeter;
    }

    // Утепление
    final insulationArea = insulation == 1
        ? (wallArea + ceilingArea) * 1.1 // +10% на нахлёст
        : 0.0;
    final insulationVolume = insulation == 1
        ? (wallArea + ceilingArea) * 0.05 // 5 см утеплителя
        : 0.0;

    // Пароизоляция (если утепление)
    final vaporBarrierArea = insulation == 1 ? (wallArea + ceilingArea) * 1.1 : 0.0;

    // Пол
    double tilesNeeded = 0.0;
    double selfLevelingMix = 0.0;
    double woodArea = 0.0;
    
    if (floorType == 1) {
      // Плитка
      final tileArea = 0.09; // 30x30 см
      tilesNeeded = (floorArea / tileArea * 1.1).ceil().toDouble();
    } else if (floorType == 2) {
      // Наливной пол
      selfLevelingMix = floorArea * 1.5 * 0.005; // 5 мм, расход 1.5 кг/м²·мм
    } else if (floorType == 3) {
      // Дерево (террасная доска)
      woodArea = floorArea * 1.1; // +10% запас
    }

    // Отделка стен
    double paintNeeded = 0.0;
    double panelsNeeded = 0.0;
    double wallTilesNeeded = 0.0;
    
    if (wallFinish == 1) {
      // Покраска
      paintNeeded = wallArea * 0.15 * 2; // 2 слоя, расход 0.15 кг/м²
    } else if (wallFinish == 2) {
      // Панели ПВХ
      final panelArea = 0.25; // м² на панель
      panelsNeeded = (wallArea / panelArea * 1.1).ceil().toDouble();
    } else if (wallFinish == 3) {
      // Плитка
      final tileArea = 0.09; // 30x30 см
      wallTilesNeeded = (wallArea / tileArea * 1.1).ceil().toDouble();
    }

    // Потолок (обычно покраска или панели)
    final ceilingPaintNeeded = ceilingArea * 0.12 * 2; // 2 слоя

    // Ограждение (если не остеклено)
    double railingLength = 0.0;
    if (glazing == 0 && perimeter > 0) {
      railingLength = perimeter;
    }

    // Цены
    final glazingPrice = _findPrice(
      priceList,
      glazing == 2
          ? ['glazing_warm', 'windows_warm', 'glazing']
          : ['glazing_cold', 'windows_cold', 'glazing'],
    )?.price;

    final insulationPrice = _findPrice(
      priceList,
      ['insulation_eps', 'eps', 'xps', 'insulation'],
    )?.price;

    final vaporBarrierPrice = _findPrice(
      priceList,
      ['vapor_barrier', 'vapor_membrane'],
    )?.price;

    final tilePrice = _findPrice(
      priceList,
      ['tile', 'tile_ceramic', 'tile_porcelain'],
    )?.price;

    final selfLevelingPrice = _findPrice(
      priceList,
      ['self_leveling', 'leveling_compound'],
    )?.price;

    final woodPrice = _findPrice(
      priceList,
      ['decking', 'terrace_board', 'wood'],
    )?.price;

    final paintPrice = _findPrice(
      priceList,
      ['paint', 'paint_wall'],
    )?.price;

    final panelPrice = _findPrice(
      priceList,
      ['pvc_panel', 'panel'],
    )?.price;

    final railingPrice = _findPrice(
      priceList,
      ['railing', 'balcony_railing'],
    )?.price;

    double? totalPrice;

    // Остекление
    if (glazingPrice != null && glazingArea > 0) {
      totalPrice = glazingArea * glazingPrice;
    }

    // Утепление
    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice;
    }

    // Пароизоляция
    if (vaporBarrierPrice != null && vaporBarrierArea > 0) {
      totalPrice = (totalPrice ?? 0) + vaporBarrierArea * vaporBarrierPrice;
    }

    // Пол
    if (floorType == 1 && tilePrice != null) {
      totalPrice = (totalPrice ?? 0) + tilesNeeded * tilePrice;
    } else if (floorType == 2 && selfLevelingPrice != null) {
      totalPrice = (totalPrice ?? 0) + selfLevelingMix * selfLevelingPrice;
    } else if (floorType == 3 && woodPrice != null) {
      totalPrice = (totalPrice ?? 0) + woodArea * woodPrice;
    }

    // Стены
    if (wallFinish == 1 && paintPrice != null) {
      totalPrice = (totalPrice ?? 0) + paintNeeded * paintPrice;
    } else if (wallFinish == 2 && panelPrice != null) {
      totalPrice = (totalPrice ?? 0) + panelsNeeded * panelPrice;
    } else if (wallFinish == 3 && tilePrice != null) {
      totalPrice = (totalPrice ?? 0) + wallTilesNeeded * tilePrice;
    }

    // Потолок
    if (paintPrice != null) {
      totalPrice = (totalPrice ?? 0) + ceilingPaintNeeded * paintPrice;
    }

    // Ограждение
    if (railingPrice != null && railingLength > 0) {
      totalPrice = (totalPrice ?? 0) + railingLength * railingPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'floorArea': floorArea,
        'wallArea': wallArea,
        'ceilingArea': ceilingArea,
        'glazingArea': glazingArea,
        'glazingLength': glazingLength,
        'insulationArea': insulationArea,
        'insulationVolume': insulationVolume,
        'vaporBarrierArea': vaporBarrierArea,
        'tilesNeeded': tilesNeeded,
        'selfLevelingMix': selfLevelingMix,
        'woodArea': woodArea,
        'paintNeeded': paintNeeded,
        'panelsNeeded': panelsNeeded,
        'wallTilesNeeded': wallTilesNeeded,
        'ceilingPaintNeeded': ceilingPaintNeeded,
        'railingLength': railingLength,
      },
      totalPrice: totalPrice,
    );
  }

  PriceItem? _findPrice(List<PriceItem> priceList, List<String> skus) {
    for (final sku in skus) {
      try {
        return priceList.firstWhere((item) => item.sku == sku);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
