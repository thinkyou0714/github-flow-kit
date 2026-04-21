# github-flow-kit

> **Save 3+ hours/week** on GitHub PR reviews, release notes, issue triage, and repo onboarding — powered by Claude Code.

```bash
gh skill install thinkyou0714/github-flow-kit pr-respond     --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit release-notes  --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit issue-triage   --agent claude-code --scope user
gh skill install thinkyou0714/github-flow-kit repo-tour      --agent claude-code --scope user
```

---

## Skills

| Skill | What it does | Time saved |
|---|---|---|
| [`pr-respond`](#pr-respond) | Read PR review comments → fix code → commit → draft replies | ~50 min/PR → 3 min |
| [`release-notes`](#release-notes) | git log + merged PRs → user-facing + dev changelog | ~55 min → 6 min |
| [`issue-triage`](#issue-triage) | Score 50+ issues by Impact×Effort → sprint plan + labels | Hours → 7 min |
| [`repo-tour`](#repo-tour) | Explore codebase → REPO_TOUR.md with Mermaid diagram | 1-3h → 2 min |

---

## Requirements

- [GitHub CLI](https://cli.github.com/) v2.90.0+
- [Claude Code](https://code.claude.com/) (any plan)
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

Each skill run costs approximately **¥10-40** in Claude API usage (claude-sonnet-4-6).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Found a bug? Open an [Issue](https://github.com/thinkyou0714/github-flow-kit/issues).

---

## License

MIT — Free to use, fork, and customize.

---

*Built with [gh skill](https://cli.github.com/manual/gh_skill) · Powered by [Claude Code](https://code.claude.com/)*
