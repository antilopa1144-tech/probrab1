import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор стяжки пола.
///
/// Рассчитывает количество цемента, песка, армирующей сетки и плёнки.
///
/// Поля:
/// - area: площадь пола (м²)
/// - thickness: толщина стяжки (мм)
/// - screedType: тип стяжки (0=цементно-песчаная, 1=полусухая, 2=бетонная)
/// - needMesh: нужна ли армирующая сетка (0/1)
/// - needFilm: нужна ли плёнка (0/1)
/// - roomWidth: ширина комнаты (м), опционально
/// - roomLength: длина комнаты (м), опционально
class CalculateScreedV2 extends BaseCalculator {
  /// Расход цемента по типу стяжки (кг/м³)
  static const Map<int, double> cementPerCbm = {
    0: 400.0, // Цементно-песчаная М150
    1: 350.0, // Полусухая
    2: 300.0, // Бетон М200
  };

  /// Расход песка по типу стяжки (кг/м³)
  static const Map<int, double> sandPerCbm = {
    0: 1200.0, // Цементно-песчаная (1:3)
    1: 1050.0, // Полусухая
    2: 900.0,  // Бетон
  };

  /// Вес мешка цемента (кг)
  static const double cementBagWeight = 50.0;

  /// Плотность песка (кг/м³)
  static const double sandDensity = 1500.0;

  /// Запас сетки (%)
  static const double meshMargin = 10.0;

  /// Запас плёнки (%)
  static const double filmMargin = 15.0;

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];

    if (area <= 0 && (roomWidth == null || roomLength == null)) {
      return 'Необходимо указать площадь или размеры комнаты';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final screedType = getIntInput(inputs, 'screedType', defaultValue: 0, minValue: 0, maxValue: 2);
    final thickness = getInput(inputs, 'thickness', defaultValue: 50.0, minValue: 30.0, maxValue: 150.0);
    final needMesh = getIntInput(inputs, 'needMesh', defaultValue: 1, minValue: 0, maxValue: 1) == 1;
    final needFilm = getIntInput(inputs, 'needFilm', defaultValue: 1, minValue: 0, maxValue: 1) == 1;

    // Площадь
    double area;
    final inputArea = getInput(inputs, 'area', defaultValue: 0);
    if (inputArea > 0) {
      area = inputArea;
    } else {
      final roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 30);
      final roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 30);
      area = roomWidth * roomLength;
    }

    // Объём стяжки
    final thicknessM = thickness / 1000;
    final volume = area * thicknessM;

    // Расход материалов
    final cementKg = volume * cementPerCbm[screedType]!;
    final sandKg = volume * sandPerCbm[screedType]!;
    final cementBags = (cementKg / cementBagWeight).ceil();
    final sandCbm = sandKg / sandDensity;

    // Сетка
    final meshArea = needMesh ? area * (1 + meshMargin / 100) : 0.0;

    // Плёнка
    final filmArea = needFilm ? area * (1 + filmMargin / 100) : 0.0;

    // Расчёт стоимости
    final cementPrice = findPrice(priceList, ['cement', 'cement_bag', 'цемент']);
    final sandPrice = findPrice(priceList, ['sand', 'песок']);
    final meshPrice = findPrice(priceList, ['mesh', 'armature_mesh', 'сетка']);
    final filmPrice = findPrice(priceList, ['film', 'pe_film', 'плёнка']);

    final costs = [
      calculateCost(cementBags.toDouble(), cementPrice?.price),
      calculateCost(sandCbm, sandPrice?.price),
      calculateCost(meshArea, meshPrice?.price),
      calculateCost(filmArea, filmPrice?.price),
    ];

    return createResult(
      values: {
        'area': area,
        'thickness': thickness,
        'screedType': screedType.toDouble(),
        'volume': volume,
        'cementKg': cementKg,
        'cementBags': cementBags.toDouble(),
        'sandKg': sandKg,
        'sandCbm': sandCbm,
        'needMesh': needMesh ? 1.0 : 0.0,
        'meshArea': meshArea,
        'needFilm': needFilm ? 1.0 : 0.0,
        'filmArea': filmArea,
      },
      totalPrice: sumCosts(costs),
    );
  }
}
