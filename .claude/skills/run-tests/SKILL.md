---
allowed-tools: Bash(npm *) Bash(python3 *) Read Grep
description: Run the github-flow-kit test suite and summarize failures. Use when asked to test, verify, or check a skill change.
license: MIT
name: run-tests
---

Run the test suite and report results concisely.

1. Ensure deps are present (SessionStart bootstrap runs `npm ci`; Python tests use the stdlib and need no install).
2. Run `npm test` (→ `python3 -m unittest discover -s tests -p 'test_*.py'`). Single test: `python3 -m unittest tests.<module>`.
3. Summarize: total pass/fail, and for each failure the test name + first assertion/traceback line.
4. Do not edit skill source unless asked; keep each `SKILL.md` frontmatter (name/description/triggers) intact.
