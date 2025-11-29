import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Калькулятор мансарды.
///
/// Нормативы:
/// - СНиП 2.01.07-85 "Нагрузки и воздействия"
/// - СП 50.13330.2012 "Тепловая защита зданий"
///
/// Поля:
/// - area: площадь мансарды (м²)
/// - roofArea: площадь кровли (м²)
/// - wallArea: площадь стен (м²)
/// - floorArea: площадь пола (м²)
/// - windows: количество окон (шт)
/// - insulation: утепление кровли (0 - нет, 1 - да)
/// - wallFinish: отделка стен (1 - вагонка, 2 - гипсокартон, 3 - панели)
/// - floorType: тип пола (1 - ламинат, 2 - паркет, 3 - линолеум)
class CalculateAttic implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0;
    final roofArea = inputs['roofArea'] ?? 0.0;
    final wallArea = inputs['wallArea'] ?? 0.0;
    final floorArea = inputs['floorArea'] ?? area;
    final windows = (inputs['windows'] ?? 0.0).round();
    final insulation = (inputs['insulation'] ?? 1.0).round();
    final wallFinish = (inputs['wallFinish'] ?? 1.0).round();
    final floorType = (inputs['floorType'] ?? 1.0).round();

    // Утепление кровли
    final insulationArea = insulation == 1 ? roofArea * 1.1 : 0.0; // +10% нахлёст
    final insulationVolume = insulation == 1 ? roofArea * 0.15 : 0.0; // 15 см утеплителя
    final vaporBarrierArea = insulation == 1 ? roofArea * 1.1 : 0.0;

    // Отделка стен
    double woodArea = 0.0;
    double gklSheets = 0.0;
    double panelsNeeded = 0.0;
    
    if (wallFinish == 1) {
      // Вагонка
      final boardArea = 0.1; // м² на доску
      woodArea = (wallArea / boardArea * 1.1).ceil().toDouble();
    } else if (wallFinish == 2) {
      // Гипсокартон
      final sheetArea = 3.0; // м² на лист ГКЛ
      gklSheets = (wallArea / sheetArea * 1.1).ceil().toDouble();
    } else if (wallFinish == 3) {
      // Панели ПВХ
      final panelArea = 0.25; // м² на панель
      panelsNeeded = (wallArea / panelArea * 1.1).ceil().toDouble();
    }

    // Пол
    double laminatePacks = 0.0;
    double parquetPlanks = 0.0;
    double linoleumRolls = 0.0;
    
    if (floorType == 1) {
      // Ламинат
      final packArea = 2.0; // м² в упаковке
      laminatePacks = (floorArea / packArea * 1.05).ceil().toDouble();
    } else if (floorType == 2) {
      // Паркет
      final plankArea = 0.28; // м² на планку
      parquetPlanks = (floorArea / plankArea * 1.1).ceil().toDouble();
    } else if (floorType == 3) {
      // Линолеум
      final rollArea = 30.0; // м² в рулоне
      linoleumRolls = (floorArea / rollArea * 1.1).ceil().toDouble();
    }

    // Окна мансардные
    final windowArea = windows * 1.5; // средняя площадь окна 1.5 м²

    // Освещение (примерно 1 светильник на 5 м²)
    final fixturesNeeded = (area / 5.0).ceil();

    // Цены
    final insulationPrice = _findPrice(
      priceList,
      ['insulation_mineral', 'mineral_wool', 'insulation'],
    )?.price;

    final vaporBarrierPrice = _findPrice(
      priceList,
      ['vapor_barrier', 'vapor_membrane'],
    )?.price;

    final woodPrice = _findPrice(
      priceList,
      ['wood', 'clapboard', 'timber'],
    )?.price;

    final gklPrice = _findPrice(
      priceList,
      ['gkl', 'drywall', 'gypsum_board'],
    )?.price;

    final panelPrice = _findPrice(
      priceList,
      ['pvc_panel', 'panel'],
    )?.price;

    final laminatePrice = _findPrice(
      priceList,
      ['laminate', 'laminate_pack'],
    )?.price;

    final parquetPrice = _findPrice(
      priceList,
      ['parquet', 'wood_floor'],
    )?.price;

    final linoleumPrice = _findPrice(
      priceList,
      ['linoleum', 'flooring'],
    )?.price;

    final windowPrice = _findPrice(
      priceList,
      ['attic_window', 'roof_window', 'window'],
    )?.price;

    double? totalPrice;

    // Утепление
    if (insulationPrice != null && insulationArea > 0) {
      totalPrice = insulationArea * insulationPrice;
    }

    // Пароизоляция
    if (vaporBarrierPrice != null && vaporBarrierArea > 0) {
      totalPrice = (totalPrice ?? 0) + vaporBarrierArea * vaporBarrierPrice;
    }

    // Стены
    if (wallFinish == 1 && woodPrice != null) {
      totalPrice = (totalPrice ?? 0) + woodArea * woodPrice;
    } else if (wallFinish == 2 && gklPrice != null) {
      totalPrice = (totalPrice ?? 0) + gklSheets * gklPrice;
    } else if (wallFinish == 3 && panelPrice != null) {
      totalPrice = (totalPrice ?? 0) + panelsNeeded * panelPrice;
    }

    // Пол
    if (floorType == 1 && laminatePrice != null) {
      totalPrice = (totalPrice ?? 0) + laminatePacks * laminatePrice;
    } else if (floorType == 2 && parquetPrice != null) {
      totalPrice = (totalPrice ?? 0) + parquetPlanks * parquetPrice;
    } else if (floorType == 3 && linoleumPrice != null) {
      totalPrice = (totalPrice ?? 0) + linoleumRolls * linoleumPrice;
    }

    // Окна
    if (windowPrice != null && windows > 0) {
      totalPrice = (totalPrice ?? 0) + windows * windowPrice;
    }

    return CalculatorResult(
      values: {
        'area': area,
        'roofArea': roofArea,
        'wallArea': wallArea,
        'floorArea': floorArea,
        'insulationArea': insulationArea,
        'insulationVolume': insulationVolume,
        'vaporBarrierArea': vaporBarrierArea,
        'woodArea': woodArea,
        'gklSheets': gklSheets,
        'panelsNeeded': panelsNeeded,
        'laminatePacks': laminatePacks,
        'parquetPlanks': parquetPlanks,
        'linoleumRolls': linoleumRolls,
        'windows': windows.toDouble(),
        'windowArea': windowArea,
        'fixturesNeeded': fixturesNeeded.toDouble(),
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
