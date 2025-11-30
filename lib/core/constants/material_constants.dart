/// Константы строительных материалов: коэффициенты, плотности, нормы расхода.
class MaterialConstants {
  // Плотности материалов (кг/м³)
  static const double densityConcrete = 2400.0;
  static const double densityBrick = 1800.0;
  static const double densityWood = 500.0;
  static const double densityGasBlock = 600.0;
  static const double densityGypsum = 1200.0;
  static const double densitySand = 1600.0;
  static const double densityCement = 1300.0;
  static const double densityMetalProfile = 7850.0;

  // Коэффициенты запаса (%)
  static const double marginConcrete = 10.0;
  static const double marginBrick = 5.0;
  static const double marginTile = 10.0;
  static const double marginPaint = 5.0;
  static const double marginWallpaper = 15.0;
  static const double marginLaminate = 7.0;
  static const double marginInsulation = 5.0;
  static const double marginDrywall = 10.0;
  static const double marginDefault = 10.0;

  // Нормы расхода (на м²)
  static const double consumptionPaintPerM2 = 0.15; // л/м²
  static const double consumptionPrimerPerM2 = 0.1; // л/м²
  static const double consumptionPuttyPerM2 = 1.2; // кг/м² (слой 1мм)
  static const double consumptionPlasterPerM2 = 8.5; // кг/м² (слой 1мм)
  static const double consumptionTileGluePerM2 = 5.0; // кг/м²
  static const double consumptionScreedPerM2 = 20.0; // кг/м² (слой 1см)
  static const double consumptionWaterproofingPerM2 = 1.5; // кг/м²

  // Размеры стандартных материалов
  static const double brickLength = 0.25; // м
  static const double brickWidth = 0.12; // м
  static const double brickHeight = 0.065; // м

  static const double drywallSheetWidth = 1.2; // м
  static const double drywallSheetHeight = 2.5; // м

  static const double insulationSheetWidth = 0.6; // м
  static const double insulationSheetHeight = 1.2; // м

  // Толщины (мм)
  static const double thicknessDrywall = 12.5;
  static const double thicknessDrywallWaterproof = 12.5;
  static const double thicknessTile = 10.0;
  static const double thicknessInsulationStandard = 50.0;
  static const double thicknessPlasterStandard = 20.0;

  // Соотношения для растворов
  static const double cementSandRatioScreed = 1 / 3; // 1 часть цемента на 3 части песка
  static const double cementSandRatioPlaster = 1 / 4;
  static const double cementSandRatioBricklaying = 1 / 4;

  // Количество материалов в упаковке
  static const int tilesPerBox = 10; // среднее
  static const int bricksPerPallet = 400;
  static const int drywallSheetsPerPallet = 50;
  static const int insulationSheetsPerPack = 10;

  // Площади покрытия (м²)
  static const double paintBucketCoverage = 10.0; // 1 л покрывает ~10 м²
  static const double wallpaperRollCoverage = 5.0; // 1 рулон ~5 м²
  static const double laminatePackCoverage = 2.0; // 1 упаковка ~2 м²
}
