#!/usr/bin/env python3
"""Rewrite `(const )?MaterialApp(home: WIDGET(...))` to `createTestApp(child: WIDGET(...))`
in calculator_scaffold_test.dart.

We use a balanced-parentheses scan instead of a regex because the inner widget
can contain nested parens of arbitrary depth.
"""
from __future__ import annotations

from pathlib import Path

TARGET = Path(__file__).resolve().parents[1] / "test" / "presentation" / "widgets" / "calculator" / "calculator_scaffold_test.dart"


def find_matching_paren(text: str, open_pos: int) -> int:
    depth = 0
    i = open_pos
    while i < len(text):
        c = text[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError(f"No matching paren for position {open_pos}")


def rewrite(text: str) -> tuple[str, int]:
    """Return rewritten text + number of replacements."""
    result = []
    i = 0
    count = 0
    while i < len(text):
        # Look for "const MaterialApp(" or "MaterialApp("
        match_const = text.startswith("const MaterialApp(", i)
        match_plain = text.startswith("MaterialApp(", i)
        if match_const or match_plain:
            # Ensure the previous non-space char is `(` (i.e. this is inside pumpWidget())
            j = i - 1
            while j >= 0 and text[j] in " \t\n":
                j -= 1
            if j < 0 or text[j] != "(":
                result.append(text[i])
                i += 1
                continue

            offset_in_match = len("const MaterialApp") if match_const else len("MaterialApp")
            open_paren = i + offset_in_match
            close_paren = find_matching_paren(text, open_paren)
            inner = text[open_paren + 1 : close_paren]

            # Inner should be of the form: \n          home: WIDGET(...),?\n
            # Strip trailing comma+whitespace
            stripped = inner.rstrip().rstrip(",")
            # Look for "home:" prefix
            home_idx = stripped.find("home:")
            if home_idx == -1:
                result.append(text[i])
                i += 1
                continue
            widget_part = stripped[home_idx + len("home:") :].strip()

            # Indent the widget. The original opening is at column of `const MaterialApp` / `MaterialApp`.
            # We keep the trailing newline+indent of the old block.
            indent = ""
            line_start = text.rfind("\n", 0, i) + 1
            indent = text[line_start:i]

            replacement = "createTestApp(\n" + indent + "  child: " + widget_part + ",\n" + indent + ")"
            result.append(replacement)
            i = close_paren + 1
            count += 1
        else:
            result.append(text[i])
            i += 1
    return "".join(result), count


def main() -> int:
    text = TARGET.read_text(encoding="utf-8")
    new_text, count = rewrite(text)
    TARGET.write_text(new_text, encoding="utf-8", newline="\n")
    print(f"Replaced {count} MaterialApp -> createTestApp")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
