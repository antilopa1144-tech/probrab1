import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';
import 'blind_area_canonical_adapter.dart';

/// Калькулятор отмостки V2.
///
/// Входные параметры:
/// - houseLength: длина дома (м), 3-30, по умолчанию 10
/// - houseWidth: ширина дома (м), 3-20, по умолчанию 8
/// - blindAreaWidth: ширина отмостки (м), 0.6-2.0, по умолчанию 1.0
/// - thickness: толщина (м), 0.05-0.20, по умолчанию 0.1
/// - blindAreaType: тип отмостки (0=бетон, 1=плитка, 2=мягкая), по умолчанию 0
/// - needInsulation: утепление (0=нет, 1=да), по умолчанию 0
/// - needDrainage: дренаж (0=нет, 1=да), по умолчанию 1
///
/// Выходные значения:
/// - totalArea: общая площадь отмостки (м²)
/// - perimeter: периметр дома (м)
/// - concreteVolume: объём бетона (м³, только для бетонной)
/// - sandVolume: объём песка (м³)
/// - gravelVolume: объём щебня (м³)
/// - membranArea: площадь мембраны (м²)
/// - insulationArea: площадь утеплителя (м², если включено)
/// - drainageLength: длина дренажа (м, если включено)
/// - pavingArea: площадь плитки (м², только для плиточной)
class CalculateBlindAreaV2 extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final houseLength = getInput(
      inputs,
      'houseLength',
      defaultValue: 10.0,
      minValue: 3.0,
      maxValue: 50.0,
    );
    final houseWidth = getInput(
      inputs,
      'houseWidth',
      defaultValue: 8.0,
      minValue: 3.0,
      maxValue: 30.0,
    );
    final blindAreaWidth = getInput(
      inputs,
      'blindAreaWidth',
      defaultValue: 1.0,
      minValue: 0.6,
      maxValue: 2.0,
    );
    final thickness = getInput(
      inputs,
      'thickness',
      defaultValue: 0.1,
      minValue: 0.05,
      maxValue: 0.20,
    );
    final blindAreaType = getIntInput(
      inputs,
      'blindAreaType',
      defaultValue: 0,
      minValue: 0,
      maxValue: 2,
    );
    final needInsulation = getIntInput(
      inputs,
      'needInsulation',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final needDrainage = getIntInput(
      inputs,
      'needDrainage',
      defaultValue: 1,
      minValue: 0,
      maxValue: 1,
    );

    // Периметр дома
    final perimeter = 2 * (houseLength + houseWidth);

    // Единый canonical-расчёт с web. Экран использует рекомендованное
    // количество к покупке, а чистая геометрия остаётся в totalArea.
    final canonical = calculateCanonicalBlindArea({
      'perimeter': perimeter,
      'width': blindAreaWidth,
      'thickness': thickness * 1000,
      'materialType': blindAreaType.toDouble(),
      'withInsulation': needInsulation == 1 ? 50 : 0,
      'accuracyMode': 1,
    });
    final totals = canonical.totals;
    final totalArea = totals['area'] ?? 0;
    final recommendedPurchase = totals['recPurchase'] ?? 0;
    final concreteVolume = blindAreaType == 0 ? recommendedPurchase : 0.0;
    final pavingArea = blindAreaType == 1 ? recommendedPurchase : 0.0;
    final sandVolume = totals['sand'] ?? 0;
    final gravelVolume = totals['gravel'] ?? 0;
    final membranArea = blindAreaType == 2 ? recommendedPurchase : 0.0;
    final insulationArea = needInsulation == 1
        ? (totals['eppsPlates'] ?? 0) * 0.72
        : 0.0;

    // Дренаж
    final drainageLength = needDrainage == 1 ? perimeter : 0.0;

    // Расчёт стоимости
    double? totalPrice;

    final concretePrice = findPrice(priceList, ['concrete', 'concrete_m300']);
    final pavingPrice = findPrice(priceList, ['paving_tile', 'tile']);
    final sandPrice = findPrice(priceList, ['sand']);
    final gravelPrice = findPrice(priceList, ['gravel', 'crushed_stone']);
    final membranePrice = findPrice(priceList, ['membrane', 'geomembrane']);
    final insulationPrice = findPrice(priceList, ['insulation_eps', 'xps']);
    final drainagePrice = findPrice(priceList, ['drainage_pipe', 'drainage']);

    // Основной материал
    if (blindAreaType == 0 && concretePrice != null) {
      totalPrice = (totalPrice ?? 0) + concreteVolume * concretePrice.price;
    } else if (blindAreaType == 1 && pavingPrice != null) {
      totalPrice = (totalPrice ?? 0) + pavingArea * pavingPrice.price;
    }

    // Подушки
    if (sandPrice != null) {
      totalPrice = (totalPrice ?? 0) + sandVolume * sandPrice.price;
    }
    if (gravelPrice != null) {
      totalPrice = (totalPrice ?? 0) + gravelVolume * gravelPrice.price;
    }

    // Мембрана
    if (membranePrice != null) {
      totalPrice = (totalPrice ?? 0) + membranArea * membranePrice.price;
    }

    // Утепление
    if (needInsulation == 1 && insulationPrice != null) {
      totalPrice = (totalPrice ?? 0) + insulationArea * insulationPrice.price;
    }

    // Дренаж
    if (needDrainage == 1 && drainagePrice != null) {
      totalPrice = (totalPrice ?? 0) + drainageLength * drainagePrice.price;
    }

    return createResult(
      values: {
        'houseLength': houseLength,
        'houseWidth': houseWidth,
        'blindAreaWidth': blindAreaWidth,
        'thickness': thickness,
        'blindAreaType': blindAreaType.toDouble(),
        'needInsulation': needInsulation.toDouble(),
        'needDrainage': needDrainage.toDouble(),
        'perimeter': perimeter,
        'totalArea': totalArea,
        'concreteVolume': concreteVolume,
        'pavingArea': pavingArea,
        'sandVolume': sandVolume,
        'gravelVolume': gravelVolume,
        'membranArea': membranArea,
        'insulationArea': insulationArea,
        'drainageLength': drainageLength,
      },
      totalPrice: totalPrice,
    );
  }
}
