class CanonicalBuyPlan {
  final String packageLabel;
  final double packageSize;
  final int packagesCount;
  final String unit;

  const CanonicalBuyPlan({
    required this.packageLabel,
    required this.packageSize,
    required this.packagesCount,
    required this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'package_label': packageLabel,
      'package_size': packageSize,
      'packages_count': packagesCount,
      'unit': unit,
    };
  }
}

class CanonicalScenarioResult {
  final double exactNeed;
  final double purchaseQuantity;
  final double leftover;
  final List<String> assumptions;
  final Map<String, double> keyFactors;
  final CanonicalBuyPlan buyPlan;

  const CanonicalScenarioResult({
    required this.exactNeed,
    required this.purchaseQuantity,
    required this.leftover,
    required this.assumptions,
    required this.keyFactors,
    required this.buyPlan,
  });

  Map<String, dynamic> toJson() {
    return {
      'exact_need': exactNeed,
      'purchase_quantity': purchaseQuantity,
      'leftover': leftover,
      'assumptions': assumptions,
      'key_factors': keyFactors,
      'buy_plan': buyPlan.toJson(),
    };
  }
}

class CanonicalMaterialResult {
  final String name;
  final double quantity;
  final String unit;
  final double? withReserve;
  final int? purchaseQty;
  final String? category;

  const CanonicalMaterialResult({
    required this.name,
    required this.quantity,
    required this.unit,
    this.withReserve,
    this.purchaseQty,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'withReserve': withReserve,
      'purchaseQty': purchaseQty,
      'category': category,
    };
  }
}

class CanonicalCalculatorContractResult {
  final String canonicalSpecId;
  final String formulaVersion;
  final List<CanonicalMaterialResult> materials;
  final Map<String, double> totals;
  final List<String> warnings;
  final Map<String, CanonicalScenarioResult> scenarios;

  const CanonicalCalculatorContractResult({
    required this.canonicalSpecId,
    required this.formulaVersion,
    required this.materials,
    required this.totals,
    required this.warnings,
    required this.scenarios,
  });
}

class CanonicalInputField {
  final String key;
  final String? unit;
  final double defaultValue;
  final double? min;
  final double? max;

  const CanonicalInputField({
    required this.key,
    this.unit,
    required this.defaultValue,
    this.min,
    this.max,
  });
}

class PuttyComponentSpec {
  final String key;
  final String label;
  final String category;
  final List<int> enabledForPuttyTypes;
  final double consumptionKgPerM2Mm;
  final double thicknessMm;

  const PuttyComponentSpec({
    required this.key,
    required this.label,
    required this.category,
    required this.enabledForPuttyTypes,
    required this.consumptionKgPerM2Mm,
    required this.thicknessMm,
  });
}

class PuttyQualityComponentProfile {
  final double consumptionKgPerM2Layer;
  final int defaultLayers;

  const PuttyQualityComponentProfile({
    required this.consumptionKgPerM2Layer,
    required this.defaultLayers,
  });
}

class PuttyQualityProfile {
  final int id;
  final String key;
  final Map<String, PuttyQualityComponentProfile> components;

  const PuttyQualityProfile({
    required this.id,
    required this.key,
    required this.components,
  });
}

class PuttyAuxiliaryRules {
  final double primerLitersPerM2PerCoat;
  final int finishOnlyPrimerCoats;
  final int withStartPrimerCoats;
  final int startOnlyPrimerCoats;
  final double serpyankaLinearMPerM2;
  final double serpyankaReserveFactor;
  final double serpyankaRollLengthM;
  final double sandpaperM2PerSheet;
  final double sandpaperReserveFactor;
  final List<int> sandpaperEnabledForPuttyTypes;

  const PuttyAuxiliaryRules({
    required this.primerLitersPerM2PerCoat,
    required this.finishOnlyPrimerCoats,
    required this.withStartPrimerCoats,
    required this.startOnlyPrimerCoats,
    required this.serpyankaLinearMPerM2,
    required this.serpyankaReserveFactor,
    required this.serpyankaRollLengthM,
    required this.sandpaperM2PerSheet,
    required this.sandpaperReserveFactor,
    required this.sandpaperEnabledForPuttyTypes,
  });
}

class PuttyPackagingRules {
  final String unit;
  final double defaultPackageSize;
  final List<double> allowedPackageSizes;

  const PuttyPackagingRules({
    required this.unit,
    required this.defaultPackageSize,
    required this.allowedPackageSizes,
  });
}

class PuttyWarningRules {
  final double mechanizedAreaThresholdM2;

  const PuttyWarningRules({required this.mechanizedAreaThresholdM2});
}

class PuttyCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<PuttyComponentSpec> components;
  final List<PuttyQualityProfile> qualityProfiles;
  final PuttyPackagingRules packagingRules;
  final PuttyAuxiliaryRules materialRules;
  final PuttyWarningRules warningRules;

  const PuttyCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.components,
    required this.qualityProfiles,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class PrimerSurfaceSpec {
  final int id;
  final String key;
  final String label;
  final double multiplier;

  const PrimerSurfaceSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.multiplier,
  });
}

class PrimerTypeSpec {
  final int id;
  final String key;
  final String label;
  final double baseLitersPerM2;

  const PrimerTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.baseLitersPerM2,
  });
}

class PrimerPackagingRules {
  final String unit;
  final double defaultPackageSize;
  final List<double> allowedPackageSizes;

  const PrimerPackagingRules({
    required this.unit,
    required this.defaultPackageSize,
    required this.allowedPackageSizes,
  });
}

class PrimerMaterialRules {
  final double rollerAreaM2PerPiece;
  final int brushesCount;
  final int traysCount;
  final Map<int, double> dryingTimeHoursByType;

  const PrimerMaterialRules({
    required this.rollerAreaM2PerPiece,
    required this.brushesCount,
    required this.traysCount,
    required this.dryingTimeHoursByType,
  });
}

class PrimerWarningRules {
  final List<int> absorbentSurfaceIds;
  final List<int> recommendedDoubleCoatSurfaceIds;

  const PrimerWarningRules({
    required this.absorbentSurfaceIds,
    required this.recommendedDoubleCoatSurfaceIds,
  });
}

class PrimerCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<PrimerSurfaceSpec> surfaceTypes;
  final List<PrimerTypeSpec> primerTypes;
  final PrimerPackagingRules packagingRules;
  final PrimerMaterialRules materialRules;
  final PrimerWarningRules warningRules;

  const PrimerCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.surfaceTypes,
    required this.primerTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class PaintScopeSpec {
  final int id;
  final String key;
  final String label;

  const PaintScopeSpec({
    required this.id,
    required this.key,
    required this.label,
  });
}

class PaintSurfaceSpec {
  final int id;
  final String key;
  final String label;
  final double multiplier;
  final List<int> scopeIds;

  const PaintSurfaceSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.multiplier,
    required this.scopeIds,
  });
}

class PaintPreparationSpec {
  final int id;
  final String key;
  final String label;
  final double multiplier;

  const PaintPreparationSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.multiplier,
  });
}

class PaintColorSpec {
  final int id;
  final String key;
  final String label;
  final double multiplier;

  const PaintColorSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.multiplier,
  });
}

class PaintPackagingRules {
  final String unit;
  final double defaultPackageSize;
  final List<double> allowedPackageSizes;
  final List<double> optimalPackageSizes;

  const PaintPackagingRules({
    required this.unit,
    required this.defaultPackageSize,
    required this.allowedPackageSizes,
    required this.optimalPackageSizes,
  });
}

class PaintMaterialRules {
  final double primerLitersPerM2;
  final double legacyUniversalPrimerLitersPerM2;
  final double primerPackageSizeLiters;
  final double rollerAreaM2PerPiece;
  final double legacyBrushAreaM2PerPiece;
  final int legacyBrushesMin;
  final int legacyBrushesMax;
  final int brushesCount;
  final int traysCount;
  final double tapeRollLengthM;
  final int tapeRunsPerRoom;
  final double tapeReserveFactor;
  final double ceilingPremiumFactor;
  final double defaultRollerAbsorptionLiters;
  final double legacyFirstCoatMultiplier;

  const PaintMaterialRules({
    required this.primerLitersPerM2,
    required this.legacyUniversalPrimerLitersPerM2,
    required this.primerPackageSizeLiters,
    required this.rollerAreaM2PerPiece,
    required this.legacyBrushAreaM2PerPiece,
    required this.legacyBrushesMin,
    required this.legacyBrushesMax,
    required this.brushesCount,
    required this.traysCount,
    required this.tapeRollLengthM,
    required this.tapeRunsPerRoom,
    required this.tapeReserveFactor,
    required this.ceilingPremiumFactor,
    required this.defaultRollerAbsorptionLiters,
    required this.legacyFirstCoatMultiplier,
  });
}

class PaintWarningRules {
  final List<int> primerRequiredSurfaceIds;
  final int oneCoatWarningThreshold;
  final List<int> roughSurfaceWarningIds;

  const PaintWarningRules({
    required this.primerRequiredSurfaceIds,
    required this.oneCoatWarningThreshold,
    required this.roughSurfaceWarningIds,
  });
}

class PaintCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<PaintScopeSpec> paintTypes;
  final List<PaintSurfaceSpec> surfaceTypes;
  final List<PaintPreparationSpec> surfacePreparations;
  final List<PaintColorSpec> colorIntensities;
  final PaintPackagingRules packagingRules;
  final PaintMaterialRules materialRules;
  final PaintWarningRules warningRules;

  const PaintCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.paintTypes,
    required this.surfaceTypes,
    required this.surfacePreparations,
    required this.colorIntensities,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}



class PlasterTypeSpec {
  final int id;
  final String key;
  final String label;
  final double baseKgPerM2Per10Mm;
  final double defaultBagWeight;
  final List<double> allowedBagWeights;

  const PlasterTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.baseKgPerM2Per10Mm,
    required this.defaultBagWeight,
    required this.allowedBagWeights,
  });
}

class PlasterSubstrateSpec {
  final int id;
  final String key;
  final String label;
  final double multiplier;
  final int primerType;

  const PlasterSubstrateSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.multiplier,
    required this.primerType,
  });
}

class PlasterEvennessSpec {
  final int id;
  final String key;
  final String label;
  final double multiplier;

  const PlasterEvennessSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.multiplier,
  });
}

class PlasterPackagingRules {
  final String unit;

  const PlasterPackagingRules({required this.unit});
}

class PlasterMaterialRules {
  final double reserveFactor;
  final double deepPrimerLitersPerM2;
  final double contactPrimerKgPerM2;
  final double primerPackageSize;
  final double beaconsAreaM2PerPiece;
  final int beaconThinSizeMm;
  final int beaconStandardSizeMm;
  final int thinBeaconThresholdMm;
  final double meshOverlapFactor;
  final double ruleSizeM;
  final int ruleCount;
  final int spatulasCount;
  final int bucketsCount;
  final int mixerCount;
  final int glovesPairs;
  final double cornerProfileLengthM;
  final int cornerProfileCount;

  const PlasterMaterialRules({
    required this.reserveFactor,
    required this.deepPrimerLitersPerM2,
    required this.contactPrimerKgPerM2,
    required this.primerPackageSize,
    required this.beaconsAreaM2PerPiece,
    required this.beaconThinSizeMm,
    required this.beaconStandardSizeMm,
    required this.thinBeaconThresholdMm,
    required this.meshOverlapFactor,
    required this.ruleSizeM,
    required this.ruleCount,
    required this.spatulasCount,
    required this.bucketsCount,
    required this.mixerCount,
    required this.glovesPairs,
    required this.cornerProfileLengthM,
    required this.cornerProfileCount,
  });
}

class PlasterWarningRules {
  final int gypsumTwoLayerThresholdMm;
  final int meshThresholdMm;
  final double smallAreaThresholdM2;
  final int thickLayerWarningThresholdMm;
  final List<int> obryzgTipSubstrateIds;
  final List<int> obryzgTipEvennessIds;

  const PlasterWarningRules({
    required this.gypsumTwoLayerThresholdMm,
    required this.meshThresholdMm,
    required this.smallAreaThresholdM2,
    required this.thickLayerWarningThresholdMm,
    required this.obryzgTipSubstrateIds,
    required this.obryzgTipEvennessIds,
  });
}

class PlasterCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<PlasterTypeSpec> plasterTypes;
  final List<PlasterSubstrateSpec> substrateTypes;
  final List<PlasterEvennessSpec> wallEvennessProfiles;
  final PlasterPackagingRules packagingRules;
  final PlasterMaterialRules materialRules;
  final PlasterWarningRules warningRules;

  const PlasterCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.plasterTypes,
    required this.substrateTypes,
    required this.wallEvennessProfiles,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class WallpaperTypeSpec {
  final int id;
  final String key;
  final String label;
  final double pasteKgPerM2;

  const WallpaperTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.pasteKgPerM2,
  });
}

class WallpaperOpeningDefaultsSpec {
  final double doorAreaM2;
  final double windowAreaM2;

  const WallpaperOpeningDefaultsSpec({
    required this.doorAreaM2,
    required this.windowAreaM2,
  });
}

class WallpaperPackagingRules {
  final String rollUnit;
  final double rollPackageSize;
  final double pastePackKg;
  final double primerCanLiters;

  const WallpaperPackagingRules({
    required this.rollUnit,
    required this.rollPackageSize,
    required this.pastePackKg,
    required this.primerCanLiters,
  });
}

class WallpaperMaterialRules {
  final double trimAllowanceM;
  final double primerLitersPerM2;
  final double primerReserveFactor;
  final double pasteReserveFactor;
  final int glueRollerCount;
  final int wallpaperSpatulaCount;
  final int knifeCount;
  final int bladesPackCount;
  final int bucketCount;
  final int spongeCount;

  const WallpaperMaterialRules({
    required this.trimAllowanceM,
    required this.primerLitersPerM2,
    required this.primerReserveFactor,
    required this.pasteReserveFactor,
    required this.glueRollerCount,
    required this.wallpaperSpatulaCount,
    required this.knifeCount,
    required this.bladesPackCount,
    required this.bucketCount,
    required this.spongeCount,
  });
}

class WallpaperWarningRules {
  final double largeRapportThresholdM;
  final double wideRollThresholdM;
  final int lowStripsPerRollThreshold;

  const WallpaperWarningRules({
    required this.largeRapportThresholdM,
    required this.wideRollThresholdM,
    required this.lowStripsPerRollThreshold,
  });
}

class WallpaperCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<WallpaperTypeSpec> wallpaperTypes;
  final WallpaperOpeningDefaultsSpec openingDefaults;
  final WallpaperPackagingRules packagingRules;
  final WallpaperMaterialRules materialRules;
  final WallpaperWarningRules warningRules;

  const WallpaperCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.wallpaperTypes,
    required this.openingDefaults,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class TileLayoutSpec {
  final int id;
  final String key;
  final String label;
  final double wastePercent;

  const TileLayoutSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.wastePercent,
  });
}

class TileRoomComplexitySpec {
  final int id;
  final String key;
  final String label;
  final double wasteBonusPercent;

  const TileRoomComplexitySpec({
    required this.id,
    required this.key,
    required this.label,
    required this.wasteBonusPercent,
  });
}

class TilePackagingRules {
  final String tileUnit;
  final double tilePackageSize;
  final double glueBagKg;
  final double groutBagKg;
  final double primerCanLiters;
  final int svpPackSize;

  const TilePackagingRules({
    required this.tileUnit,
    required this.tilePackageSize,
    required this.glueBagKg,
    required this.groutBagKg,
    required this.primerCanLiters,
    required this.svpPackSize,
  });
}

class TileMaterialRules {
  final double glueKgPerM2Small;
  final double glueKgPerM2Medium;
  final double glueKgPerM2Large;
  final double glueKgPerM2Xl;
  final double primerLitersPerM2;
  final double groutDensityKgPerM3;
  final double groutLossFactor;
  final double crossesReserveFactor;
  final double svpThresholdCm;
  final double largeTileExtraWastePercent;
  final double mosaicWasteDiscountPercent;
  final double siliconeTubeAreaM2;

  const TileMaterialRules({
    required this.glueKgPerM2Small,
    required this.glueKgPerM2Medium,
    required this.glueKgPerM2Large,
    required this.glueKgPerM2Xl,
    required this.primerLitersPerM2,
    required this.groutDensityKgPerM3,
    required this.groutLossFactor,
    required this.crossesReserveFactor,
    required this.svpThresholdCm,
    required this.largeTileExtraWastePercent,
    required this.mosaicWasteDiscountPercent,
    required this.siliconeTubeAreaM2,
  });
}

class TileWarningRules {
  final int lowTileCountThreshold;
  final double largeTileWarningThresholdCm;
  final double herringboneLargeAreaM2;

  const TileWarningRules({
    required this.lowTileCountThreshold,
    required this.largeTileWarningThresholdCm,
    required this.herringboneLargeAreaM2,
  });
}

class TileCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<TileLayoutSpec> layouts;
  final List<TileRoomComplexitySpec> roomComplexities;
  final TilePackagingRules packagingRules;
  final TileMaterialRules materialRules;
  final TileWarningRules warningRules;

  const TileCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.layouts,
    required this.roomComplexities,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class LaminateLayoutProfileSpec {
  final int id;
  final String key;
  final String label;
  final double wastePercent;

  const LaminateLayoutProfileSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.wastePercent,
  });
}

class LaminatePackagingRules {
  final String laminatePackAreaUnit;
  final double plinthPieceLengthM;
  final double underlaymentRollAreaM2;

  const LaminatePackagingRules({
    required this.laminatePackAreaUnit,
    required this.plinthPieceLengthM,
    required this.underlaymentRollAreaM2,
  });
}

class LaminateMaterialRules {
  final double smallRoomThresholdM2;
  final double smallRoomWastePerM2Percent;
  final double reservePercentDefault;
  final double underlaymentOverlapPercent;
  final double vaporBarrierOverlapPercent;
  final double wedgeSpacingM;
  final double defaultDoorOpeningWidthM;
  final int rectangleInnerCorners;

  const LaminateMaterialRules({
    required this.smallRoomThresholdM2,
    required this.smallRoomWastePerM2Percent,
    required this.reservePercentDefault,
    required this.underlaymentOverlapPercent,
    required this.vaporBarrierOverlapPercent,
    required this.wedgeSpacingM,
    required this.defaultDoorOpeningWidthM,
    required this.rectangleInnerCorners,
  });
}

class LaminateWarningRules {
  final double smallAreaWarningThresholdM2;
  final List<int> diagonalWarningProfileIds;
  final List<int> herringboneWarningProfileIds;
  final List<int> halfShiftWarningProfileIds;

  const LaminateWarningRules({
    required this.smallAreaWarningThresholdM2,
    required this.diagonalWarningProfileIds,
    required this.herringboneWarningProfileIds,
    required this.halfShiftWarningProfileIds,
  });
}

class LaminateCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<LaminateLayoutProfileSpec> layoutProfiles;
  final LaminatePackagingRules packagingRules;
  final LaminateMaterialRules materialRules;
  final LaminateWarningRules warningRules;

  const LaminateCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.layoutProfiles,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class ParquetLayoutProfileSpec {
  final int id;
  final String key;
  final String label;
  final double wastePercent;

  const ParquetLayoutProfileSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.wastePercent,
  });
}

class ParquetPackagingRules {
  final String parquetPackAreaUnit;
  final double underlaymentRollAreaM2;
  final double plinthPieceLengthM;
  final double glueBucketKg;

  const ParquetPackagingRules({
    required this.parquetPackAreaUnit,
    required this.underlaymentRollAreaM2,
    required this.plinthPieceLengthM,
    required this.glueBucketKg,
  });
}

class ParquetMaterialRules {
  final double reservePercentDefault;
  final double underlaymentOverlapPercent;
  final double wedgeSpacingM;
  final double defaultDoorOpeningWidthM;
  final double glueKgPerM2;
  final double plinthReservePercent;

  const ParquetMaterialRules({
    required this.reservePercentDefault,
    required this.underlaymentOverlapPercent,
    required this.wedgeSpacingM,
    required this.defaultDoorOpeningWidthM,
    required this.glueKgPerM2,
    required this.plinthReservePercent,
  });
}

class ParquetWarningRules {
  final double smallAreaWarningThresholdM2;
  final List<int> diagonalWarningProfileIds;
  final List<int> herringboneWarningProfileIds;

  const ParquetWarningRules({
    required this.smallAreaWarningThresholdM2,
    required this.diagonalWarningProfileIds,
    required this.herringboneWarningProfileIds,
  });
}

class ParquetCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<ParquetLayoutProfileSpec> layoutProfiles;
  final ParquetPackagingRules packagingRules;
  final ParquetMaterialRules materialRules;
  final ParquetWarningRules warningRules;

  const ParquetCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.layoutProfiles,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class LinoleumPackagingRules {
  final String linearMeterUnit;
  final double linearMeterStepM;
  final double plinthPieceLengthM;
  final double primerCanLiters;
  final double glueBucketKg;
  final double coldWeldingTubeLinearM;

  const LinoleumPackagingRules({
    required this.linearMeterUnit,
    required this.linearMeterStepM,
    required this.plinthPieceLengthM,
    required this.primerCanLiters,
    required this.glueBucketKg,
    required this.coldWeldingTubeLinearM,
  });
}

class LinoleumMaterialRules {
  final double trimAllowanceM;
  final double roomMarginM;
  final double glueKgPerM2;
  final double primerLitersPerM2;
  final double plinthReservePercent;
  final double defaultDoorOpeningWidthM;
  final double tapeExtraPerimeterRun;

  const LinoleumMaterialRules({
    required this.trimAllowanceM,
    required this.roomMarginM,
    required this.glueKgPerM2,
    required this.primerLitersPerM2,
    required this.plinthReservePercent,
    required this.defaultDoorOpeningWidthM,
    required this.tapeExtraPerimeterRun,
  });
}

class LinoleumWarningRules {
  final double highWastePercentThreshold;
  final double maxSingleRollWidthM;
  final double lowRollWidthWarningThresholdM;

  const LinoleumWarningRules({
    required this.highWastePercentThreshold,
    required this.maxSingleRollWidthM,
    required this.lowRollWidthWarningThresholdM,
  });
}

class LinoleumCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final LinoleumPackagingRules packagingRules;
  final LinoleumMaterialRules materialRules;
  final LinoleumWarningRules warningRules;

  const LinoleumCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

class SelfLevelingMixtureTypeSpec {
  final int id;
  final String key;
  final String label;
  final double baseKgPerM2Mm;

  const SelfLevelingMixtureTypeSpec({
    required this.id,
    required this.key,
    required this.label,
    required this.baseKgPerM2Mm,
  });
}

class SelfLevelingPackagingRules {
  final String unit;
  final double primerCanL;
  final double tapeRollM;

  const SelfLevelingPackagingRules({
    required this.unit,
    required this.primerCanL,
    required this.tapeRollM,
  });
}

class SelfLevelingMaterialRules {
  final double reserveFactor;
  final double primerLPerM2;
  final double levelingMinThicknessMm;
  final double finishMaxThicknessMm;
  final double deformationJointAreaThresholdM2;

  const SelfLevelingMaterialRules({
    required this.reserveFactor,
    required this.primerLPerM2,
    required this.levelingMinThicknessMm,
    required this.finishMaxThicknessMm,
    required this.deformationJointAreaThresholdM2,
  });
}

class SelfLevelingWarningRules {
  final double largeAreaThresholdM2;

  const SelfLevelingWarningRules({required this.largeAreaThresholdM2});
}

class SelfLevelingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final List<SelfLevelingMixtureTypeSpec> mixtureTypes;
  final SelfLevelingPackagingRules packagingRules;
  final SelfLevelingMaterialRules materialRules;
  final SelfLevelingWarningRules warningRules;

  const SelfLevelingCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.mixtureTypes,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── Drywall Ceiling ─── */

class DrywallCeilingPackagingRules {
  final String unit;
  final int packageSize;

  const DrywallCeilingPackagingRules({required this.unit, required this.packageSize});
}

class DrywallCeilingMaterialRules {
  final double sheetArea;
  final double sheetReserve;
  final double profileReserve;
  final double crossStep;
  final double suspensionStep;
  final int screwsPerSheet;
  final int screwsPerKg;
  final double screwReserve;
  final int clopPerSusp;
  final int clopPerCrab;
  final double dowelStep;
  final double serpyankaCoeff;
  final double serpyankaReserve;
  final double serpyankaRoll;
  final double puttyKgPerM;
  final double puttyBag;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final double profileLength;

  const DrywallCeilingMaterialRules({
    required this.sheetArea,
    required this.sheetReserve,
    required this.profileReserve,
    required this.crossStep,
    required this.suspensionStep,
    required this.screwsPerSheet,
    required this.screwsPerKg,
    required this.screwReserve,
    required this.clopPerSusp,
    required this.clopPerCrab,
    required this.dowelStep,
    required this.serpyankaCoeff,
    required this.serpyankaReserve,
    required this.serpyankaRoll,
    required this.puttyKgPerM,
    required this.puttyBag,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.profileLength,
  });
}

class DrywallCeilingWarningRules {
  final double deformationJointAreaThresholdM2;

  const DrywallCeilingWarningRules({required this.deformationJointAreaThresholdM2});
}

class DrywallCeilingCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final DrywallCeilingPackagingRules packagingRules;
  final DrywallCeilingMaterialRules materialRules;
  final DrywallCeilingWarningRules warningRules;

  const DrywallCeilingCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── 3D Panels ─── */

class Panels3dPackagingRules {
  final String unit;
  final int packageSize;

  const Panels3dPackagingRules({required this.unit, required this.packageSize});
}

class Panels3dMaterialRules {
  final double panelReserve;
  final double glueKgPerM2;
  final double primerLPerM2;
  final double puttyKgPerM2;
  final double paintLPerM2;
  final double varnishLPerM2;
  final double glueBag;
  final double primerCan;
  final double puttyBag;
  final double paintCan;
  final double varnishCan;

  const Panels3dMaterialRules({
    required this.panelReserve,
    required this.glueKgPerM2,
    required this.primerLPerM2,
    required this.puttyKgPerM2,
    required this.paintLPerM2,
    required this.varnishLPerM2,
    required this.glueBag,
    required this.primerCan,
    required this.puttyBag,
    required this.paintCan,
    required this.varnishCan,
  });
}

class Panels3dWarningRules {
  final double largeAreaThresholdM2;

  const Panels3dWarningRules({required this.largeAreaThresholdM2});
}

class Panels3dCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final Panels3dPackagingRules packagingRules;
  final Panels3dMaterialRules materialRules;
  final Panels3dWarningRules warningRules;

  const Panels3dCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── MDF Panels ─── */

class MdfPanelsPackagingRules {
  final String unit;
  final int packageSize;

  const MdfPanelsPackagingRules({required this.unit, required this.packageSize});
}

class MdfPanelsMaterialRules {
  final double panelReserve;
  final double profileReserve;
  final double profileStep;
  final double standardPanelLength;
  final int clipsPerPanel;
  final double plinthLength;
  final double plinthExtra;

  const MdfPanelsMaterialRules({
    required this.panelReserve,
    required this.profileReserve,
    required this.profileStep,
    required this.standardPanelLength,
    required this.clipsPerPanel,
    required this.plinthLength,
    required this.plinthExtra,
  });
}

class MdfPanelsWarningRules {
  final double largeAreaThresholdM2;

  const MdfPanelsWarningRules({required this.largeAreaThresholdM2});
}

class MdfPanelsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final MdfPanelsPackagingRules packagingRules;
  final MdfPanelsMaterialRules materialRules;
  final MdfPanelsWarningRules warningRules;

  const MdfPanelsCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── PVC Panels ─── */

class PvcPanelsPackagingRules {
  final String unit;
  final int packageSize;

  const PvcPanelsPackagingRules({required this.unit, required this.packageSize});
}

class PvcPanelsMaterialRules {
  final double panelReserve;
  final double profileReserve;
  final double profileStep;
  final List<double> panelLengths;
  final double cornerProfileLength;
  final int standardCorners;

  const PvcPanelsMaterialRules({
    required this.panelReserve,
    required this.profileReserve,
    required this.profileStep,
    required this.panelLengths,
    required this.cornerProfileLength,
    required this.standardCorners,
  });
}

class PvcPanelsWarningRules {
  final double largeAreaThresholdM2;

  const PvcPanelsWarningRules({required this.largeAreaThresholdM2});
}

class PvcPanelsCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final PvcPanelsPackagingRules packagingRules;
  final PvcPanelsMaterialRules materialRules;
  final PvcPanelsWarningRules warningRules;

  const PvcPanelsCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── Wood Wall ─── */

class WoodWallPackagingRules {
  final String unit;
  final int packageSize;

  const WoodWallPackagingRules({required this.unit, required this.packageSize});
}

class WoodWallMaterialRules {
  final double boardReserve;
  final double antisepticLPerM2;
  final double finishLPerM2;
  final int finishLayers;
  final double primerLPerM2;
  final int fastenersPerBoard;
  final int clampsPerBoard;
  final double battenStep;
  final double plinthReserve;
  final double cornerRatio;
  final double cornerReserve;

  const WoodWallMaterialRules({
    required this.boardReserve,
    required this.antisepticLPerM2,
    required this.finishLPerM2,
    required this.finishLayers,
    required this.primerLPerM2,
    required this.fastenersPerBoard,
    required this.clampsPerBoard,
    required this.battenStep,
    required this.plinthReserve,
    required this.cornerRatio,
    required this.cornerReserve,
  });
}

class WoodWallWarningRules {
  final double largeAreaThresholdM2;

  const WoodWallWarningRules({required this.largeAreaThresholdM2});
}

class WoodWallCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final WoodWallPackagingRules packagingRules;
  final WoodWallMaterialRules materialRules;
  final WoodWallWarningRules warningRules;

  const WoodWallCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}

/* ─── Decor Stone ─── */

class DecorStonePackagingRules {
  final String unit;
  final int packageSize;

  const DecorStonePackagingRules({required this.unit, required this.packageSize});
}

class DecorStoneMaterialRules {
  final double stoneReserve;
  final List<double> glueKgPerM2;
  final double glueReserve;
  final double glueBag;
  final double primerLPerM2;
  final double primerReserve;
  final double primerCan;
  final double groutBaseFactor;
  final double groutReserve;
  final double groutBag;

  const DecorStoneMaterialRules({
    required this.stoneReserve,
    required this.glueKgPerM2,
    required this.glueReserve,
    required this.glueBag,
    required this.primerLPerM2,
    required this.primerReserve,
    required this.primerCan,
    required this.groutBaseFactor,
    required this.groutReserve,
    required this.groutBag,
  });
}

class DecorStoneWarningRules {
  final double largeAreaThresholdM2;

  const DecorStoneWarningRules({required this.largeAreaThresholdM2});
}

class DecorStoneCanonicalSpec {
  final String calculatorId;
  final String formulaVersion;
  final List<CanonicalInputField> inputSchema;
  final List<String> enabledFactors;
  final DecorStonePackagingRules packagingRules;
  final DecorStoneMaterialRules materialRules;
  final DecorStoneWarningRules warningRules;

  const DecorStoneCanonicalSpec({
    required this.calculatorId,
    required this.formulaVersion,
    required this.inputSchema,
    required this.enabledFactors,
    required this.packagingRules,
    required this.materialRules,
    required this.warningRules,
  });
}
