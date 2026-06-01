#!/usr/bin/env python3
"""Inventory guard: keep the skill list in sync across the whole repo.

The set of skills is duplicated in several human-edited places (README install
commands, the issue/feature/discussion dropdowns). Historically adding a skill
updated some of them and missed others (the "4 skills vs 6 skills" drift). This
test derives the canonical skill set from the directories that actually contain
a SKILL.md and fails CI if any of those surfaces falls out of sync — so the next
skill addition can't silently leave a stale reference behind.

Dependency-free on purpose (no PyYAML) so it also runs in a bare local checkout.
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def discover_skills():
    """Canonical skill set = top-level dirs containing a SKILL.md."""
    return sorted(p.parent.name for p in REPO.glob("*/SKILL.md"))


def frontmatter_name(skill_md: Path):
    text = skill_md.read_text(encoding="utf-8")
    m = re.search(r"^name:\s*(\S+)\s*$", text, re.MULTILINE)
    return m.group(1) if m else None


def dropdown_options(path: Path):
    """The `- value` list items in a GitHub form-template file."""
    text = path.read_text(encoding="utf-8")
    return [m.group(1).strip() for m in re.finditer(r"^\s*-\s*(.+?)\s*$", text, re.MULTILINE)]


class TestSkillInventory(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.skills = discover_skills()

    def test_skills_discovered(self):
        self.assertTrue(self.skills, "No skill directories (containing SKILL.md) found")

    def test_frontmatter_name_matches_dir(self):
        for skill in self.skills:
            name = frontmatter_name(REPO / skill / "SKILL.md")
            self.assertEqual(
                name, skill,
                f"{skill}/SKILL.md frontmatter name is {name!r}, expected {skill!r}",
            )

    def test_readme_has_install_line_for_each_skill(self):
        readme = (REPO / "README.md").read_text(encoding="utf-8")
        for skill in self.skills:
            pattern = rf"gh skill install thinkyou0714/github-flow-kit {re.escape(skill)}\b"
            self.assertRegex(
                readme, pattern,
                f"README.md is missing the install line for skill '{skill}'",
            )

    def test_form_templates_list_every_skill(self):
        forms = [
            REPO / ".github" / "ISSUE_TEMPLATE" / "bug_report.yml",
            REPO / ".github" / "ISSUE_TEMPLATE" / "feature_request.yml",
            REPO / ".github" / "DISCUSSION_TEMPLATE" / "general.yml",
        ]
        for form in forms:
            self.assertTrue(form.exists(), f"Missing form template: {form}")
            options = dropdown_options(form)
            for skill in self.skills:
                self.assertIn(
                    skill, options,
                    f"{form.relative_to(REPO)} skill dropdown is missing '{skill}'",
                )


if __name__ == "__main__":
    unittest.main(verbosity=2)
