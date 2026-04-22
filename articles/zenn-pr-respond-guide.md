---
title: "PR レビュー対応を 3 分で終わらせる gh skill: pr-respond"
emoji: "🤖"
type: "tech"
topics: ["github", "claudecode", "productivity", "cli", "automation"]
published: false
---

## PR レビュー対応、こんなに時間かかってませんか?

1 本の PR に対してレビューコメントが 5〜10 件ついた時の対応フロー、こんな感じではないでしょうか。

1. コメントを 1 件ずつ読む (5 分)
2. どのファイルを直すか探す (5 分)
3. コードを修正する (20 分)
4. 修正内容を確認する (5 分)
5. コミットメッセージを書く (5 分)
6. レビュアーに返答コメントを書く (10 分)

**合計: 約 50 分。**

これを `/pr-respond` は **3〜5 分** に短縮します。

---

## pr-respond とは

`pr-respond` は [github-flow-kit](https://github.com/thinkyou0714/github-flow-kit) に含まれる Claude Code スキルです。

PR の未解決レビューコメントを全件読んで、次の 4 種類に分類し、それぞれに自動対応します。

| 分類 | 基準 | 対応 |
|---|---|---|
| **MUST-FIX** | コード修正を明確に要求 ("fix", "change", "wrong" 等) | ファイル編集 + commit + 返答 |
| **ACK** | 確認・nitpick・任意の提案 ("nit:", "optional" 等) | 「了解しました」返答のみ |
| **DISCUSS** | 設計議論・質問 ("why did you...?") | 説明 or 反論コメント返答 |
| **SKIP** | 解決済み・絵文字のみ | 無視 |

---

## インストール

前提: GitHub CLI v2.90.0 以上

```bash
gh --version  # v2.90.0+ であることを確認

gh skill install thinkyou0714/github-flow-kit pr-respond \
  --agent claude-code \
  --scope user
```

インストールは 30 秒で完了します。API キー設定は不要です。

---

## 基本的な使い方

レビューコメントがついた PR のブランチにいる状態で:

```bash
/pr-respond
```

これだけです。Claude Code が自動的に未解決コメントを取得し、分類・対応します。

### オプション

```bash
/pr-respond --pr 42        # PR 番号を直接指定
/pr-respond --dry-run      # 実行せず、やること一覧を表示
/pr-respond --auto-push    # commit 後に自動で git push
```

---

## 実際の動作例

### Before: レビューコメント 5 件

```
@reviewer: この関数の引数の型が string じゃなくて number にすべきでは？
@reviewer: nit: 変数名 tmp より desc の方が分かりやすい
@reviewer: なぜここで sleep(1000) しているの？
@reviewer: この正規表現、/\d+/ で十分では？
@reviewer: LGTM! 後は好みで
```

### After: `/pr-respond` 実行後

```
✅ PR #42 — 5件対応完了

  MUST-FIX : 2件 (コミット済み)
  ACK      : 2件 (返答済み)
  DISCUSS  : 1件 (返答済み)
  SKIP     : 0件

📋 人間が確認すること:
  - src/utils.ts の型変更を確認してください
  - sleep(1000) の説明コメントを追加しました

次のアクション: git push してレビュアーに通知してください
```

実行時間: **約 3 分**。

---

## --dry-run で安全に確認

初めて使う場合は `--dry-run` で実際に何が変わるか確認してから実行できます。

```bash
/pr-respond --dry-run
```

出力例:

```
[DRY RUN] 以下の変更を行う予定です:

MUST-FIX:
  src/utils.ts:42 — 引数の型を string → number に変更
  src/utils.ts:67 — 正規表現を /\d+/ に簡略化

コミットメッセージ (予定):
  fix: address PR #42 review comments
  - 引数型を number に修正
  - 正規表現を簡略化

実際に実行するには --dry-run なしで再実行してください。
```

---

## セキュリティ制約

`pr-respond` は以下のファイルを**絶対に変更しません**:

- `**/migrations/**` (DB マイグレーション)
- `**/.env*` (環境変数)
- `**/auth/**` (認証ロジック)
- `**/.github/workflows/**` (CI/CD)

また、1 回の実行で 3 ファイル超・50 行超の変更が必要な場合は確認を求めます。

---

## コスト

1 PR あたり **約 ¥10〜40** (claude-sonnet-4-6 使用、Claude Code の API 使用量として課金)。

コメント 5 件の PR で平均 ¥15 程度です。レビュアーとのやり取りを 1 往復減らせれば十分に元が取れます。

---

## まとめ

| Before | After |
|---|---|
| 50 分/PR | 3〜5 分/PR |
| コメントを 1 件ずつ手動対応 | 全件自動分類・対応 |
| 返答を書くのが面倒で後回し | コメントと同時に返答まで完了 |

PR レビュー対応の「めんどくさい」をゼロにしましょう。

```bash
gh skill install thinkyou0714/github-flow-kit pr-respond \
  --agent claude-code \
  --scope user
```

⭐ 便利だと思ったら [Star をもらえると嬉しいです](https://github.com/thinkyou0714/github-flow-kit)。Stars が増えると開発継続の励みになります。

---

## 関連スキル

github-flow-kit には他に 3 つのスキルがあります:

- `/release-notes` — git log からリリースノートを自動生成
- `/issue-triage` — issue バックログを Impact×Effort で優先度付け
- `/repo-tour` — 初めてのリポジトリを 2 分で把握

```bash
# 4スキル一括インストール
for skill in pr-respond release-notes issue-triage repo-tour; do
  gh skill install thinkyou0714/github-flow-kit $skill --agent claude-code --scope user
done
```
