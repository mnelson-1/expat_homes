#!/usr/bin/env python3
"""Plot workflow_perf/v1 JSONL: one AVG_MS bar chart per role (landlord, agent, expat).

Each chart shows only workflows exercised for that role. Missing/null averages are drawn
as short hatched placeholder bars so the layout matches expectations.

Reads docs/perf/history/workflow_history.jsonl by default.
Optional --allow-synthetic-layout-demo uses the demo file under docs/perf/history/examples/.

Outputs docs/perf/history/plots/{landlord,agent,expat}_workflows_avg_ms.png
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from collections import defaultdict
from pathlib import Path

# Workflow IDs must match expat_app/lib/services/perf_workflow_ids.dart
ROLE_CHART_WORKFLOWS: dict[str, list[str]] = {
    "landlord": [
        "landlord_listing_creation",
        "landlord_listing_assignment",
        "landlord_payment_workflow",
        "landlord_messaging",
    ],
    "agent": [
        "agent_payment_workflow",
        "agent_listing_assignment",
        "agent_bio_view_update",
    ],
    "expat": [
        "expat_explore_area",
        "expat_rides_maps",
        "expat_community_workflow",
        "expat_listing_inquiry_messaging",
    ],
}

LEGEND_LABELS_BY_ROLE: dict[str, dict[str, str]] = {
    "landlord": {
        "landlord_listing_creation": "Listing creation",
        "landlord_listing_assignment": "Listing assignment",
        "landlord_payment_workflow": "Payment workflow (commission slips)",
        "landlord_messaging": "Messaging",
    },
    "agent": {
        "agent_payment_workflow": "Payment workflow (commission slips)",
        "agent_listing_assignment": "Listing assignment (your assignments)",
        "agent_bio_view_update": "Bio-View update",
    },
    "expat": {
        "expat_explore_area": "Explore area (Places)",
        "expat_rides_maps": "Rides / maps (Directions)",
        "expat_community_workflow": "Community (feed)",
        "expat_listing_inquiry_messaging": "Listing inquiry & messaging",
    },
}

ROLE_DISPLAY_NAME = {
    "landlord": "Landlord",
    "agent": "Agent",
    "expat": "Expat",
}

STAT = "avg_ms"

# Pre–role-specific-probe JSONL used shared workflow keys; map where semantics overlap.
LEGACY_WORKFLOW_AVG: dict[tuple[str, str], str] = {
    ("landlord", "landlord_listing_creation"): "landlord_listing_upload",
    ("landlord", "landlord_listing_assignment"): "listing_assignment",
    ("landlord", "landlord_messaging"): "message_translate",
    ("agent", "agent_listing_assignment"): "listing_assignment",
    ("expat", "expat_listing_inquiry_messaging"): "message_translate",
    ("expat", "expat_explore_area"): "explore_places",
    ("expat", "expat_rides_maps"): "rides_estimate",
}

SYNTHETIC_DEMO = (
    Path("docs") / "perf" / "history" / "examples" / "SYNTHETIC_layout_demo_only.jsonl"
)


def load_runs(root: Path, allow_synthetic: bool) -> tuple[list[dict], Path]:
    hist = root / "docs" / "perf" / "history" / "workflow_history.jsonl"
    runs: list[dict] = []
    path = hist
    if hist.is_file() and hist.stat().st_size > 0:
        for line in hist.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            runs.append(json.loads(line))
        return runs, path

    if allow_synthetic:
        demo = root / SYNTHETIC_DEMO
        if not demo.is_file():
            print(f"Missing {demo}", file=sys.stderr)
            sys.exit(1)
        path = demo
        for line in demo.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            runs.append(json.loads(line))
        roles_cycle = ["landlord", "agent", "expat"]
        for i, r in enumerate(runs):
            env = r.setdefault("environment", {})
            if env.get("benchmark_role") is None:
                env["benchmark_role"] = roles_cycle[i % len(roles_cycle)]
        return runs, path

    print(
        "No real data: docs/perf/history/workflow_history.jsonl is missing or empty.\n"
        "1) Run probes with PERF_PROBE_BENCHMARK_ROLE=landlord|agent|expat.\n"
        "2) Append console JSONL via scripts/append_workflow_history.py --dedupe\n"
        "3) Re-run this plot script.\n"
        "Dev-only: add --allow-synthetic-layout-demo",
        file=sys.stderr,
    )
    sys.exit(1)


def _norm_role(raw: object | None) -> str | None:
    if raw is None:
        return None
    s = str(raw).strip().lower()
    if s in ROLE_CHART_WORKFLOWS:
        return s
    return None


def group_runs_by_role(runs: list[dict]) -> dict[str, list[dict]]:
    buckets: dict[str, list[dict]] = defaultdict(list)
    for r in runs:
        role = _norm_role((r.get("environment") or {}).get("benchmark_role"))
        if role is None:
            continue
        buckets[role].append(r)
    for role in buckets:
        buckets[role].sort(key=lambda x: x.get("recorded_at", ""))
    return dict(buckets)


def _is_legacy_five_workflow_export(run: dict) -> bool:
    w = run.get("workflows") or {}
    return "landlord_listing_upload" in w and "landlord_listing_creation" not in w


def _workflow_avg_ms(run: dict, wf: str, role: str) -> float:
    workflows = run.get("workflows") or {}
    block = workflows.get(wf) or {}
    v = block.get(STAT)
    if v is not None:
        return float(v)
    legacy_key = LEGACY_WORKFLOW_AVG.get((role, wf))
    if legacy_key:
        ob = workflows.get(legacy_key) or {}
        ov = ob.get(STAT)
        if ov is not None:
            return float(ov)
    if role == "expat" and wf == "expat_rides_maps":
        old_combined = (workflows.get("expat_rides_and_explore") or {}).get(STAT)
        if old_combined is not None:
            return float(old_combined)
    return float("nan")


def _prepare_heights(raw_vals: list[float]) -> tuple[list[float], list[bool], float]:
    finite = [v for v in raw_vals if not math.isnan(v)]
    ymax_data = max(finite) if finite else 0.0
    stub = max(ymax_data * 0.1, 28.0) if ymax_data > 0 else 0.42
    missing = [math.isnan(v) for v in raw_vals]
    heights = [v if not math.isnan(v) else stub for v in raw_vals]
    return heights, missing, ymax_data


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--allow-synthetic-layout-demo",
        action="store_true",
        help="Plot using docs/perf/history/examples/SYNTHETIC_layout_demo_only.jsonl",
    )
    args = ap.parse_args()

    root = Path(__file__).resolve().parents[1]
    runs, source = load_runs(root, args.allow_synthetic_layout_demo)
    if not runs:
        print("No JSONL rows to plot.", file=sys.stderr)
        return 1

    try:
        import matplotlib.pyplot as plt
        import numpy as np
        from datetime import datetime
        from matplotlib import colormaps
    except ImportError:
        print("pip install matplotlib", file=sys.stderr)
        return 1

    by_role = group_runs_by_role(runs)
    if not by_role:
        print(
            "No rows with environment.benchmark_role (landlord | agent | expat).",
            file=sys.stderr,
        )
        return 1

    out_dir = root / "docs" / "perf" / "history" / "plots"
    out_dir.mkdir(parents=True, exist_ok=True)

    synthetic_note = (
        "\n(DEMO DATA — not real measurements)"
        if "SYNTHETIC" in str(source)
        or "examples" in str(source).replace("\\", "/")
        else ""
    )

    cmap_runs = colormaps["tab10"]
    cmap_wf = colormaps["Set2"]
    wrote = 0

    for role in ("landlord", "agent", "expat"):
        role_runs = by_role.get(role) or []
        if not role_runs:
            print(f"Skip {role}: no probe rows for this role.", file=sys.stderr)
            continue

        wf_list = ROLE_CHART_WORKFLOWS[role]
        legend_map = LEGEND_LABELS_BY_ROLE[role]
        n_wf = len(wf_list)
        n_runs = len(role_runs)
        x = np.arange(n_wf, dtype=float)

        fig_w = max(8.0, 1.35 * n_wf + 4.0)
        fig, ax = plt.subplots(figsize=(fig_w, 5.6))
        fig.subplots_adjust(bottom=0.28)

        legacy_any = any(_is_legacy_five_workflow_export(r) for r in role_runs)

        if n_runs == 1:
            raw_vals = [_workflow_avg_ms(role_runs[0], wf, role) for wf in wf_list]
            heights, missing, _ymax_d = _prepare_heights(raw_vals)
            colors = [
                cmap_wf(i / max(n_wf, 1)) if not missing[i] else "#d0d0d0"
                for i in range(n_wf)
            ]
            bars = ax.bar(
                x,
                heights,
                width=0.72,
                color=colors,
                edgecolor="#333333",
                linewidth=0.4,
            )
            for i, b in enumerate(bars):
                if missing[i]:
                    b.set_hatch("///")
                    b.set_alpha(0.85)
            ax.legend(
                bars,
                [legend_map.get(wf, wf) for wf in wf_list],
                loc="upper right",
                fontsize=8,
            )
            ax.set_xticks(x)
            ax.set_xticklabels(
                [legend_map.get(wf, wf) for wf in wf_list],
                rotation=18,
                ha="right",
                fontsize=8,
            )
            y_top = max(heights) * 1.18 if heights and max(heights) > 0 else 1.0
            ax.set_ylim(0, y_top)
            for i in range(n_wf):
                if missing[i]:
                    ax.text(
                        x[i],
                        heights[i] + y_top * 0.02,
                        "no avg (n=0\nor key)",
                        ha="center",
                        va="bottom",
                        fontsize=6.2,
                        color="#555",
                        linespacing=0.95,
                    )
        else:
            width = 0.8 / max(n_runs, 1)
            offsets = [(j - (n_runs - 1) / 2) * width for j in range(n_runs)]
            global_ymax = 0.0
            for j, run in enumerate(role_runs):
                raw_vals = [_workflow_avg_ms(run, wf, role) for wf in wf_list]
                heights, missing, _ = _prepare_heights(raw_vals)
                global_ymax = max(global_ymax, max(heights) if heights else 0)
                color = cmap_runs(j / max(n_runs, 1))
                face = [
                    color if not missing[i] else "#d0d0d0" for i in range(n_wf)
                ]
                label = datetime.fromisoformat(
                    run["recorded_at"].replace("Z", "+00:00")
                ).strftime("%m-%d %H:%M UTC")
                bars = ax.bar(
                    x + offsets[j],
                    heights,
                    width * 0.92,
                    label=label,
                    color=face,
                    edgecolor="#333333",
                    linewidth=0.3,
                )
                for i, b in enumerate(bars):
                    if missing[i]:
                        b.set_hatch("///")
            ax.set_xticks(x)
            ax.set_xticklabels(
                [legend_map.get(wf, wf) for wf in wf_list],
                rotation=18,
                ha="right",
                fontsize=8,
            )
            ax.legend(
                title="Probe run",
                loc="upper left",
                bbox_to_anchor=(1.02, 1),
                fontsize=7,
            )
            y_top = global_ymax * 1.18 if global_ymax > 0 else 1.0
            ax.set_ylim(0, y_top)

        ax.set_ylabel("Average time (ms) — lower is faster")
        ax.set_xlabel("Workflow")
        ax.grid(axis="y", alpha=0.3)
        display = ROLE_DISPLAY_NAME[role]
        ax.set_title(
            f"{display} — workflow performance ({STAT}){synthetic_note}\n"
            f"(source: {source.relative_to(root)})",
            fontsize=11,
            pad=10,
        )

        foot: list[str] = []
        if legacy_any:
            foot.append(
                "This JSONL still uses the old five-workflow export (e.g. landlord_listing_upload). "
                "Re-run collect-workflow-perf.ps1 after building the current app to record role workflows."
            )
        foot.append(
            "Hatched / gray bars: no avg_ms in file (probe step did not complete or n=0)."
        )
        fig.text(
            0.5,
            0.02,
            "\n".join(foot),
            ha="center",
            va="bottom",
            fontsize=7,
            color="#444",
            wrap=True,
        )

        png = out_dir / f"{role}_workflows_avg_ms.png"
        fig.savefig(png, dpi=150, facecolor="white", bbox_inches="tight")
        plt.close(fig)
        print(f"Wrote {png}")
        wrote += 1

    if wrote == 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
