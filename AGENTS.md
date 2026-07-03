# AGENTS.md — github-flow-kit

6 Claude Code skills for GitHub-native developers: `pr-respond`, `release-notes`, `issue-triage`,
`repo-tour`, `gh-pr-perm-audit`, `gh-repo-security-audit`. Also hosts Zenn articles/books.

- **Stack**: Python skills (stdlib + `unittest`) + Node/Zenn tooling for `articles/`+`books/`.
- **Layout**: one dir per skill (`pr-respond/`, `release-notes/`, …) each with `SKILL.md`; `tests/` (Python unittest); `scripts/`.
- **Setup**: deps auto-install via `.claude/bootstrap.sh` on SessionStart (`npm ci` for Zenn; Python tests need no install). Manual: `npm ci`.
- **Test**: `npm test` (→ `python3 -m unittest discover -s tests -p 'test_*.py'`).
- **Zenn**: `npm run preview` / `npm run new:article`.
- **Conventions**: each skill follows the SKILL.md frontmatter + trigger convention; see `CONTRIBUTING.md`.

## Claude Code on the web

A cloud session auto-installs deps (SessionStart hook) and loads this `AGENTS.md` + `.claude/skills/`.
The 6 shipped skills live in their own top-level dirs (installed into a consumer's `~/.claude`), while
`.claude/skills/run-tests` is a repo-dev helper. MCP is local-only. See `thinkyou0714/.github` →
`docs/claude-code-web-readiness.md`.
