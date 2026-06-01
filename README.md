# github-flow-kit

[![Skill Validation](https://github.com/thinkyou0714/github-flow-kit/actions/workflows/skill-validate.yml/badge.svg)](https://github.com/thinkyou0714/github-flow-kit/actions/workflows/skill-validate.yml)
[![Lint Workflows](https://github.com/thinkyou0714/github-flow-kit/actions/workflows/actionlint.yml/badge.svg)](https://github.com/thinkyou0714/github-flow-kit/actions/workflows/actionlint.yml)
[![GitHub release](https://img.shields.io/github/v/release/thinkyou0714/github-flow-kit?color=blue)](https://github.com/thinkyou0714/github-flow-kit/releases)
[![License: MIT](https://img.shields.io/github/license/thinkyou0714/github-flow-kit)](LICENSE)
[![Stars](https://img.shields.io/github/stars/thinkyou0714/github-flow-kit?style=social)](https://github.com/thinkyou0714/github-flow-kit/stargazers)
[![Issues](https://img.shields.io/github/issues/thinkyou0714/github-flow-kit)](https://github.com/thinkyou0714/github-flow-kit/issues)

> **Save 3+ hours/week** on GitHub PR reviews, release notes, issue triage, and repo onboarding — powered by Claude Code.

---

## Why github-flow-kit?

- **Zero setup** — install one command, use immediately. No API keys, no config files.
- **6 skills for every GitHub workflow** — from first PR review to weekly backlog cleanup and security audits.
- **Safe by design** — never modifies migrations, `.env`, auth, or CI files without asking.

---

## Quick Install

```bash
# Install all 6 skills at once
for skill in pr-respond release-notes issue-triage repo-tour gh-pr-perm-audit gh-repo-security-audit; do
  gh skill install thinkyou0714/github-flow-kit $skill --agent claude-code --scope user
done
```

Or install individually:

```bash
gh skill install thinkyou0714/github-flow-kit pr-respond             --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit release-notes          --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit issue-triage           --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit repo-tour              --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit gh-pr-perm-audit       --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit gh-repo-security-audit --agent claude-code --scope user
```

---

## Skills

| Skill | What it does | Time saved |
|---|---|---|
| [`pr-respond`](#pr-respond) | Read PR review comments → fix code → commit → draft replies | ~50 min/PR → 3 min |
| [`release-notes`](#release-notes) | git log + merged PRs → user-facing + dev changelog | ~55 min → 6 min |
| [`issue-triage`](#issue-triage) | Score 50+ issues by Impact×Effort → sprint plan + labels | Hours → 7 min |
| [`repo-tour`](#repo-tour) | Explore codebase → REPO_TOUR.md with Mermaid diagram | 1-3h → 2 min |
| [`gh-pr-perm-audit`](#gh-pr-perm-audit) | Flag repos where Actions can approve PRs (review-bypass) | manual audit → seconds |
| [`gh-repo-security-audit`](#gh-repo-security-audit) | OpenSSF posture: token perms, branch protection, Dependabot | manual audit → seconds |

---

## Demo

> **Coming soon** — asciinema recordings of each skill in action.
>
> Sneak peek: `/pr-respond` on a real open-source PR (5 review comments, 3 files changed, 0 manual edits needed).

---

## Requirements

- [GitHub CLI](https://cli.github.com/) v2.90.0+
- [Claude Code](https://code.claude.com/) (any plan — Free works)
- `gh auth login` completed

---

## Usage

### pr-respond

Address all open PR review comments in one pass.

```bash
/pr-respond                    # auto-detect open PRs with comments
/pr-respond --pr 42            # target specific PR
/pr-respond --dry-run          # preview actions without executing
/pr-respond --auto-push        # push after committing
```

**What it does:**
1. Fetches unresolved review comments
2. Classifies each: `MUST-FIX` / `ACK` / `DISCUSS` / `SKIP`
3. Edits files for MUST-FIX items and commits
4. Drafts response text for each comment
5. Posts replies via `gh pr review --comment`

---

### release-notes

Generate polished release notes from git history.

```bash
/release-notes                        # since last tag, auto-detect language
/release-notes --since v1.2.0        # custom base tag
/release-notes --audience en         # English output
/release-notes --type dev            # conventional changelog format
/release-notes --dry-run             # preview without creating GitHub release
```

**Output:** GitHub Release draft + suggested semver bump.

---

### issue-triage

Score and prioritize your backlog.

```bash
/issue-triage                  # all open issues, 2-week sprint
/issue-triage --sprint 1w      # 1-week sprint capacity
/issue-triage --top 20         # top 20 only
/issue-triage --label bug      # filter by label
/issue-triage --dry-run        # output TRIAGE.md without applying labels
```

**Scoring:** `Impact(1-5) × (6 - Effort(1-5)) + Urgency bonus`

**Output:** `TRIAGE.md` + priority labels applied.

---

### repo-tour

Understand any codebase in minutes.

```bash
/repo-tour                     # full analysis, auto-detect language
/repo-tour --depth 2           # limit directory depth
/repo-tour --focus src/api     # focus on specific subtree
/repo-tour --lang en           # English output
/repo-tour --output stdout     # print instead of writing REPO_TOUR.md
```

**Output:** `REPO_TOUR.md` with 30-second summary, annotated tree, Mermaid diagram.

---

### gh-pr-perm-audit

Security-first audit of "Allow GitHub Actions to create and approve pull requests" across an account.

```bash
/gh-pr-perm-audit                       # audit the authenticated account
/gh-pr-perm-audit --owner some-org      # a specific owner
/gh-pr-perm-audit --allow ci-bot-repo   # mark a repo as intentionally allowed
/gh-pr-perm-audit --json                # machine-readable
```

**Why:** `true` lets a workflow self-approve PRs and bypass required reviews ([OpenSSF](https://best.openssf.org/SCM-BestPractices/github/actions/actions_can_approve_pull_requests.html)). **Read-only** — prints the revert command for you to run.

---

### gh-repo-security-audit

OpenSSF-aligned posture audit across every repo: token permissions, allowed-actions, branch protection, secret scanning, Dependabot.

```bash
/gh-repo-security-audit                  # audit the authenticated account
/gh-repo-security-audit --owner some-org # a specific owner
/gh-repo-security-audit --enable-dependabot  # the one safe opt-in fix (reversible)
/gh-repo-security-audit --json           # machine-readable
```

**Output:** posture table + WARN (fixable) / INFO (hardening). Mutations stay manual except the optional Dependabot enable.

---

## Combine Skills

```bash
# New repo: understand → triage → start working
/repo-tour && /issue-triage --sprint 2w

# Release day
/pr-respond --auto-push && /release-notes

# Weekly maintenance (5 minutes total)
/issue-triage --top 10 --dry-run
```

---

## Update All Skills

```bash
gh skill update --all
```

---

## Cost

Each skill run costs approximately **¥10-40** in Claude API usage (claude-sonnet-4-6, billed through Claude Code).

---

## FAQ

**Q: Do I need a paid Claude Code plan?**
No. All 6 skills work on the Free plan.

**Q: `gh skill install` failed with "command not found"**
You need GitHub CLI v2.90.0 or later. Run `gh --version` to check. Update: `gh upgrade` or download from [cli.github.com](https://cli.github.com/).

**Q: Does it work in Japanese?**
Yes. All skills auto-detect language from README/commit history. Use `--lang ja` or `--lang en` to override.

**Q: Is it safe to run on production repos?**
Yes. `pr-respond` never modifies migrations, `.env`, auth, or CI files. All changes require your `git push` to take effect.

**Q: Can I customize the scoring or classification rules?**
Yes. After install, edit `~/.claude/skills/<skill-name>/references/*.md`. Your changes persist across updates until you reinstall.

---

## Secrets Setup (for CI/CD features)

These secrets are **all optional** — each workflow detects a missing secret and
skips that step gracefully, so CI stays green without them:

| Secret | Enables | How to get |
|---|---|---|
| `ANTHROPIC_API_KEY` | AI summaries in `auto-release-notes`, `weekly-triage` | [console.anthropic.com](https://console.anthropic.com/) |
| `SLACK_WEBHOOK_URL` | Slack post in `skill-release-announce` | Slack app settings → Incoming Webhooks |

Set them at: `github.com/YOUR_ORG/YOUR_REPO` → Settings → Secrets and variables → Actions

> CI/workflow conventions and a portable hardening checklist live in
> [`.github/WORKFLOWS.md`](.github/WORKFLOWS.md).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Found a bug? Open an [Issue](https://github.com/thinkyou0714/github-flow-kit/issues).

---

## License

MIT — Free to use, fork, and customize.

---

*Built with [gh skill](https://cli.github.com/manual/gh_skill) · Powered by [Claude Code](https://code.claude.com/)*

⭐ If github-flow-kit saved you time, a star helps others find it!
