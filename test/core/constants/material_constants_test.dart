import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants/material_constants.dart';

void main() {
  group('MaterialConstants - Densities', () {
    test('densityConcrete is 2400 kg/m³', () {
      expect(MaterialConstants.densityConcrete, 2400.0);
    });

    test('densityBrick is 1800 kg/m³', () {
      expect(MaterialConstants.densityBrick, 1800.0);
    });

    test('densityWood is 500 kg/m³', () {
      expect(MaterialConstants.densityWood, 500.0);
    });

    test('densityGasBlock is 600 kg/m³', () {
      expect(MaterialConstants.densityGasBlock, 600.0);
    });

    test('densityGypsum is 1200 kg/m³', () {
      expect(MaterialConstants.densityGypsum, 1200.0);
    });

    test('densitySand is 1600 kg/m³', () {
      expect(MaterialConstants.densitySand, 1600.0);
    });

    test('densityCite is 1300 kg/m³', () {
      expect(MaterialConstants.densityCement, 1300.0);
    });

    test('densityMetalProfile is 7850 kg/m³', () {
      expect(MaterialConstants.densityMetalProfile, 7850.0);
    });
  });

  group('MaterialConstants - Margins', () {
    test('marginConcrete is 10%', () {
      expect(MaterialConstants.marginConcrete, 10.0);
    });

    test('marginBrick is 5%', () {
      expect(MaterialConstants.marginBrick, 5.0);
    });

    test('marginTile is 10%', () {
      expect(MaterialConstants.marginTile, 10.0);
    });

    test('marginPaint is 5%', () {
      expect(MaterialConstants.marginPaint, 5.0);
    });

    test('marginWallpaper is 15%', () {
      expect(MaterialConstants.marginWallpaper, 15.0);
    });

    test('marginLaminate is 7%', () {
      expect(MaterialConstants.marginLaminate, 7.0);
    });

    test('marginInsulation is 5%', () {
      expect(MaterialConstants.marginInsulation, 5.0);
    });

    test('marginDrywall is 10%', () {
      expect(MaterialConstants.marginDrywall, 10.0);
    });

    test('marginDefault is 10%', () {
      expect(MaterialConstants.marginDefault, 10.0);
    });
  });

  group('MaterialConstants - Consumption Rates', () {
    test('consumptionPaintPerM2 is 0.15 l/m²', () {
      expect(MaterialConstants.consumptionPaintPerM2, 0.15);
    });

    test('consumptionPrimerPerM2 is 0.1 l/m²', () {
      expect(MaterialConstants.consumptionPrimerPerM2, 0.1);
    });

    test('consumptionPuttyPerM2 is 1.2 kg/m²', () {
      expect(MaterialConstants.consumptionPuttyPerM2, 1.2);
    });

    test('consumptionPlasterPerM2 is 8.5 kg/m²', () {
      expect(MaterialConstants.consumptionPlasterPerM2, 8.5);
    });

    test('consumptionTileGluePerM2 is 5.0 kg/m²', () {
      expect(MaterialConstants.consumptionTileGluePerM2, 5.0);
    });

    test('consumptionScreedPerM2 is 20.0 kg/m²', () {
      expect(MaterialConstants.consumptionScreedPerM2, 20.0);
    });

    test('consumptionWaterproofingPerM2 is 1.5 kg/m²', () {
      expect(MaterialConstants.consumptionWaterproofingPerM2, 1.5);
    });
  });

  group('MaterialConstants - Brick Dimensions', () {
    test('brickLength is 0.25 m', () {
      expect(MaterialConstants.brickLength, 0.25);
    });

    test('brickWidth is 0.12 m', () {
      expect(MaterialConstants.brickWidth, 0.12);
    });

    test('brickHeight is 0.065 m', () {
      expect(MaterialConstants.brickHeight, 0.065);
    });
  });

  group('MaterialConstants - Drywall Dimensions', () {
    test('drywallSheetWidth is 1.2 m', () {
      expect(MaterialConstants.drywallSheetWidth, 1.2);
    });

    test('drywallSheetHeight is 2.5 m', () {
      expect(MaterialConstants.drywallSheetHeight, 2.5);
    });
  });

  group('MaterialConstants - Insulation Dimensions', () {
    test('insulationSheetWidth is 0.6 m', () {
      expect(MaterialConstants.insulationSheetWidth, 0.6);
    });

    test('insulationSheetHeight is 1.2 m', () {
      expect(MaterialConstants.insulationSheetHeight, 1.2);
    });
  });

  group('MaterialConstants - Thicknesses', () {
    test('thicknessDrywall is 12.5 mm', () {
      expect(MaterialConstants.thicknessDrywall, 12.5);
    });

    test('thicknessDrywallWaterproof is 12.5 mm', () {
      expect(MaterialConstants.thicknessDrywallWaterproof, 12.5);
    });

    test('thicknessTile is 10.0 mm', () {
      expect(MaterialConstants.thicknessTile, 10.0);
    });

    test('thicknessInsulationStandard is 50.0 mm', () {
      expect(MaterialConstants.thicknessInsulationStandard, 50.0);
    });

    test('thicknessPlasterStandard is 20.0 mm', () {
      expect(MaterialConstants.thicknessPlasterStandard, 20.0);
    });
  });

  group('MaterialConstants - Mix Ratios', () {
    test('cementSandRatioScreed is 1:3', () {
      expect(MaterialConstants.cementSandRatioScreed, 1 / 3);
    });

    test('cementSandRatioPlaster is 1:4', () {
      expect(MaterialConstants.cementSandRatioPlaster, 1 / 4);
    });

    test('cementSandRatioBricklaying is 1:4', () {
      expect(MaterialConstants.cementSandRatioBricklaying, 1 / 4);
    });
  });

  group('MaterialConstants - Packaging', () {
    test('tilesPerBox is 10', () {
      expect(MaterialConstants.tilesPerBox, 10);
    });

    test('bricksPerPallet is 400', () {
      expect(MaterialConstants.bricksPerPallet, 400);
    });

    test('drywallSheetsPerPallet is 50', () {
      expect(MaterialConstants.drywallSheetsPerPallet, 50);
    });

    test('insulationSheetsPerPack is 10', () {
      expect(MaterialConstants.insulationSheetsPerPack, 10);
    });
  });

  group('MaterialConstants - Coverage Areas', () {
    test('paintBucketCoverage is 10 m²', () {
      expect(MaterialConstants.paintBucketCoverage, 10.0);
    });

    test('wallpaperRollCoverage is 5 m²', () {
      expect(MaterialConstants.wallpaperRollCoverage, 5.0);
    });

    test('laminatePackCoverage is 2 m²', () {
      expect(MaterialConstants.laminatePackCoverage, 2.0);
    });
  });
}
