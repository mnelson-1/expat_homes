#!/usr/bin/env python3
"""Append one workflow_perf/v1 JSON object to docs/perf/history/workflow_history.jsonl.

Usage (repo root):
  python scripts/append_workflow_history.py exported_line.json
  # or pipe:
  type line.json | python scripts/append_workflow_history.py -

The file must contain a single JSON object (pretty or one line).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    out = root / "docs" / "perf" / "history" / "workflow_history.jsonl"
    out.parent.mkdir(parents=True, exist_ok=True)

    if len(sys.argv) < 2:
        print("Usage: append_workflow_history.py <file.json> or -", file=sys.stderr)
        return 1

    src = sys.argv[1]
    if src == "-":
        raw = sys.stdin.read()
    else:
        raw = Path(src).read_text(encoding="utf-8")

    obj = json.loads(raw)
    if obj.get("schema") != "workflow_perf/v1":
        print("Expected schema workflow_perf/v1", file=sys.stderr)
        return 1
    if "workflows" not in obj or "recorded_at" not in obj:
        print("Missing workflows or recorded_at", file=sys.stderr)
        return 1

    line = json.dumps(obj, separators=(",", ":"), ensure_ascii=False)
    with out.open("a", encoding="utf-8") as f:
        f.write(line + "\n")
    print(f"Appended to {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
