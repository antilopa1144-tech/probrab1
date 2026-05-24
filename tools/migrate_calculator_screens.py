#!/usr/bin/env python3
"""Migrate custom calculator screens to CalculatorEngine."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "presentation" / "views"

FILE_TO_ID = {
    "calculator/attic_calculator_screen.dart": "attic",
    "calculator/balcony_calculator_screen.dart": "balcony",
    "calculator/bathroom_waterproof_calculator_screen.dart": "bathroom_waterproof",
    "calculator/basement_calculator_screen.dart": "foundation_basement",
    "calculator/blind_area_calculator_screen.dart": "foundation_blind_area",
    "calculator/brick_calculator_screen.dart": "partitions_brick",
    "calculator/cassette_ceiling_calculator_screen.dart": "ceilings_cassette",
    "calculator/ceiling_insulation_calculator_screen.dart": "ceilings_insulation",
    "calculator/concrete_universal_calculator_screen.dart": "concrete_universal",
    "calculator/decor_plaster_calculator_screen.dart": "walls_decor_plaster",
    "calculator/decor_stone_calculator_screen.dart": "walls_decor_stone",
    "calculator/doors_install_calculator_screen.dart": "doors_install",
    "calculator/electrical_calculator_screen.dart": "engineering_electrics",
    "calculator/facade_panels_calculator_screen.dart": "exterior_facade_panels",
    "calculator/fence_calculator_screen.dart": "fence",
    "calculator/gasblock_calculator_screen.dart": "partitions_blocks",
    "calculator/gutters_calculator_screen.dart": "roofing_gutters",
    "calculator/gypsum_calculator_screen.dart": "gypsum_board",
    "calculator/linoleum_calculator_screen.dart": "floors_linoleum",
    "calculator/mdf_panels_calculator_screen.dart": "walls_mdf_panels",
    "calculator/pvc_panels_calculator_screen.dart": "walls_pvc_panels",
    "calculator/rail_ceiling_calculator_screen.dart": "ceilings_rail",
    "calculator/screed_unified_calculator_screen.dart": "floors_screed_unified",
    "calculator/slab_calculator_screen.dart": "foundation_slab",
    "calculator/slopes_calculator_screen.dart": "slopes_finishing",
    "calculator/sound_insulation_calculator_screen.dart": "insulation_sound",
    "calculator/stairs_calculator_screen.dart": "stairs",
    "calculator/stretch_ceiling_calculator_screen.dart": "ceilings_stretch",
    "calculator/strip_foundation_calculator_screen.dart": "foundation_strip",
    "calculator/terrace_calculator_screen.dart": "terrace",
    "calculator/three_d_panels_calculator_screen.dart": "walls_3d_panels",
    "calculator/tile_adhesive_calculator_screen.dart": "mixes_tile_glue",
    "calculator/tile_grout_calculator_screen.dart": "floors_tile_grout",
    "calculator/underfloor_heating_calculator_screen.dart": "floors_warm",
    "calculator/ventilation_calculator_screen.dart": "engineering_ventilation",
    "calculator/windows_install_calculator_screen.dart": "windows_install",
    "calculator/wood_lining_calculator_screen.dart": "walls_wood",
    "calculator/room_calculator_screen.dart": "room",
    "calculator/roofing_unified_calculator_screen.dart": "roofing_unified",
    "calculator/primer_calculator_screen.dart": "mixes_primer",
    "calculator/putty_calculator_screen_v2.dart": "mixes_putty",
    "calculator/plaster_calculator_screen.dart": "mixes_plaster",
}

ENGINE_IMPORT = "import '../../../domain/services/calculator_engine.dart';"

FIELD_RE = re.compile(
    r"^\s*final (?:Calculate\w+|_\w+) (?:_\w+ )?= (?:const )?Calculate\w+\(\);\s*\n",
    re.MULTILINE,
)


def transform(path: Path, calc_id: str) -> bool:
    text = path.read_text(encoding="utf-8")
    orig = text

    text = FIELD_RE.sub("", text)

    text = text.replace(
        "_useCase.call(state.toInputs(), _priceList)",
        f"CalculatorEngine.calculate('{calc_id}', state.toInputs(), priceList: _priceList)",
    )

    replacements = [
        (
            "_calculator(_buildCalculationInputs(), <PriceItem>[])",
            f"CalculatorEngine.calculate('{calc_id}', _buildCalculationInputs()",
        ),
        (
            "_calculator(_buildCalculationInputs(), const [])",
            f"CalculatorEngine.calculate('{calc_id}', _buildCalculationInputs()",
        ),
        (
            "_calculator(_buildCalculationInputs(), [])",
            f"CalculatorEngine.calculate('{calc_id}', _buildCalculationInputs()",
        ),
        (
            "_calculator(inputs, [])",
            f"CalculatorEngine.calculate('{calc_id}', inputs)",
        ),
    ]
    for old, new in replacements:
        text = text.replace(old, new)

    if ENGINE_IMPORT not in text:
        lines = text.splitlines(keepends=True)
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import '../../../domain/") or line.startswith(
                "import '../../domain/"
            ):
                insert_at = i + 1
        lines.insert(insert_at, ENGINE_IMPORT + "\n")
        text = "".join(lines)

    if text != orig:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed: list[str] = []
    for rel, calc_id in FILE_TO_ID.items():
        path = ROOT / rel
        if not path.exists():
            print("MISSING", path)
            continue
        if transform(path, calc_id):
            changed.append(rel)

    print(f"Updated {len(changed)} files:")
    for name in sorted(changed):
        print(" ", name)


if __name__ == "__main__":
    main()
