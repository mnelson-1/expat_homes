#!/usr/bin/env python3
"""Line chart: Expat workflow response time (ms) vs iteration within one probe run.

Reads docs/perf/history/workflow_history.jsonl, selects the latest row with
environment.benchmark_role == expat, uses the `iterations` array.

Outputs docs/perf/history/plots/expat_workflow_performance_results.png

Workflow IDs must match expat_app/lib/services/perf_workflow_ids.dart chartOrderExpat.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

EXPAT_WORKFLOWS: list[str] = [
    "expat_explore_area",
    "expat_rides_maps",
    "expat_community_workflow",
    "expat_listing_inquiry_messaging",
]

LABELS: dict[str, str] = {
    "expat_explore_area": "Explore area (Places)",
    "expat_rides_maps": "Rides / maps (Directions)",
    "expat_community_workflow": "Community (feed)",
    "expat_listing_inquiry_messaging": "Listing inquiry & messaging",
}


def _latest_expat_run(jsonl_path: Path) -> dict | None:
    if not jsonl_path.is_file():
        return None
    best: dict | None = None
    best_at = ""
    for line in jsonl_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
        except json.JSONDecodeError:
            continue
        env = o.get("environment") or {}
        if str(env.get("benchmark_role", "")).strip().lower() != "expat":
            continue
        ra = str(o.get("recorded_at") or "")
        if ra >= best_at:
            best_at = ra
            best = o
    return best


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--jsonl",
        type=Path,
        default=None,
        help="workflow_history.jsonl (default: repo docs/perf/history/workflow_history.jsonl)",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Output PNG path",
    )
    args = ap.parse_args()
    root = Path(__file__).resolve().parents[1]
    jsonl = args.jsonl or (root / "docs" / "perf" / "history" / "workflow_history.jsonl")
    out = args.out or (
        root / "docs" / "perf" / "history" / "plots" / "expat_workflow_performance_results.png"
    )

    run = _latest_expat_run(jsonl)
    if run is None:
        print(f"No expat rows in {jsonl}", file=sys.stderr)
        return 1

    iterations = run.get("iterations")
    if not isinstance(iterations, list) or not iterations:
        print(
            "Selected expat row has no `iterations` array. "
            "Re-run the perf probe with a current app build and re-append JSONL.",
            file=sys.stderr,
        )
        return 1

    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("pip install matplotlib", file=sys.stderr)
        return 1

    xs = []
    series: dict[str, list[float | None]] = {w: [] for w in EXPAT_WORKFLOWS}
    for row in iterations:
        if not isinstance(row, dict):
            continue
        it = row.get("iteration")
        if it is None:
            continue
        xs.append(int(it) + 1)
        for w in EXPAT_WORKFLOWS:
            v = row.get(w)
            series[w].append(float(v) if v is not None else None)

    if not xs:
        print("No iteration rows to plot.", file=sys.stderr)
        return 1

    out.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(9, 5.2))
    colors = ("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728")
    for i, w in enumerate(EXPAT_WORKFLOWS):
        ys = series[w]
        if len(ys) != len(xs):
            continue
        y_plot = [math.nan if y is None else y for y in ys]
        ax.plot(
            xs,
            y_plot,
            marker="o",
            linewidth=1.6,
            markersize=5,
            label=LABELS.get(w, w),
            color=colors[i % len(colors)],
        )

    ax.set_xlabel("Iteration (development run #)")
    ax.set_ylabel("Response time (ms)")
    ax.set_title("Expat Workflow Performance Results")
    ax.grid(True, alpha=0.3)
    ax.legend(loc="upper left", fontsize=8)
    ax.set_xticks(xs)
    ra = run.get("recorded_at", "")
    fig.text(0.99, 0.02, f"recorded_at: {ra}", ha="right", fontsize=7, color="#555")
    fig.tight_layout()
    fig.savefig(out, dpi=150, facecolor="white", bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
