#!/usr/bin/env python3
"""Plot docs/qa/generated/system_overview_for_charts.csv into PNG + SVG.

Run from repo root after collecting metrics:
  pip install -r scripts/requirements-plot.txt
  python scripts/plot_system_overview.py

Output: docs/qa/generated/system_overview_charts.png (and .svg)
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    csv_path = root / "docs" / "qa" / "generated" / "system_overview_for_charts.csv"
    out_dir = csv_path.parent

    if not csv_path.is_file():
        print(
            f"Missing {csv_path}\n"
            "Run from repo root: .\\scripts\\collect-test-metrics.ps1",
            file=sys.stderr,
        )
        return 1

    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print(
            "matplotlib is required. Run: pip install -r scripts/requirements-plot.txt",
            file=sys.stderr,
        )
        return 1

    rows: list[dict[str, str]] = []
    with csv_path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rows.append(row)

    def nums(group: str) -> list[tuple[str, float]]:
        out: list[tuple[str, float]] = []
        for r in rows:
            if r.get("chart_group") != group:
                continue
            try:
                v = float(r["value_numeric"])
            except (KeyError, ValueError):
                continue
            label = r.get("metric_label", r.get("metric_key", ""))
            out.append((label, v))
        return out

    pct = nums("percent_0_100")
    counts = nums("counts")
    seconds = nums("seconds")
    ms = nums("milliseconds")
    gate = nums("gate")

    plt.rcParams.update(
        {
            "font.size": 9,
            "axes.titlesize": 11,
            "axes.labelsize": 9,
        }
    )

    fig, axes = plt.subplots(2, 2, figsize=(12, 9), layout="constrained")
    fig.suptitle(
        "ExpatHomes — system quality & runtime overview\n"
        "(automated tests + optional perf probe; see viewer_note in CSV for limits)",
        fontsize=12,
        fontweight="bold",
    )

    def hbar(ax, data: list[tuple[str, float]], title: str, xlabel: str) -> None:
        if not data:
            ax.set_title(title)
            ax.text(0.5, 0.5, "No rows", ha="center", va="center", transform=ax.transAxes)
            return
        labels, vals = zip(*data, strict=True)
        y = range(len(labels))
        colors = plt.cm.viridis([0.2 + 0.6 * i / max(len(vals) - 1, 1) for i in range(len(vals))])
        ax.barh(list(y), list(vals), color=colors, height=0.65)
        ax.set_yticks(list(y))
        ax.set_yticklabels([_shorten(l, 48) for l in labels], fontsize=8)
        ax.set_xlabel(xlabel)
        ax.set_title(title)
        ax.invert_yaxis()
        for i, v in enumerate(vals):
            ax.text(v, i, f"  {v:g}", va="center", fontsize=8, color="#333")

    hbar(axes[0, 0], pct, "0–100% scale", "Percent")
    hbar(axes[0, 1], counts, "Counts", "Count")
    hbar(axes[1, 0], ms, "Milliseconds (probe)", "ms")
    # seconds + gate on same panel if small
    sec_gate = seconds + gate
    hbar(axes[1, 1], sec_gate, "Seconds & gate", "Value")

    png = out_dir / "system_overview_charts.png"
    svg = out_dir / "system_overview_charts.svg"
    fig.savefig(png, dpi=150, bbox_inches="tight", facecolor="white")
    fig.savefig(svg, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"Wrote {png}")
    print(f"Wrote {svg}")
    return 0


def _shorten(s: str, max_len: int) -> str:
    s = s.strip()
    if len(s) <= max_len:
        return s
    return s[: max_len - 1] + "…"


if __name__ == "__main__":
    raise SystemExit(main())
