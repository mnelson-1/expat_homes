#!/usr/bin/env python3
"""Append workflow_perf/v1 JSON objects to docs/perf/history/workflow_history.jsonl.

Modes:
  1) Raw JSON file (one object):
       python scripts/append_workflow_history.py path/to/object.json
       type object.json | python scripts/append_workflow_history.py -

  2) Flutter console log (extracts PERF_WORKFLOW_HISTORY_JSON=...):
       python scripts/append_workflow_history.py --from-console path/to/console.txt

Use --dedupe to skip rows whose recorded_at already exists in the JSONL file.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _read_console_file(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return path.read_text(encoding="utf-16")
    return path.read_text(encoding="utf-8", errors="replace")


def _existing_recorded_ats(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    out: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
            ra = o.get("recorded_at")
            if isinstance(ra, str):
                out.add(ra)
        except json.JSONDecodeError:
            continue
    return out


def _try_parse_workflow_json_fragment(raw: str) -> dict | None:
    """Parse JSON; repair logcat-truncated payloads that include ,"iterations":[..."""
    dec = json.JSONDecoder()
    s = raw.strip()
    if s.startswith("I/flutter"):
        if "PERF_WORKFLOW_HISTORY_JSON=" in s:
            s = s.split("PERF_WORKFLOW_HISTORY_JSON=", 1)[1].strip()
    try:
        obj, _ = dec.raw_decode(s)
        return obj if isinstance(obj, dict) else None
    except json.JSONDecodeError:
        pass
    if ',"iterations":' in s:
        try:
            fixed = s.split(',"iterations":', 1)[0].rstrip() + "}"
            obj, _ = dec.raw_decode(fixed)
            return obj if isinstance(obj, dict) else None
        except json.JSONDecodeError:
            pass
    return None


def extract_workflow_objects_from_console(text: str) -> list[dict]:
    """One JSON object per log line (see perf_probe compact stdout)."""
    needle = "PERF_WORKFLOW_HISTORY_JSON="
    objs: list[dict] = []
    seen: set[str] = set()
    for line in text.splitlines():
        if needle not in line:
            continue
        payload = line.split(needle, 1)[1].strip()
        obj = _try_parse_workflow_json_fragment(payload)
        if not isinstance(obj, dict):
            continue
        ra = obj.get("recorded_at")
        if isinstance(ra, str):
            if ra in seen:
                continue
            seen.add(ra)
        objs.append(obj)
    return objs


def validate_row(obj: dict) -> None:
    if obj.get("schema") != "workflow_perf/v1":
        raise ValueError("Expected schema workflow_perf/v1")
    if "workflows" not in obj or "recorded_at" not in obj:
        raise ValueError("Missing workflows or recorded_at")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    out = root / "docs" / "perf" / "history" / "workflow_history.jsonl"
    out.parent.mkdir(parents=True, exist_ok=True)

    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--from-console",
        metavar="FILE",
        help="Scan Flutter run output for PERF_WORKFLOW_HISTORY_JSON=",
    )
    ap.add_argument(
        "--dedupe",
        action="store_true",
        help="Skip objects whose recorded_at is already in workflow_history.jsonl",
    )
    ap.add_argument(
        "input_path",
        nargs="?",
        help="Single JSON object file, or - for stdin (ignored with --from-console)",
    )
    args = ap.parse_args()

    to_append: list[dict] = []

    if args.from_console:
        log = Path(args.from_console)
        if not log.is_file():
            print(f"Not found: {log}", file=sys.stderr)
            return 1
        text = _read_console_file(log)
        to_append = extract_workflow_objects_from_console(text)
        if not to_append:
            print(
                "No PERF_WORKFLOW_HISTORY_JSON= lines found. "
                "Save full flutter run output after the probe finishes.",
                file=sys.stderr,
            )
            return 1
    else:
        if not args.input_path:
            ap.print_help()
            return 1
        if args.input_path == "-":
            raw = sys.stdin.read()
        else:
            raw = Path(args.input_path).read_text(encoding="utf-8")
        obj = json.loads(raw)
        if not isinstance(obj, dict):
            print("Root JSON must be an object", file=sys.stderr)
            return 1
        to_append = [obj]

    seen = _existing_recorded_ats(out) if args.dedupe else set()
    appended = 0
    for obj in to_append:
        validate_row(obj)
        ra = obj.get("recorded_at")
        if args.dedupe and isinstance(ra, str) and ra in seen:
            print(f"Skip duplicate recorded_at={ra}")
            continue
        line = json.dumps(obj, separators=(",", ":"), ensure_ascii=False)
        with out.open("a", encoding="utf-8") as f:
            f.write(line + "\n")
        if isinstance(ra, str):
            seen.add(ra)
        appended += 1
        print(f"Appended recorded_at={ra} -> {out}")

    if appended == 0:
        print("Nothing appended.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
