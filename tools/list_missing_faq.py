import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ids: set[str] = set()
for p in (ROOT / "lib/domain/calculators").rglob("*.dart"):
    ids.update(re.findall(r"id: '([^']+)'", p.read_text(encoding="utf-8")))

faq = json.load(open(ROOT / "assets/lang/ru.json", encoding="utf-8")).get("faq", {})
missing = sorted(ids - faq.keys())
print(len(ids), "calculators", len(faq), "faq", len(missing), "missing")
for m in missing:
    print(m)
