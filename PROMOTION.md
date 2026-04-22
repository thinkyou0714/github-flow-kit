# github-flow-kit Promotion Templates

Ready-to-paste text for submitting to lists and platforms.

---

## awesome-claude-code / awesome-copilot-instructions

**PR title:** `Add github-flow-kit — Claude Code skill pack for GitHub automation`

**PR body:**
```markdown
## github-flow-kit

**Category:** Tools / Skill Packs

**Description:** 4-skill pack for Claude Code that automates daily GitHub workflows.
Installs via `gh skill install` — no API keys or configuration required.

**Skills:**
- `/pr-respond` — Auto-classify and respond to PR review comments (50min → 3min)
- `/release-notes` — Generate user-facing + developer changelogs from git log
- `/issue-triage` — Score and prioritize issue backlog by Impact × Effort × Urgency
- `/repo-tour` — Generate architecture overview + Mermaid diagram for any repo

**Links:**
- GitHub: https://github.com/thinkyou0714/github-flow-kit
- Install: `gh skill install thinkyou0714/github-flow-kit pr-respond --agent claude-code --scope user`
```

**Submission targets:**
- https://github.com/wong2/awesome-claude-code (check if exists)
- https://github.com/nicholasgasior/awesome-claude (check if exists)
- https://github.com/ai-boost/awesome-prompts (check if relevant)

---

## Product Hunt

**Tagline:** `4 Claude Code skills that automate your entire GitHub workflow`

**Description:**
```
github-flow-kit is a free skill pack for Claude Code that automates the GitHub tasks you do every day.

Install 4 skills with one command:
- /pr-respond — Handle all PR review comments in 3 minutes instead of 50
- /release-notes — Auto-generate changelogs from your git history
- /issue-triage — Score your issue backlog by impact × effort
- /repo-tour — Understand any codebase in 2 minutes

Zero configuration. No API keys. Just gh skill install and go.

Open source. MIT license.
```

**Topics:** Developer Tools, GitHub, AI, Productivity, Open Source

**Gallery images needed:**
- Terminal screenshot of `/pr-respond` in action
- Before/after time comparison table

---

## Hacker News — Show HN

```
Show HN: github-flow-kit – 4 Claude Code skills for GitHub automation

I built a free skill pack for Claude Code that automates the GitHub tasks I was spending 3-4 hours a week on.

The 4 skills:
- /pr-respond: Auto-classify PR comments (MUST-FIX/ACK/DISCUSS/SKIP) and handle each appropriately. Cuts 50min review responses to 3min.
- /release-notes: Generate changelogs for both users and developers from git log + merged PRs.
- /issue-triage: Score open issues by Impact × Effort × Urgency. Writes TRIAGE.md for sprint planning.
- /repo-tour: Parse any repo's structure and generate a REPO_TOUR.md + Mermaid architecture diagram.

Install: gh skill install thinkyou0714/github-flow-kit <skill> --agent claude-code --scope user

All 4 require only GitHub CLI v2.90.0+ and Claude Code. No config files, no API keys.

GitHub: https://github.com/thinkyou0714/github-flow-kit
```

**Best posting time:** Tuesday–Thursday 9–11 AM EST

---

## X (Twitter) — Launch Thread

**Tweet 1/4 (hook):**
```
PR のレビューコメントに返答するの、毎回 50 分かかってた。

今は 3 分。

/pr-respond というコマンド 1 つで全部やってくれる。
```

**Tweet 2/4 (仕組み):**
```
仕組みはシンプル。

未解決コメントを全件読んで 4 種類に分類:
- MUST-FIX → ファイル編集 + commit
- ACK → 「了解しました」返答
- DISCUSS → 理由説明コメント
- SKIP → 無視

人間は結果を確認するだけ。
```

**Tweet 3/4 (インストール):**
```
インストールは 1 行:

gh skill install thinkyou0714/github-flow-kit pr-respond \
  --agent claude-code --scope user

30 秒で終わる。API キー設定なし。無料。

PR 対応・リリースノート・issue 優先付け・リポジトリ解析の 4 スキルあり。
```

**Tweet 4/4 (CTA):**
```
github-flow-kit として OSS 公開しました。

MIT ライセンス。フィードバック歓迎。
⭐ Star もらえると開発継続の励みになります。

→ github.com/thinkyou0714/github-flow-kit

#ClaudeCode #GitHub #DeveloperTools
```

---

## GitHub Discussions — Welcome Post

**Post title:** `Welcome! How are you using github-flow-kit?`

**Post body:**
```markdown
ようこそ！

github-flow-kit を使ってくださっている方のフィードバックを集めたいと思っています。

**教えてほしいこと:**
1. どのスキルを一番よく使っていますか？
2. 「こんな機能があったら嬉しい」というものはありますか？
3. セットアップで詰まったところはありましたか？

---

**For English speakers:**

Thanks for using github-flow-kit!

Feel free to share:
- Which skill you find most useful
- Feature requests or ideas
- Any friction in the setup process

All feedback helps prioritize the v1.1 roadmap.
```
