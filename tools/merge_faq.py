#!/usr/bin/env python3
"""Merge missing FAQ entries into assets/lang/ru.json."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RU_JSON = ROOT / "assets/lang/ru.json"
FAQ_JSON = ROOT / "tools/faq_missing.json"


def main() -> None:
    data = json.loads(RU_JSON.read_text(encoding="utf-8"))
    new_entries = json.loads(FAQ_JSON.read_text(encoding="utf-8"))
    faq = data.setdefault("faq", {})
    added = 0
    for key, entry in new_entries.items():
        if key not in faq:
            faq[key] = entry
            added += 1
            print(f"ADDED: {key}")
        else:
            print(f"SKIP (exists): {key}")

    # Alias: ProCalculator uses slopes_finishing id
    if "slopes_finishing" not in faq and "slopes" in faq:
        faq["slopes_finishing"] = dict(faq["slopes"])
        added += 1
        print("ADDED: slopes_finishing (alias of slopes)")

    # Alias partitions
    if "partitions_blocks" not in faq and "partitions" in faq:
        faq["partitions_blocks"] = dict(faq["partitions"])
        added += 1
        print("ADDED: partitions_blocks (alias of partitions)")

    if "partitions_brick" not in faq and "exterior_brick" in faq:
        faq["partitions_brick"] = dict(faq["exterior_brick"])
        added += 1
        print("ADDED: partitions_brick (alias of exterior_brick)")

    if "insulation_sound" not in faq and "insulation" in faq:
        faq["insulation_sound"] = dict(faq["insulation"])
        added += 1
        print("ADDED: insulation_sound (alias of insulation)")

    if "roofing_unified" not in faq and "roofing" in faq:
        faq["roofing_unified"] = dict(faq["roofing"])
        added += 1
        print("ADDED: roofing_unified (alias of roofing)")

    RU_JSON.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"\nDone: {added} entries added, total faq keys: {len(faq)}")


if __name__ == "__main__":
    main()
