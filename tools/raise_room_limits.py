#!/usr/bin/env python3
"""Raise length/width maxValue from 20 to 30 in room-level calculators.

Only touches lines that match the pattern:
    label.width / label.length CalculatorTextField with maxValue: 20

This is safer than a blind regex — we require both labelKey + maxValue: 20
on the same line.
"""
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SCREENS = ROOT / "lib" / "presentation" / "views" / "calculator"

# Files where rooms are usually ≤ 30 m (apartments, halls)
ROOM_FILES = [
    "cassette_ceiling_calculator_screen.dart",
    "ceiling_insulation_calculator_screen.dart",
    "decor_plaster_calculator_screen.dart",
    "laminate_calculator_screen.dart",
    "mdf_panels_calculator_screen.dart",
    "parquet_calculator_screen.dart",
    "primer_calculator_screen.dart",
]

PATTERN = re.compile(
    r"(label:\s*_loc\.translate\('[\w_]+\.label\.(?:width|length)'\).*?minValue:\s*1,\s*maxValue:\s*)20\)",
    re.DOTALL,
)
REPLACE = r"\g<1>30)"


def main() -> int:
    total = 0
    for name in ROOM_FILES:
        path = SCREENS / name
        if not path.exists():
            print(f"MISSING: {path}")
            continue
        content = path.read_text(encoding="utf-8")
        new_content, n = PATTERN.subn(REPLACE, content)
        if n > 0:
            path.write_text(new_content, encoding="utf-8", newline="\n")
            print(f"{name}: {n} replacements")
            total += n
    print(f"Total: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
