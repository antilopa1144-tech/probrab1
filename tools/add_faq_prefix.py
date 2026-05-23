#!/usr/bin/env python3
"""Add faqPrefix to CalculatorScaffold calls in calculator screens."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "lib/presentation/utils/calculator_screen_registry.dart"
CALC_DIR = ROOT / "lib/presentation/views/calculator"
OTHER_DIRS = [
    ROOT / "lib/presentation/views/paint",
    ROOT / "lib/presentation/views/wood",
    ROOT / "lib/presentation/views/osb",
    ROOT / "lib/presentation/views/primer",
]

# Manual overrides when screen file != standard mapping
MANUAL = {
    "paint_screen.dart": "paint_universal",
    "wood_screen.dart": "wood",
    "osb_calculator_screen.dart": "sheeting_osb_plywood",
    "primer_screen.dart": "mixes_primer",
    "primer_calculator_screen.dart": "mixes_primer",
    "putty_calculator_screen_v2.dart": "mixes_putty",
    "brick_calculator_screen.dart": "exterior_brick",
    "screed_unified_calculator_screen.dart": "floors_screed_unified",
    "gypsum_calculator_screen.dart": "gypsum_board",
    "gutters_calculator_screen.dart": "roofing_gutters",
    "gasblock_calculator_screen.dart": "partitions_blocks",
    "sound_insulation_calculator_screen.dart": "insulation_sound",
    "roofing_unified_calculator_screen.dart": "roofing_unified",
}

# FAQ prefix may differ from calculator id when localization uses another key
FAQ_PREFIX_BY_CALC_ID = {
    "partitions_blocks": "faq.partitions",
    "insulation_sound": "faq.insulation",
    "roofing_unified": "faq.roofing",
    "slopes_finishing": "faq.slopes",
}

SKIP_FILES = {"pro_calculator_screen.dart"}


def camel_to_snake(name: str) -> str:
    s = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s).lower()


def screen_class_to_file(class_name: str) -> str:
    if class_name == "PaintScreen":
        return "paint_screen.dart"
    if class_name == "WoodScreen":
        return "wood_screen.dart"
    if class_name.endswith("CalculatorScreen"):
        base = class_name[: -len("CalculatorScreen")]
        return f"{camel_to_snake(base)}_calculator_screen.dart"
    if class_name.endswith("Screen"):
        base = class_name[: -len("Screen")]
        return f"{camel_to_snake(base)}_screen.dart"
    return f"{camel_to_snake(class_name)}.dart"


def parse_registry() -> dict[str, str]:
    text = REGISTRY.read_text(encoding="utf-8")
    pattern = re.compile(
        r"'([^']+)':[^=]*=>\s*(?:\([^)]*\)\s*=>\s*)?(?:const\s+)?(\w+)\("
    )
    mapping: dict[str, str] = {}
    for calc_id, class_name in pattern.findall(text):
        fname = screen_class_to_file(class_name)
        mapping[fname] = calc_id
    mapping.update(MANUAL)
    return mapping


def remove_manual_faq(content: str) -> str:
    """Remove _buildFaqCard method and its usage from children."""
    content = re.sub(
        r"\n\s*const SizedBox\(height: 16\),\n\s*_buildFaqCard\(\),",
        "",
        content,
    )
    content = re.sub(
        r"\n\s*Widget _buildFaqCard\(\) \{[\s\S]*?\n\s*\}\n",
        "\n",
        content,
    )
    return content


def add_faq_prefix(content: str, calc_id: str) -> tuple[str, bool, str | None]:
    if "faqPrefix:" in content:
        return content, False, None

    prefix = FAQ_PREFIX_BY_CALC_ID.get(calc_id, f"faq.{calc_id}")
    # Insert after accentColor line in first CalculatorScaffold(
    match = re.search(
        r"(return CalculatorScaffold\(\n\s*title:[^\n]+\n\s*accentColor:[^\n]+,)",
        content,
    )
    if not match:
        return content, False, None

    insert = f"\n      faqPrefix: '{prefix}',"
    new_content = content[: match.end()] + insert + content[match.end() :]
    return new_content, True, prefix


def main() -> None:
    mapping = parse_registry()
    dirs = [CALC_DIR, *OTHER_DIRS]
    updated = 0
    skipped = 0

    for d in dirs:
        if not d.exists():
            continue
        for path in sorted(d.glob("*.dart")):
            if path.name.startswith("_") or path.name in SKIP_FILES:
                continue
            content = path.read_text(encoding="utf-8")
            if "CalculatorScaffold(" not in content:
                continue
            calc_id = mapping.get(path.name)
            if not calc_id:
                print(f"SKIP (no id): {path.name}")
                skipped += 1
                continue

            original = content
            content = remove_manual_faq(content)
            content, changed, prefix = add_faq_prefix(content, calc_id)
            if content != original:
                path.write_text(content, encoding="utf-8")
            if changed:
                print(f"UPDATED: {path.name} -> {prefix}")
                updated += 1

    print(f"\nDone: {updated} updated, {skipped} skipped")


if __name__ == "__main__":
    main()
