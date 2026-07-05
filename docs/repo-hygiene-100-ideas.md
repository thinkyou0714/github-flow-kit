# Repo Hygiene & Reflection — 100 Ideas (2026-07-05)

多リポジトリ（`thinkyou0714` 27 repo / ローカル 44 checkout）の GitHub↔ローカル反映を健全化する 100 案。
姉妹版: per-repo 改善は `~/.claude/docs/cross-repo-improvement-catalog-2026-07-04.md`（4 repo×100項）。
本書は **reflection/sync 軸**に特化。各案: `[tag]` = safe-auto / judgment / decision、`{st}` = done(本タスク実施) / plan(近日) / backlog。
ランク根拠: Impact(反映事故の防止・可視性) × Effort × Risk。

## A. Git global config bootstrap（基盤・最高 ROI）
1. `push.autoSetupRemote=true` — 新規 branch push 時に upstream 自動設定。upstream 未設定バグ(RC3)の恒久解。[safe-auto]{done: git-bootstrap.sh}
2. `fetch.prune=true` — 消えた remote branch を fetch 時に自動掃除。stale ref 累積を防ぐ(RC8)。[safe-auto]{plan}
3. `core.longpaths=true` — Windows 260 文字制限回避。深いパスの clone/checkout 失敗を防ぐ。[safe-auto]{plan}
4. `core.autocrlf=false` + `.gitattributes` — EOL は宣言的制御。jj repo 方針と整合。[safe-auto]{done}
5. `pull.ff=only` — 誤マージコミット防止。diverged は明示 rebase を強制。[safe-auto]{plan}
6. `init.defaultBranch=main` — 新規 repo の branch 名統一。[safe-auto]{plan}
7. `rerere.enabled=true` — 繰返す conflict 解決を記録・再利用。[safe-auto]{backlog}
8. `merge.conflictStyle=zdiff3` — conflict の可読性向上。[safe-auto]{backlog}
9. `fetch.parallel` / `submodule.fetchJobs` — 多 remote fetch 高速化。[safe-auto]{backlog}
10. `credential.helper`(manager) 確認 — token 期限切れによる push 失敗の予防。[judgment]{backlog}

## B. Upstream / branch tracking 衛生
11. 全 local branch に upstream 設定監査（`for-each-ref` で gone/未設定検出）。[safe-auto]{done: doctor}
12. `--set-upstream` 一括適用スクリプト（clean branch のみ）。[safe-auto]{done}
13. upstream が `[gone]` の branch を検出しレポート。[safe-auto]{plan: doctor --probe}
14. detached HEAD の checkout 検出・警告。[safe-auto]{backlog}
15. `origin/HEAD` シンボリック ref の未設定修復（`remote set-head origin -a`）。[safe-auto]{backlog}
16. tracking mismatch（local main → origin/master 等）検出。[judgment]{backlog}
17. 長期未 push の ahead branch を「反映漏れ候補」として日次通知。[safe-auto]{plan}
18. merged 済 local branch の GC 候補提示（`branch --merged`）。[judgment]{backlog}
19. branch 命名規約 lint（feat/ fix/ chore/ 等）。[judgment]{backlog}
20. WIP branch の TTL 監査（N 日超で確認）。[judgment]{backlog}

## C. Dead-remote / inventory 棚卸し
21. `git ls-remote` probe で 404 remote 検出（lab-os, n8n-gmail-vault 等）。[safe-auto]{done: doctor --probe}
22. リモート実在・ローカル未クローンの棚卸し（lab-public 等 4 repo）。[safe-auto]{done: report}
23. ローカル→死んだ remote 参照の一覧化と退避提案。[judgment]{done: report §2}
24. 改名 remote の検出（redirect 追従: nextjs-boilerplate→tyl-monorepo）。[judgment]{done}
25. 同一 remote の二重 clone 検出（public-docs, tyl-monorepo）。[safe-auto]{done: doctor 分類}
26. fork と canonical の分離タグ付け（onyx, supabase-grafana）。[safe-auto]{done: 分類F}
27. archive/worktree の反映対象からの自動除外。[safe-auto]{done: 分類C}
28. remote URL の `.git` 有無統一。[safe-auto]{done: lab-infra-n8n}
29. HTTPS/SSH remote 方式の統一監査。[judgment]{backlog}
30. `gh repo list --archived` 込みで真の repo 総数を突合。[safe-auto]{done}

## D. Secret / 公開安全（最重要リスク）
31. push 前 gitleaks ゲート（本タスクで 5 repo に適用、findings 0）。[safe-auto]{done}
32. PUBLIC repo への push 時は secret-scan 必須ポリシー。[safe-auto]{done: RB5}
33. GitHub secret scanning + push protection 有効化（gh-repo-security-audit 連携）。[decision]{plan}
34. `.env`/`.env.local` の tracked 混入監査（lab-inbox-bot .env.example 確認済）。[safe-auto]{done}
35. pre-push hook に secret-scan 組込み（全 repo 共通）。[judgment]{plan}
36. 履歴内 secret の検出（gitleaks full-history）。[judgment]{done: detect --source}
37. obsidian-vault 等 PII 含む repo の PRIVATE 維持確認。[safe-auto]{done: PRIVATE}
38. commit 前 `preflight_secrets_check.py` hook 活用。[safe-auto]{backlog}
39. token scope 最小化（現 gho は delete_repo 保持 — 要検討）。[decision]{backlog}
40. `.gitignore` に secret ファイルパターン共通テンプレ配布。[safe-auto]{backlog}

## E. Reflection 自動化・可視性
41. `repo-sync-doctor.sh` を再発防止の常設ツール化（github-flow-kit）。[safe-auto]{done}
42. doctor の日次スケジュール実行 + 未反映 0 監視。[judgment]{plan}
43. 未反映 A 件数を数値ダッシュボード化。[safe-auto]{plan}
44. markdown レポート自動生成 → `_reports/`。[safe-auto]{done}
45. behind 過多 repo の pull --ff-only 一括同期。[safe-auto]{done: 6 repo}
46. ahead branch の push 候補一覧生成。[safe-auto]{done}
47. carve-out（並列編集中 tree）の自動検出（mtime 24h）。[safe-auto]{done: 分類B}
48. reflection 差分の Slack/通知連携。[judgment]{backlog}
49. multi-device 間の同期状態突合（session-brief）。[judgment]{backlog}
50. doctor 出力を CI artifact 化。[judgment]{backlog}

## F. .gitattributes / EOL 衛生
51. 正本 `.gitattributes` を全 active repo へ rollout（G042/G051/G065/G071/G078 完遂）。[safe-auto]{plan}
52. `*.ps1/*.cmd` は CRLF 維持（実行系整合）。[safe-auto]{done: template}
53. `git add --renormalize` を専用コミットで実施（差分大のため人間）。[judgment]{backlog}
54. `check-line-endings.{sh,ps1}` を pre-commit/CI に組込み。[judgment]{plan}
55. binary 種別の EOL 変換除外明記。[safe-auto]{done: template}
56. `.editorconfig` の全 repo 配布（codex-toolkit を基準）。[safe-auto]{backlog}
57. CRLF churn を起こす追跡済ファイルの監査。[safe-auto]{backlog}
58. jj repo の autocrlf=false ローカル維持確認。[safe-auto]{done}
59. 新規 repo テンプレに .gitattributes 同梱。[safe-auto]{backlog}
60. EOL 監査の月次スケジュール。[judgment]{backlog}

## G. Branch protection / governance（GitHub 側）
61. default branch protection（PR 必須・force-push 禁止）。[decision]{plan}
62. Actions の PR 自己承認権限監査（gh-pr-perm-audit）。[safe-auto]{plan: skill wired}
63. OpenSSF 準拠 repo 監査（gh-repo-security-audit）。[safe-auto]{plan: skill wired}
64. GITHUB_TOKEN の既定 read-only 化。[decision]{backlog}
65. allowed-actions ポリシー（pinned SHA）。[decision]{backlog}
66. Dependabot alerts 有効化。[judgment]{backlog}
67. CODEOWNERS 配置。[judgment]{backlog}
68. PR template 統一（.github org repo）。[safe-auto]{backlog}
69. required status checks 設定。[decision]{backlog}
70. tag protection（release tag）。[judgment]{backlog}

## H. Dedup / archive doctrine
71. winner/loser dedup 規約の文書化（-lab-loser 命名）。[judgment]{plan}
72. archive-over-delete 原則の runbook 化。[safe-auto]{plan}
73. dirty-tree 保全パターン（patch + tgz 退避）の標準化。[safe-auto]{done: 参照}
74. stale clone（nextjs-boilerplate 等）の削除候補通知。[judgment]{done: report §5}
75. `_home-consolidated` の整理完了確認（clean+pushed → archive）。[judgment]{done: 確認}
76. remote-less local repo（clawd）の cold-storage 保全。[decision]{done: 保全指定}
77. branch-gc manifest（restore 手順付き）の定期生成。[safe-auto]{backlog}
78. 重複 checkout の canonical 指定を WORKSPACE_PATHS に追記。[judgment]{plan}
79. archive フォルダの命名日付規約統一。[safe-auto]{backlog}
80. 退避前 snapshot（pre-prune）の自動取得。[safe-auto]{backlog}

## I. Worktree / 並列セッション衛生
81. worktree = 1 Claude=1 worktree 規約遵守（lab-os/docs/worktree.md）。[safe-auto]{done: 参照}
82. 手動タスク worktree の owned 扱い（auto-reap 除外）。[safe-auto]{done: 分類C}
83. 並列編集 tree への additive-only 原則。[safe-auto]{done}
84. worktree の branch push 済確認後のみ削除。[judgment]{backlog}
85. `parallel-dev.ps1 -Doctor` による worktree 健全性チェック。[safe-auto]{backlog}
86. 並列 claude.exe cap 3 の監視（reap-claude）。[judgment]{backlog}
87. worktree base=fresh（origin/default 起点）の徹底。[safe-auto]{done: 設定}
88. n8n 内 worktree scheme と _worktrees の分離明記。[judgment]{done: report}
89. 共有 tree での reset/restore/checkout 禁止。[safe-auto]{done}
90. worktree gitlink 破損の検出。[judgment]{backlog}

## J. SSoT / lab-os 特殊対応
91. lab-os（remote 404）の GitHub 再作成 or ローカル維持の判断。[decision]{RB1}
92. lab-os の定期 backup（tgz snapshot 存在確認）。[safe-auto]{done: 確認}
93. mcp-audit タスクの書込み先を canonical へ再ポイント検討。[decision]{backlog}
94. jj repo（lab-os, think-you-lab）の jj-status 監視。[safe-auto]{done: 既存 task}
95. SSoT→downstream 投影の drift-guard（既存 tools）。[safe-auto]{backlog}
96. managed-roots（n8n=tyl, nextjs）定義の最新化。[judgment]{backlog}
97. SSoT テンプレ（requirement/spec/adr/pr）の活用。[judgment]{backlog}
98. lab-os を private GitHub へ復元し jj-git 併用。[decision]{RB1}
99. requirements-os の session-brief 同期ツール新設。[judgment]{backlog}
100. reflection ポリシー（本書）を lab-os ADR 化して恒久ルール化。[decision]{plan}

---
## 集計
- **本タスク実施(done)**: 約 34 案（config 一部, upstream, inventory, secret gate, reflection 6+5, 分類）。
- **近日(plan)**: 約 20 案（config 残り, .gitattributes rollout, gh 監査 wiring, branch protection）。
- **backlog**: 約 46 案。
- **要判断(decision)**: RB1(lab-os), secret push-protection, token scope, branch protection 方式。
