#!/usr/bin/env python3
"""Regression tests for the secret scanner used by skill-validate.yml.

The workflow and this test read the SAME pattern file
(.github/secret-patterns.txt), so this is a true test of CI behavior:
- real secret shapes must match (no false negatives),
- documentation that merely *names* the prefixes must NOT match
  (the false positive that previously turned CI red), and
- the committed SKILL.md / references tree must currently be clean.
"""
import re
import sys
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATTERNS_FILE = REPO / ".github" / "secret-patterns.txt"


def load_patterns():
    lines = [
        ln.strip()
        for ln in PATTERNS_FILE.read_text(encoding="utf-8").splitlines()
        if ln.strip()
    ]
    return [re.compile(p) for p in lines]


def any_match(patterns, text):
    return any(p.search(text) for p in patterns)


class TestSecretScan(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.patterns = load_patterns()

    def test_patterns_loaded(self):
        self.assertEqual(len(self.patterns), 4)

    def test_real_secrets_match(self):
        positives = [
            "ghp_" + "a" * 36,
            "sk-ant-" + "b" * 30,
            "AKIA" + "ABCDEFGH12345678",
            "-----BEGIN RSA PRIVATE KEY-----",
            "-----BEGIN OPENSSH PRIVATE KEY-----",
        ]
        for s in positives:
            self.assertTrue(
                any_match(self.patterns, s),
                f"Expected secret shape to match: {s!r}",
            )

    def test_documentation_mentions_do_not_match(self):
        # These are exactly how the patterns are referenced in the skills/docs.
        negatives = [
            "`sk-ant-`, `ghp_`, `AKIA[0-9A-Z]`, `-----BEGIN ... PRIVATE`",
            "secret patterns (sk-ant-…, ghp_…, AKIA…, -----BEGIN … PRIVATE KEY-----)",
            "ghp_ tokens and sk-ant- keys are forbidden",
        ]
        for s in negatives:
            self.assertFalse(
                any_match(self.patterns, s),
                f"Documentation mention must NOT match: {s!r}",
            )

    def test_committed_tree_is_clean(self):
        files = list(REPO.glob("*/SKILL.md")) + list(REPO.glob("*/references/*.md"))
        self.assertTrue(files, "No skill files found to scan")
        offenders = []
        for f in files:
            text = f.read_text(encoding="utf-8")
            for i, line in enumerate(text.splitlines(), 1):
                if any_match(self.patterns, line):
                    offenders.append(f"{f.relative_to(REPO)}:{i}: {line.strip()}")
        self.assertEqual(offenders, [], "Potential secrets found:\n" + "\n".join(offenders))


if __name__ == "__main__":
    unittest.main(verbosity=2)
