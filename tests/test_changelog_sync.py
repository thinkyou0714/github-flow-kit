#!/usr/bin/env python3
"""Guard package.json version and CHANGELOG.md release headings."""
import json
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PACKAGE_JSON = REPO / "package.json"
CHANGELOG = REPO / "CHANGELOG.md"


def package_version():
    return json.loads(PACKAGE_JSON.read_text(encoding="utf-8"))["version"]


class TestChangelogSync(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.version = package_version()
        cls.changelog = CHANGELOG.read_text(encoding="utf-8")

    def test_unreleased_section_exists(self):
        self.assertRegex(
            self.changelog,
            r"(?m)^## \[Unreleased\](?:\s|$)",
            "CHANGELOG.md must keep an [Unreleased] section",
        )

    def test_package_version_has_changelog_heading(self):
        self.assertRegex(
            self.changelog,
            rf"(?m)^## \[{re.escape(self.version)}\](?:\s|$)",
            f"CHANGELOG.md must include a heading for package.json version {self.version}",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
