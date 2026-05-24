import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
reg = (ROOT / "test/helpers/canonical_adapter_registry.dart").read_text(encoding="utf-8")
adapters = set(re.findall(r"'([^']+)':", reg))
fixtures = set()
for p in (ROOT / "test/parity_fixtures").glob("*.parity.json"):
    d = json.loads(p.read_text(encoding="utf-8"))
    fixtures.add(d.get("calculator_id", p.stem.replace(".parity", "")))
print("adapters", len(adapters))
print("fixtures", len(fixtures))
print("fixtures without adapter:", sorted(fixtures - adapters))
print("adapters without fixture:", sorted(adapters - fixtures))
