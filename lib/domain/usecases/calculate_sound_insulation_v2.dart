import '../../data/models/price_item.dart';
import './base_calculator.dart';
import './calculator_usecase.dart';

class CalculateSoundInsulationV2 extends BaseCalculator {
  static const double insulationWastePercent = 10.0;
  static const double membraneWastePercent = 15.0;
  static const double gypsumWastePercent = 10.0;
  static const double profileWastePercent = 10.0;
  static const double standardProfileLength = 3.0;
  static const double wallProfileSpacing = 0.6;
  static const double ceilingProfileSpacing = 0.4;
  static const double areaPerHanger = 1.2;

  bool _hasScreenInputs(Map<String, double> inputs) {
    return inputs.containsKey('inputMode') ||
        inputs.containsKey('length') ||
        inputs.containsKey('height');
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final hasDimensions =
        (inputs['length'] ?? 0) > 0 && (inputs['height'] ?? 0) > 0;
    if (area <= 0 && !hasDimensions) {
      return areaOrRoomDimensionsRequiredMessage();
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    if (_hasScreenInputs(inputs)) {
      return _calculateScreenPath(inputs, priceList);
    }
    return _calculateCore(
      area: getInput(
        inputs,
        'area',
        defaultValue: 20.0,
        minValue: 1.0,
        maxValue: 500.0,
      ),
      thickness: getInput(
        inputs,
        'thickness',
        defaultValue: 50.0,
        minValue: 20.0,
        maxValue: 200.0,
      ),
      insulationType: getIntInput(
        inputs,
        'insulationType',
        defaultValue: 0,
        minValue: 0,
        maxValue: 2,
      ),
      surfaceType: getIntInput(
        inputs,
        'surfaceType',
        defaultValue: 0,
        minValue: 0,
        maxValue: 2,
      ),
      needGypsum:
          getIntInput(
            inputs,
            'needGypsum',
            defaultValue: 1,
            minValue: 0,
            maxValue: 1,
          ) ==
          1,
      needProfile:
          getIntInput(
            inputs,
            'needProfile',
            defaultValue: 1,
            minValue: 0,
            maxValue: 1,
          ) ==
          1,
      inputMode: 0,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateScreenPath(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final inputMode = getIntInput(
      inputs,
      'inputMode',
      defaultValue: 0,
      minValue: 0,
      maxValue: 1,
    );
    final area = inputMode == 0
        ? getInput(
            inputs,
            'area',
            defaultValue: 20.0,
            minValue: 1.0,
            maxValue: 500.0,
          )
        : getInput(
                inputs,
                'length',
                defaultValue: 5.0,
                minValue: 1.0,
                maxValue: 50.0,
              ) *
              getInput(
                inputs,
                'height',
                defaultValue: 2.7,
                minValue: 1.0,
                maxValue: 10.0,
              );

    return _calculateCore(
      area: area,
      thickness: getInput(
        inputs,
        'thickness',
        defaultValue: 50.0,
        minValue: 20.0,
        maxValue: 200.0,
      ),
      insulationType: getIntInput(
        inputs,
        'insulationType',
        defaultValue: 0,
        minValue: 0,
        maxValue: 2,
      ),
      surfaceType: getIntInput(
        inputs,
        'surfaceType',
        defaultValue: 0,
        minValue: 0,
        maxValue: 2,
      ),
      needGypsum:
          getIntInput(
            inputs,
            'needGypsum',
            defaultValue: 1,
            minValue: 0,
            maxValue: 1,
          ) ==
          1,
      needProfile:
          getIntInput(
            inputs,
            'needProfile',
            defaultValue: 1,
            minValue: 0,
            maxValue: 1,
          ) ==
          1,
      inputMode: inputMode,
      priceList: priceList,
    );
  }

  CalculatorResult _calculateCore({
    required double area,
    required double thickness,
    required int insulationType,
    required int surfaceType,
    required bool needGypsum,
    required bool needProfile,
    required int inputMode,
    required List<PriceItem> priceList,
  }) {
    double insulationArea = 0;
    if (insulationType != 1) {
      insulationArea = area * (1 + insulationWastePercent / 100);
    }

    double membraneArea = 0;
    if (insulationType != 0) {
      membraneArea = area * (1 + membraneWastePercent / 100);
    }

    final gypsumArea = needGypsum ? area * (1 + gypsumWastePercent / 100) : 0.0;

    double profileLength = 0;
    if (needProfile) {
      final isCeiling = surfaceType == 1;
      final spacing = isCeiling ? ceilingProfileSpacing : wallProfileSpacing;
      final rows = (area / spacing).ceil();
      profileLength =
          rows * standardProfileLength * (1 + profileWastePercent / 100);
    }

    final isCeiling = surfaceType == 1;
    final hangersCount = needProfile && isCeiling
        ? (area / areaPerHanger).ceil()
        : 0;

    final insulationPrice = findPrice(priceList, [
      'insulation',
      'утеплитель',
      'минвата',
      'sound_insulation',
    ]);
    final membranePrice = findPrice(priceList, [
      'membrane',
      'мембрана',
      'sound_membrane',
    ]);
    final gypsumPrice = findPrice(priceList, ['gypsum', 'гипсокартон', 'gkl']);
    final profilePrice = findPrice(priceList, [
      'profile',
      'профиль',
      'cd_profile',
    ]);
    final hangerPrice = findPrice(priceList, [
      'hanger',
      'подвес',
      'suspension',
    ]);

    final costs = [
      if (insulationArea > 0)
        calculateCost(insulationArea, insulationPrice?.price),
      if (membraneArea > 0) calculateCost(membraneArea, membranePrice?.price),
      if (gypsumArea > 0) calculateCost(gypsumArea, gypsumPrice?.price),
      if (profileLength > 0) calculateCost(profileLength, profilePrice?.price),
      if (hangersCount > 0)
        calculateCost(hangersCount.toDouble(), hangerPrice?.price),
    ];

    return createResult(
      values: {
        'inputMode': inputMode.toDouble(),
        'area': area,
        'thickness': thickness,
        'insulationType': insulationType.toDouble(),
        'surfaceType': surfaceType.toDouble(),
        'needGypsum': needGypsum ? 1.0 : 0.0,
        'needProfile': needProfile ? 1.0 : 0.0,
        'insulationArea': insulationArea,
        'membraneArea': membraneArea,
        'gypsumArea': gypsumArea,
        'profileLength': profileLength,
        'hangersCount': hangersCount.toDouble(),
      },
      totalPrice: sumCosts(costs),
    );
  }
}
