#!/usr/bin/env python3
"""Golden tests for the issue-triage scoring formula.

Parses the worked-example table under "## スコアリング例" in
issue-triage/references/scoring-rubric.md and verifies that (a) the documented
arithmetic is correct and (b) each example lands in the score band the docs
claim. This keeps the rubric, the formula, and the band thresholds in sync —
a doc edit with bad math fails CI.
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RUBRIC = REPO / "issue-triage" / "references" / "scoring-rubric.md"
SKILL = REPO / "issue-triage" / "SKILL.md"


# score = impact * (6 - effort) + urgency   (see issue-triage/SKILL.md)
def score(impact: int, effort: int, urgency: int) -> int:
    return impact * (6 - effort) + urgency


# Display bands (issue-triage/SKILL.md Step 3 + scoring-rubric.md)
def band(s: int) -> str:
    if s >= 15:
        return "🔴 Sprint必須"
    if s >= 10:
        return "🟡 Sprint推奨"
    if s >= 5:
        return "🟢 Backlog"
    return "⚪ 低優先度"


def parse_examples(text: str):
    """Yield (impact, effort, urgency, claimed_score, band) from the example table."""
    section = text.split("## スコアリング例", 1)
    if len(section) < 2:
        return
    for line in section[1].splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) < 6:
            continue
        # skip header / separator rows
        if cols[1] in ("Impact", "---") or set(cols[1]) <= set("-:"):
            continue
        try:
            impact = int(cols[1])
            effort = int(cols[2])
            urgency = int(cols[3].replace("+", "") or "0")
            claimed = int(cols[4].split("=")[-1])
        except ValueError:
            continue
        yield impact, effort, urgency, claimed, cols[5]


class TestScoringRubric(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = RUBRIC.read_text(encoding="utf-8")
        cls.examples = list(parse_examples(cls.text))

    def test_examples_found(self):
        self.assertGreaterEqual(
            len(self.examples), 4,
            "Expected the worked-example table in scoring-rubric.md",
        )

    def test_arithmetic_and_bands(self):
        for impact, effort, urgency, claimed, claimed_band in self.examples:
            computed = score(impact, effort, urgency)
            self.assertEqual(
                computed, claimed,
                f"Arithmetic mismatch: {impact}×(6−{effort})+{urgency} "
                f"= {computed}, doc says {claimed}",
            )
            self.assertEqual(
                band(computed), claimed_band,
                f"Band mismatch for score {computed}: "
                f"formula says {band(computed)!r}, doc says {claimed_band!r}",
            )

    def test_band_boundaries(self):
        self.assertEqual(band(15), "🔴 Sprint必須")
        self.assertEqual(band(14), "🟡 Sprint推奨")
        self.assertEqual(band(10), "🟡 Sprint推奨")
        self.assertEqual(band(9), "🟢 Backlog")
        self.assertEqual(band(5), "🟢 Backlog")
        self.assertEqual(band(4), "⚪ 低優先度")


def label_lower_bounds(text: str):
    """Lower score bound for each priority:* label (critical→low order)."""
    bounds = []
    for label in ("critical", "high", "medium", "low"):
        m = re.search(rf'priority:{label}".*?score\s*([^\n]+)', text)
        if not m:
            continue
        expr = m.group(1)
        ge = re.search(r"(?:≥|>=)\s*(\d+)", expr)
        rng = re.search(r"(\d+)\s*-\s*\d+", expr)
        lt = re.search(r"<\s*(\d+)", expr)
        if ge:
            bounds.append(int(ge.group(1)))
        elif rng:
            bounds.append(int(rng.group(1)))
        elif lt:
            bounds.append(0)
    return bounds


class TestLabelBands(unittest.TestCase):
    """Step 4 priority:* labels must mirror the Step 3 display bands 1:1."""

    @classmethod
    def setUpClass(cls):
        cls.bounds = label_lower_bounds(SKILL.read_text(encoding="utf-8"))

    def test_four_labels_parsed(self):
        self.assertEqual(len(self.bounds), 4, f"Parsed bounds: {self.bounds}")

    def test_label_bounds_match_display_bands(self):
        # Lower bounds: critical≥15, high 10-14, medium 5-9, low <5.
        self.assertEqual(self.bounds, [15, 10, 5, 0])

    def test_each_label_lands_in_its_display_band(self):
        critical, high, medium, low = self.bounds
        self.assertEqual(band(critical), "🔴 Sprint必須")
        self.assertEqual(band(high), "🟡 Sprint推奨")
        self.assertEqual(band(medium), "🟢 Backlog")
        self.assertEqual(band(low), "⚪ 低優先度")


if __name__ == "__main__":
    unittest.main(verbosity=2)
