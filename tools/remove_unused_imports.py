#!/usr/bin/env python3
"""Remove unused_import warnings from `flutter analyze` output.

Parses lines like:
    warning - Unused import: 'PATH' - lib\file.dart:LINE:COL - unused_import

Deletes the matching line from the source file. Safe because the line
number and the import path must both match.
"""
from __future__ import annotations

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PATTERN = re.compile(
    r"Unused import: '([^']+)' - (lib[\\/][^ :]+):(\d+):\d+ - unused_import"
)


def collect_edits(analyze_output_path: str | None = None) -> list[tuple[str, int, str]]:
    """Collect (file, line, import_path) tuples from `flutter analyze` output.

    If ``analyze_output_path`` is provided, reads from that file. Otherwise
    runs ``flutter analyze`` via subprocess (requires flutter on PATH).
    """
    if analyze_output_path:
        all_output = Path(analyze_output_path).read_text(encoding="utf-8")
    else:
        result = subprocess.run(
            ["flutter", "analyze", "--no-fatal-infos", "--no-fatal-warnings"],
            capture_output=True,
            text=True,
            cwd=ROOT,
        )
        all_output = (result.stdout or "") + "\n" + (result.stderr or "")
    edits = []
    for line in all_output.splitlines():
        m = PATTERN.search(line)
        if m:
            import_path = m.group(1)
            file_path = m.group(2).replace("\\", "/")
            line_no = int(m.group(3))
            edits.append((file_path, line_no, import_path))
    return edits


def main() -> int:
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    edits = collect_edits(arg)
    print(f"Found {len(edits)} unused imports")

    by_file: dict[str, list[tuple[int, str]]] = defaultdict(list)
    for fp, ln, ip in edits:
        by_file[fp].append((ln, ip))

    removed = 0
    for fp, items in by_file.items():
        items.sort(reverse=True)  # delete from bottom up
        abs_fp = ROOT / fp
        if not abs_fp.exists():
            print(f"MISSING: {abs_fp}")
            continue
        content = abs_fp.read_text(encoding="utf-8")
        lines = content.split("\n")
        for ln, ip in items:
            idx = ln - 1
            if idx >= len(lines):
                print(f"SKIP {fp}:{ln} (out of range)")
                continue
            text = lines[idx]
            if "import" in text and ip in text:
                del lines[idx]
                removed += 1
            else:
                print(f"SKIP {fp}:{ln} mismatch: {text[:80]}")
        abs_fp.write_text("\n".join(lines), encoding="utf-8", newline="\n")

    print(f"Removed {removed} import lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
