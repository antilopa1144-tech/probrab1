#!/usr/bin/env python3
"""
Remove setState from CalculatorTextField onChanged closures that also call _update().
While the user types, triggering setState resets the widget and re-syncs the controller,
undoing intermediate digits when min/max exist or decimalPlaces format differs.

Keeps Slider/Switch/etc. callbacks unchanged (those need setState).
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "presentation" / "views"

pattern = re.compile(
    r"onChanged:\s*\(v\)\s*\{\s*setState\(\(\)\s*\{\s*"
    r"([^;]+;)\s*_update\(\);\s*\}\);\s*\}",
    re.MULTILINE,
)


def transform_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "CalculatorTextField" not in text:
        return False

    def repl(m: re.Match[str]) -> str:
        assignment = m.group(1).strip()
        return f"onChanged: (v) {{ {assignment} _update(); }}"

    new_text, n = pattern.subn(repl, text)
    if n == 0:
        return False
    path.write_text(new_text, encoding="utf-8")
    print(f"{path.relative_to(ROOT.parent.parent)}: {n} replacement(s)")
    return True


def main() -> None:
    count = 0
    for path in ROOT.rglob("*.dart"):
        if transform_file(path):
            count += 1
    print(f"Done. Modified {count} file(s).")


if __name__ == "__main__":
    main()
