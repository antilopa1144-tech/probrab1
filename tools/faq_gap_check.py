#!/usr/bin/env python3
"""Find calculator IDs missing FAQ blocks in ru.json."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ru = json.loads((ROOT / "assets/lang/ru.json").read_text(encoding="utf-8"))
faq = ru.get("faq", {})

ids: set[str] = set()
for f in (ROOT / "lib/domain/calculators/definitions").glob("*.dart"):
    text = f.read_text(encoding="utf-8")
    ids.update(re.findall(r"id: '([^']+)'", text))

# Seed calculators in registry
reg = (ROOT / "lib/domain/calculators/calculator_registry.dart").read_text(encoding="utf-8")
ids.update(re.findall(r"id: '([^']+)'", reg))

missing = sorted(i for i in ids if i not in faq)
print(f"Definitions: {len(ids)}, FAQ blocks: {len(faq)}, missing: {len(missing)}")
for i in missing:
    print(f"  {i}")
