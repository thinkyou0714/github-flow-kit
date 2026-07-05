# 多リポジトリ Git Hygiene ベストプラクティス

複数の GitHub リポジトリとローカル clone を並行運用すると、未 push、未 pull、dead remote、二重 clone、fork/canonical 混在が見えにくくなります。この文書は github-flow-kit に追加した `scripts/git-bootstrap.sh` と `scripts/repo-sync-doctor.sh` を使い、再発しやすい同期事故を予防するための運用メモです。

## 1. Git global config を bootstrap する

**なぜ:** Windows と POSIX 環境で Git の既定値が揺れると、改行差分、push 先未設定、stale branch、merge commit 混入が起きます。global config は個人端末ごとに一度そろえるのが安全です。

**推奨値:**

| key | value | 理由 |
|---|---|---|
| `core.longpaths` | `true` | Windows の長い path で checkout や npm 系の深い tree が壊れにくくなります。 |
| `core.autocrlf` | `false` | 改行は Git の自動変換ではなく `.gitattributes` で制御します。jj リポジトリ方針 `C:/work/WORKSPACE_PATHS.md` とも整合します。 |
| `push.autoSetupRemote` | `true` | 新規 branch の初回 push で upstream を自動設定します。 |
| `fetch.prune` | `true` | 消えた remote branch の追跡 refs を fetch 時に掃除します。 |
| `pull.ff` | `only` | pull 時に意図しない merge commit を作らないようにします。 |
| `init.defaultBranch` | `main` | 新規 repo の初期 branch 名を統一します。 |

**コマンド:**

```bash
bash scripts/git-bootstrap.sh --check
bash scripts/git-bootstrap.sh --apply
bash scripts/git-bootstrap.sh --selftest
```

`--check` は差分表示だけで変更しません。`core.editor` は個人差が大きいため、この bootstrap では触りません。

## 2. `.gitattributes` で EOL を正規化する

**なぜ:** Windows では `LF will be replaced by CRLF` の churn が起きやすく、実装差分と改行差分が混ざるとレビューが困難になります。リポジトリ内の改行方針は `.gitattributes` を正本にします。

**コマンド:**

```bash
git diff --check
git add --renormalize <path>
```

通常運用では `.gitattributes` を置くだけで十分です。既存追跡済みファイルへ一括反映したい場合だけ、対象 path を明示して `git add --renormalize` を実行します。

## 3. `push.autoSetupRemote` で upstream を自動設定する

**なぜ:** upstream がない branch は `git pull` や `git status -sb` の意味が弱くなり、未 push の検知も人間依存になります。初回 push 時に upstream が設定されると、以後の ahead/behind が安定して読めます。

**コマンド:**

```bash
bash scripts/git-bootstrap.sh --apply
git push
git status -sb
```

この repo の運用では push は人間がレビュー後に行います。ツールは状態を整えますが、公開操作は明示的に分けます。

## 4. `fetch.prune` で stale branch を掃除する

**なぜ:** GitHub 側で削除済みの branch がローカル追跡 refs に残ると、まだ作業対象があるように見えます。定期的な prune は棚卸しのノイズを減らします。

**コマンド:**

```bash
bash scripts/git-bootstrap.sh --apply
git fetch --prune
git branch -r
```

global の `fetch.prune=true` が入っていれば、通常の `git fetch` でも stale remote-tracking branch が掃除されます。

## 5. `repo-sync-doctor.sh --probe` を定期実行する

**なぜ:** 通常の高速 scan は local metadata だけを見るため、GitHub 側で消えた repository や権限切れ remote は検出できません。`--probe` は `git ls-remote origin` を timeout 付きで実行し、dead remote を分類します。

**コマンド:**

```bash
bash scripts/repo-sync-doctor.sh --root C:/work --md
bash scripts/repo-sync-doctor.sh --root C:/work --exclude node_modules --probe --md
```

毎日の確認は `--probe` なしで高速に、週次や棚卸し時だけ `--probe` ありで実行するのが現実的です。

## 6. dead-remote と二重 clone を棚卸しする

**なぜ:** dead remote は「もう GitHub に反映できない local 作業」を抱える原因になります。二重 clone は片方だけが進み、もう片方が古いまま残る原因になります。

**コマンド:**

```bash
bash scripts/repo-sync-doctor.sh --root C:/work --probe --md
git -C <repo> remote -v
git -C <repo> status -sb
```

`E:dead-remote` は remote URL、GitHub 側の repository 存在、権限を確認します。同名 repo が複数出る場合は、canonical と作業用 clone のどちらを残すかを決めます。

## 7. fork と canonical を分離する

**なぜ:** `thinkyou0714` 配下を canonical として扱う場合、fork や別 owner の origin を同じ一覧で active 扱いすると、push 先を間違えるリスクがあります。`repo-sync-doctor.sh` は origin owner が `thinkyou0714` 以外なら `F:fork` に分類します。

**コマンド:**

```bash
bash scripts/repo-sync-doctor.sh --root C:/work --md
git -C <repo> remote get-url origin
git -C <repo> remote set-url origin git@github.com:thinkyou0714/<repo>.git
```

fork を残す場合は、path 名や親ディレクトリで canonical clone と明確に分けます。

## 8. 並列セッションは worktree と additive-only を守る

**なぜ:** 複数 agent や複数 terminal が同じ checkout を同時に編集すると、未 commit 作業を上書きしやすくなります。並列作業は worktree を分け、既存変更を戻さず追加的に進めるのが安全です。

**コマンド:**

```bash
git worktree add C:/work/_worktrees/<repo>-<task> -b feat/<task>
git -C C:/work/_worktrees/<repo>-<task> status -sb
bash scripts/repo-sync-doctor.sh --root C:/work --exclude node_modules --md
```

`B:carve-out` は dirty かつ 24 時間以内に変更された repo です。これは並列編集中の可能性が高いため、上書きや reset ではなく、作業者と状態を確認してから進めます。
