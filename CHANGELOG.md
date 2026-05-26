# Changelog

All notable changes to github-flow-kit are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [0.3.0] — 2026-05-31

### Added
- Skill `gh-pr-perm-audit`: security-first audit of "Allow GitHub Actions to create and approve
  pull requests" (`can_approve_pull_request_reviews`) across an account. Flags un-allowlisted `true`
  repos (review-bypass exposure, OpenSSF). Read-only; prints the revert command. Includes
  `references/openssf.md`.
- Skill `gh-repo-security-audit`: OpenSSF-aligned posture audit (default workflow token permissions,
  allowed-actions policy, branch protection, secret scanning + push protection, Dependabot alerts)
  with WARN/INFO severity. Read-only except the optional `--enable-dependabot`. Includes
  `references/openssf-checks.md`.
- README: Skills table, Quick Install loop, and Usage sections updated for the 2 new skills (6 total).
- `.github/workflows/actionlint.yml`: meta-CI that lints all workflows (syntax + shellcheck) on every PR touching `.github/workflows/`.
- `.github/WORKFLOWS.md`: GitHub Actions hardening checklist and conventions for cross-repo reuse.
- `tests/`: golden tests — scoring-rubric arithmetic/bands and the secret-scanner (real-secret detection + documentation false-positive guard), run in CI.
- `.github/secret-patterns.txt`: single source of truth for secret patterns, shared by the scanner and its test.
- `pr-respond`: secret-pattern halt and a CI `--auto-push` gate (`GITHUB_FLOW_KIT_ALLOW_PUSH`).
- `issue-triage`: injection-marker and secret-pattern handling for untrusted issue bodies.
- `release-notes` / `repo-tour`: untrusted-input handling for commit/PR/file text.

### Changed
- Hardened all workflows: least-privilege `permissions`, `concurrency` groups, untrusted input routed through `env` (script-injection safe), removed failure-masking `continue-on-error`.
- `skill-release-announce`: gate the Slack step on `env` (secrets can't be used in `if:`).
- `skill-validate`: explicit `actions/setup-python` + `pip install pyyaml`; refreshed valid model list.
- `renovate.json`: pin GitHub Action `uses:` to commit digests (`helpers:pinGitHubActionDigests`).
- `SECURITY.md`: aligned the A1–A4 threat-model claims with the actual skill implementations.

### Fixed
- `package.json` license corrected from `ISC` to `MIT`.

## [0.2.0] — 2026-04-22

### Added
- Zenn articles: `articles/github-flow-kit-pr-respond.md` (pr-respond guide, published: false)
- Zenn articles: `articles/ccmux-stream-timeout-zero.md` (ccmux v1.0 intro, published: false)
- Zenn articles: `articles/en-run-business-with-ai-oss.md` (English, published: false)
- Zenn articles: `articles/en-rethinking-ai-coworker.md` (English, published: false)
- Zenn Book scaffold: `books/claude-code-skill-pack/` (3 chapters, ¥980 planned)
- GH Actions: `auto-release-notes.yml`, `weekly-triage.yml`, `skill-release-announce.yml`
- `PROMOTION.md`: awesome-list / Product Hunt / HN / X post templates
- `.github/DISCUSSION_TEMPLATE/general.yml`: GitHub Discussions form template
- `CONTRIBUTING.md`: contributor guide
- `SECURITY.md`: vulnerability reporting policy
- README: 4 shields badges + FAQ + Secrets Setup section + Star CTA

### Changed
- `articles/zenn-pr-respond-guide.md` renamed to `articles/github-flow-kit-pr-respond.md` (slug alignment)

[0.2.0]: https://github.com/thinkyou0714/github-flow-kit/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/thinkyou0714/github-flow-kit/releases/tag/v0.1.0

---

## [0.1.0] — 2026-04-21

### Added
- `pr-respond`: Classify PR review comments (MUST-FIX/ACK/DISCUSS/SKIP) → fix code → commit → post replies
- `release-notes`: Generate user-facing and developer-facing release notes from git log and merged PRs
- `issue-triage`: Score open issues by Impact×Effort×Urgency → TRIAGE.md + priority labels
- `repo-tour`: Analyze file tree → REPO_TOUR.md with 30-second summary and Mermaid architecture diagram
- `references/` knowledge base for each skill (patterns, scoring rubric, audience guide, architecture templates)
- MIT License
- Security policy with threat model (A1-A4)
