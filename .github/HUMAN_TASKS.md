# Human Tasks — Owner Action Required

These items can't be completed from CI / the agent (no branch-protection MCP
tool, no `gh` CLI in the sandbox, and some are outward-facing/irreversible).
They're the remaining gap to a "perfect" repo. Check each off when done.

Tracking PR: https://github.com/thinkyou0714/github-flow-kit/pull/6

---

## 1. Enforce CI on `main` (branch protection) — HIGH

Green checks only matter if they block merges. Require both checks on `main`.

```bash
gh api -X PUT repos/thinkyou0714/github-flow-kit/branches/main/protection \
  -F 'required_status_checks[strict]=true' \
  -F 'required_status_checks[contexts][]=validate' \
  -F 'required_status_checks[contexts][]=actionlint' \
  -F 'enforce_admins=true' \
  -F 'required_pull_request_reviews[required_approving_review_count]=1' \
  -f 'restrictions='
```

UI alternative: Settings → Branches → Add branch protection rule → require
`validate` and `actionlint`, require PR before merge, require branches up to date.

- [ ] Done

## 2. Configure CI secrets (optional features) — MEDIUM

All optional; workflows skip gracefully if unset. Settings → Secrets and
variables → Actions.

- [ ] `ANTHROPIC_API_KEY` — AI summaries in auto-release-notes & weekly-triage
- [ ] `SLACK_WEBHOOK_URL` — release announcement in skill-release-announce

## 3. Merge PR #6 — HIGH

After branch protection is on and checks are green.

- [ ] Squash-merge PR #6 into `main`

## 4. Triage open Renovate / feature PRs — MEDIUM

- [ ] PR #4 — `actions/checkout` v4 → v6 (review, then merge)
- [ ] PR #3 — `zenn-cli` 0.4.7 → 0.4.8 (review, then merge)
- [ ] PR #2 — security-audit skills v0.3.0 (review; rebase on #6 once merged)

## 5. Release hygiene — LOW

- [ ] Tag a release once #6 merges; move CHANGELOG `[Unreleased]` → version
- [ ] Decide version number (current `package.json` is 0.2.0; PR #2 targets 0.3.0)

## 6. External validation / proof — LOW

- [ ] Record asciinema demos (README says "coming soon")
- [ ] Verify the auto-release-notes and weekly-triage workflows on a real
      run (manual `workflow_dispatch` for weekly-triage)

---

_Everything code-side (workflow hardening, security alignment, golden tests,
metadata) is implemented and passing in PR #6. The items above are operational
or outward-facing and require a human with repo admin / publishing rights._
