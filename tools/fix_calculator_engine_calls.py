#!/usr/bin/env python3
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "lib" / "presentation" / "views" / "calculator"

broken_values = re.compile(
    r"CalculatorEngine\.calculate\('([^']+)', _buildCalculationInputs\(\)\.values"
)
missing_paren = re.compile(
    r"CalculatorEngine\.calculate\('([^']+)', _buildCalculationInputs\(\);"
)

for path in root.glob("*.dart"):
    text = path.read_text(encoding="utf-8")
    updated = broken_values.sub(
        r"CalculatorEngine.calculate('\1', _buildCalculationInputs()).values",
        text,
    )
    updated = missing_paren.sub(
        r"CalculatorEngine.calculate('\1', _buildCalculationInputs());",
        updated,
    )
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        print("fixed", path.name)
