# Human Tasks — Owner Action Required

These items can't be completed from CI / the agent (no branch-protection MCP
tool, no `gh` CLI in the sandbox, and some are outward-facing/irreversible).
They're the remaining gap to a "perfect" repo. Check each off when done.

Status: the v0.3.0 code-side work (PRs #1–#9) has merged to `main`. The items
below are the operational / outward-facing tasks that still need a human.

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

## 3. Merge release PRs — DONE

- [x] PR #6 (workflow hardening + golden tests) merged
- [x] PR #2 (security-audit skills, v0.3.0) merged

## 4. Triage open Renovate / feature PRs — MEDIUM

- [x] PR #4 — `actions/checkout` → v6 (merged)
- [x] PR #3 — `zenn-cli` → 0.4.8 (merged)
- [x] PR #8 — `python` → 3.14 (merged)
- [x] PR #9 — `actions/setup-python` → v6 (merged)
- [ ] Keep reviewing future Renovate PRs as they open

## 5. Release hygiene — LOW

- [ ] Tag/publish the `v0.3.0` GitHub release (`package.json` + `CHANGELOG` are already at 0.3.0)

## 6. External validation / proof — LOW

- [ ] Record asciinema demos (README says "coming soon")
- [ ] Verify the auto-release-notes and weekly-triage workflows on a real
      run (manual `workflow_dispatch` for weekly-triage)

---

_Everything code-side (workflow hardening, security alignment, golden tests,
metadata) is implemented, merged, and passing on `main`. The items above are
operational or outward-facing and require a human with repo admin / publishing
rights._
