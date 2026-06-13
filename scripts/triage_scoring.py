#!/usr/bin/env python3
"""Shared issue-triage scoring logic.

The weekly workflow and rubric golden tests both import this module so the
formula has one executable source of truth.
"""
from __future__ import annotations

import datetime as dt
import json
import sys
from pathlib import Path
from typing import Any, Iterable


def _label_names(labels: Iterable[dict[str, Any]] | None) -> list[str]:
    return [
        str(label.get("name", "")).lower()
        for label in (labels or [])
        if isinstance(label, dict)
    ]


def impact(labels: Iterable[dict[str, Any]] | None) -> int:
    names = _label_names(labels)
    if any("bug" in name or "crash" in name or "security" in name for name in names):
        return 5
    if any("enhancement" in name or "feature" in name for name in names):
        return 3
    if any("docs" in name or "refactor" in name for name in names):
        return 1
    return 2


def effort(body: str | None) -> int:
    if not body:
        return 3
    length = len(body)
    if length < 200:
        return 1
    if length < 600:
        return 2
    if length < 1500:
        return 3
    return 4


def thumbs_up(reaction_groups: Iterable[dict[str, Any]] | None) -> int:
    """Return only the thumbs-up reaction count used by the rubric."""
    for reaction_group in reaction_groups or []:
        if reaction_group.get("content") == "THUMBS_UP":
            users = reaction_group.get("users") or {}
            return int(users.get("totalCount") or 0)
    return 0


def urgency_bonus(issue: dict[str, Any], age: int, comments: int) -> int:
    names = _label_names(issue.get("labels", []))
    bonus = 0
    if age > 30 and comments >= 3:
        bonus += 2
    if issue.get("milestone"):
        bonus += 1
    if thumbs_up(issue.get("reactionGroups", [])) >= 5:
        bonus += 1
    if any(name in ("urgent", "hotfix", "p0") for name in names):
        bonus += 3
    return bonus


def score(impact_value: int, effort_value: int, urgency: int) -> int:
    return impact_value * (6 - effort_value) + urgency


def band(score_value: int) -> str:
    if score_value >= 15:
        return "🔴 Sprint必須"
    if score_value >= 10:
        return "🟡 Sprint推奨"
    if score_value >= 5:
        return "🟢 Backlog"
    return "⚪ 低優先度"


def _parse_created_at(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def rank_issues(
    issues: Iterable[dict[str, Any]],
    now: dt.datetime | None = None,
) -> list[dict[str, Any]]:
    now = now or dt.datetime.now(dt.timezone.utc)
    scored = []

    for issue in issues:
        impact_value = impact(issue.get("labels", []))
        effort_value = effort(issue.get("body", ""))
        age = (now - _parse_created_at(issue["createdAt"])).days
        comments = int(issue.get("comments", 0) or 0)
        urgency = urgency_bonus(issue, age, comments)
        total = score(impact_value, effort_value, urgency)
        scored.append(
            {**issue, "score": total, "impact": impact_value, "effort": effort_value}
        )

    return sorted(scored, key=lambda issue: -issue["score"])


def render_top_issues(scored: list[dict[str, Any]]) -> str:
    top10 = scored[:10]
    lines = ["## 🔢 Top Issues This Week", "", "| # | Title | Score |", "|---|---|---|"]

    for issue in top10:
        lines.append(f"| #{issue['number']} | {issue['title'][:60]} | {issue['score']} |")

    if scored[10:]:
        lines.append("")
        lines.append(f"_Plus {len(scored) - 10} more issues in backlog._")

    return "\n".join(lines)


def main(argv: list[str]) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    if len(argv) not in (2, 3):
        print("Usage: triage_scoring.py ISSUES_JSON [OUTPUT_MD]", file=sys.stderr)
        return 2

    issues_path = Path(argv[1])
    output_path = Path(argv[2]) if len(argv) == 3 else Path("/tmp/triage_output.md")
    issues = json.loads(issues_path.read_text(encoding="utf-8"))
    output = render_top_issues(rank_issues(issues))
    output_path.write_text(output, encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
