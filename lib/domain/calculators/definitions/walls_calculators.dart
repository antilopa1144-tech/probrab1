// Barrel file для калькуляторов стен.
// Объединяет все подкатегории калькуляторов стен из отдельных файлов.
//
// Для поддерживаемости код был разделен на 3 файла:
// - walls_plaster_calculators.dart: штукатурка, грунтовка, шпатлёвка, плиточный клей
// - walls_masonry_calculators.dart: кирпич, блоки, декоративный камень
// - walls_drywall_calculators.dart: ГКЛ, панели, обои, деревянная отделка

import '../../models/calculator_definition_v2.dart';
import './walls/walls_plaster_calculators.dart';
import './walls/walls_masonry_calculators.dart';
import './walls/walls_drywall_calculators.dart';

/// Полный список калькуляторов для категории "Стены"
///
/// Включает 14 калькуляторов:
/// - 5 штукатурно-отделочных (plaster, primer, putty, tile_glue, decor_plaster)
/// - 3 каменно-кирпичных (blocks, brick, decor_stone)
/// - 6 сухих отделочных (gypsum, 3d_panels, mdf, pvc, wallpaper, wood)
final List<CalculatorDefinitionV2> wallsCalculators = [
  ...wallsPlasterCalculators,
  ...wallsMasonryCalculators,
  ...wallsDrywallCalculators,
];
