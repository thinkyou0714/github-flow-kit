---
allowed-tools: Bash(git *) Bash(gh pr *) Bash(gh release *) Bash(gh auth *) Read Glob
argument-hint: '[--since <tag>] [--audience ja|en] [--type user|dev] [--dry-run]'
context: fork
description: 'Generate human-readable release notes from git history and merged PRs. Creates two versions: user-facing (what''s new in plain language) and developer-facing (conventional changelog format). Publishes as a GitHub Release draft with auto-suggested semver bump. Use when you''re preparing a release, want to document what changed since the last tag, or need to write CHANGELOG entries. Triggers on: "リリースノート", "changelog", "release notes", "何が変わった", "バージョンアップ", "release-notes". DO NOT USE FOR: creating a new git tag, deploying to production.'
effort: medium
license: MIT
model: claude-sonnet-4-6
name: release-notes
---
# Release Notes Generator

Generate polished release notes from git log and merged PRs.

## Step 1: Determine Range

```bash
git tag --sort=-v:refname | head -5
```

- If `--since <tag>` provided: use that tag as base.
- If no tags exist: use `git rev-list --max-parents=0 HEAD` (first commit).

```bash
git log <base_tag>..HEAD --oneline --no-merges
```

If 0 commits found: output `[RN-003] No commits between <from> and HEAD.` and stop (exit 0).

## Step 2: Fetch PR Data

```bash
gh pr list --state merged --base main --limit 100 \
  --json number,title,body,labels,mergedAt,author \
  --jq '[.[] | select(.mergedAt > "<base_tag_date>")]'
```

Merge with git log. PRs take priority over raw commits for titles.
If gh API fails: use git log only, note `[RN-004] Using git log only (gh API unavailable).`

## Step 3: Classify Changes

Read `references/audience-guide.md` ONLY WHEN writing the user-facing section.

| Category | Labels | Title keywords |
|---|---|---|
| ✨ New Features | `feature`, `enhancement` | `feat:`, `add`, `new`, `implement` |
| 🐛 Bug Fixes | `bug`, `fix` | `fix:`, `bug`, `resolve`, `patch` |
| ⚡ Performance | `performance` | `perf:`, `optimize`, `speed`, `faster` |
| 🔒 Security | `security` | `security`, `CVE`, `vuln`, `auth` |
| 💥 Breaking | `breaking-change` | `BREAKING CHANGE`, `!:` |
| 🔧 Internal | `chore`, `ci`, `refactor` | `chore:`, `refactor:`, `ci:` |
| 📝 Docs | `documentation` | `docs:` |

Filter 🔧 Internal and 📝 Docs from **user-facing** notes.

## Step 4: Suggest Version Bump

```
💥 Breaking present → MAJOR bump (x.0.0)
✨ Features present  → MINOR bump (x.y.0)
🐛 Fixes only        → PATCH bump (x.y.z)
```

Output: `Suggested next version: v<new_version> (current: v<current>)`

## Step 5: Generate Notes

Language = `--audience` flag. Default: detect from README (Japanese if ≥50% JP text).

### User-facing (--type user, default)

**Japanese:**
```markdown
## 🎉 v<NEW_VERSION> — <YYYY-MM-DD>

<lead sentence: theme of this release, 1 sentence>

### ✨ 新機能
- **<Feature name>**: <What the user can now do, plain language, no dev jargon>

### 🐛 改善・修正
- <What was broken and is now fixed, plain language>

### ⚠️ 重要な変更
<Only if breaking changes exist>
- <What users need to do to migrate>
```

**English:**
```markdown
## 🎉 v<NEW_VERSION> — <YYYY-MM-DD>

<Lead sentence>

### ✨ What's New
- **<Feature name>**: <User-facing description>

### 🐛 Fixes & Improvements
- <Fix description>
```

### Developer-facing (--type dev)

```markdown
## [<NEW_VERSION>] — <YYYY-MM-DD>

### Features
- <conventional commit> (#<PR>)

### Bug Fixes
- <fix> (#<PR>)

### BREAKING CHANGES
- <description>
  Migration: <steps>
```

## Step 6: Publish (unless --dry-run)

```bash
gh release create "v<NEW_VERSION>" \
  --draft \
  --title "v<NEW_VERSION>" \
  --notes "<user_facing_notes>"
```

Output:
```
✅ Draft release created: <URL>
Suggested version: v<NEW_VERSION> (<reason>)

📋 人間が確認すること:
  - Breaking Changes セクションの内容確認
  - Draft → Publish に変更する前に最終確認

⭐ Found this useful? Star → https://github.com/thinkyou0714/github-flow-kit
```

## Error Handling

| Code | Condition | Exit |
|---|---|---|
| RN-001 | Usage error (bad args) | 2 |
| RN-002 | Tag not found | 3 |
| RN-003 | No commits in range | 0 |
| RN-004 | gh API unavailable | continue with git log |
