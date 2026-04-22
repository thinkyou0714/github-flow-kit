# Changelog

All notable changes to github-flow-kit are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

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
