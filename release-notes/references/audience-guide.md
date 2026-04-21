# Release Notes Audience Guide

## ユーザー向け（--type user）の書き方原則

### 基本ルール
1. **「何ができるようになったか」で書く** — 実装の詳細は書かない
2. **ですます調で統一**（日本語の場合）
3. **技術用語は最小限** — PR/commit/refactor などの開発語は使わない
4. **具体的な操作を示す** — 「設定 > 表示からテーマを変更できます」

### NG → OK 変換例

| NG（開発者目線） | OK（ユーザー目線） |
|---|---|
| Implement dark mode feature | ダークモードに対応しました |
| Refactor authentication module | ログインの安定性が向上しました |
| Fix N+1 query on dashboard | ダッシュボードの表示速度が改善されました |
| Add CSV export endpoint | データをCSVでダウンロードできるようになりました |
| Bump dependency versions | セキュリティを強化しました |
| fix: handle null in processData | データ処理のエラーを修正しました |

### Breaking Changes の書き方

```markdown
### ⚠️ 重要な変更（アップデート前にご確認ください）

**設定ファイルの形式が変わりました**
v1.2 以前をお使いの方は、以下の手順で移行が必要です：

1. `config.json` を開く
2. `"auth_token"` を `"api_key"` に変更する
3. アプリを再起動する

詳細: [移行ガイド](docs/migration.md)
```

### リード文の書き方

リード文は「このリリースのテーマ」を1文で。

```
良い例: 「このリリースでは、PR レビュー対応の速度を大幅に改善しました。」
悪い例: 「バグ修正と機能追加を行いました。」（具体性がない）
悪い例: 「SKILL.md の frontmatter を refactor しました。」（開発用語）
```

---

## 開発者向け（--type dev）の書き方原則

Conventional Commits 形式に従い、PR 番号とコミットハッシュを含める。

```markdown
## [1.3.0] — 2026-04-21

### Features
- add dark mode toggle in settings (#38, @contributor-a)
- implement CSV export API endpoint (GET /api/export/csv) (#35)

### Bug Fixes
- fix N+1 query on dashboard page (#33)
- resolve authentication token refresh race condition (#29)

### Performance
- optimize dashboard query: 2x speedup via index addition

### BREAKING CHANGES
- `config.auth_token` renamed to `config.api_key`
  Migration: update config.json key name and restart
```

---

## バージョン命名の判断基準

| 変更の種類 | バンプ | 例 |
|---|---|---|
| API 削除・引数変更・互換性破壊 | MAJOR | 1.x.x → 2.0.0 |
| 新機能追加（後方互換あり） | MINOR | 1.2.x → 1.3.0 |
| バグ修正・セキュリティパッチのみ | PATCH | 1.2.3 → 1.2.4 |
| Breaking + 新機能 | MAJOR | 常に MAJOR を優先 |

---

## 内部変更のフィルタリング基準

ユーザー向けリリースノートから**除外する**べき変更:

- `chore:` / `ci:` / `refactor:` / `test:` / `docs:` prefix の commit
- 依存バージョンバンプ（セキュリティパッチを除く）
- コードのリファクタリング（ユーザー動作に変化なし）
- テストの追加・修正
- 開発環境設定の変更

ユーザー向けリリースノートに**含める**べき変更:

- `feat:` / `fix:` / `perf:` / `security:` prefix
- ユーザーに見える UI/UX の変更
- パフォーマンスの体感できる改善
- セキュリティ修正（詳細は伏せつつ「セキュリティを強化」と記載）
