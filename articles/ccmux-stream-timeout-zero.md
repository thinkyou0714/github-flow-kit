---
title: "SSH が切れても Claude Code が止まらない環境を作った — ccmux v1.0"
emoji: "⚡"
type: "tech"
topics: ["claudecode", "tmux", "cli", "ssh", "開発環境"]
published: false
---

## 俺の Claude Code は止まらない。

8 時間前に仕掛けた実装タスクが、今もバックグラウンドで動いている。

SSH の接続が切れた。ルーターが再起動した。スマホで外出した。それでも Claude は止まっていない。

戻ってきたら、こう打つだけだ。

```bash
ccmux attach feat/auth
```

それだけで、8 時間前の会話コンテキストが全部そこにある。

---

## なぜ Claude Code は止まるのか

Claude Code を使い込むと、必ずこのエラーに出会う。

```
API Error: Stream idle timeout - partial response received
```

Claude が長考している。コードを読み込んでいる。複雑な実装を考えている。その「沈黙の時間」に、HTTP ストリームが死ぬ。

原因はシンプルだ。**ルーターの NAT タイムアウト（60〜300 秒）が、Anthropic API への HTTP ストリームを強制終了する**。

Claude 自体の問題ではない。Anthropic のサーバーの問題でもない。純粋にネットワーク層の問題だ。

特に酷いのが、こういうケース:

- SSH 経由でリモートサーバーに接続して作業している
- Wi-Fi が不安定な環境（スマホのテザリング・カフェ・移動中）
- 自宅の NucBox に Tailscale 経由で接続している

一度タイムアウトすると、それまでのセッションが消える。Claude Code の `--resume` フラグで拾い直しできることもあるが、コンテキストが中途半端になるケースもある。何より、**止まるたびに集中が切れる**。

---

## 解決策として「全部やった」

`CLAUDE_CODE_STREAM_TIMEOUT=0` という環境変数を設定すれば、組み込みのタイムアウトは切れる。これは Anthropic が公式で言及している。

だが、それだけでは不十分だった。

ルーター側の NAT タイムアウトは、この変数では止まらない。SSH 接続が切れた瞬間に、tmux なしで動かしていたプロセスは全滅する。

だから、**4 層で防御する**仕組みを作った。

| 層 | メカニズム | 役割 |
|---|---|---|
| L1 | `CLAUDE_CODE_STREAM_TIMEOUT=0` | 組み込みタイムアウトを完全無効化 |
| L2 | keepalive デーモン (SIGWINCH/120 秒) | Claude のアイドル検出を欺く |
| L3 | `ServerAliveInterval 60` (SSH 設定) | SSH トンネルを維持 |
| L4 | tmux セッション | SSH 切断後もプロセスを生かす |

この 4 層を、**自動で全部セットアップして管理するのが `ccmux`** だ。

---

## ccmux とは何か

**Claude Code Multiplexer** — 略して `ccmux`。

一言で言うと、「Claude Code のすべてのセッションを tmux でラップして、環境変数と keepalive を自動注入する CLI ツール」だ。

インストールは 1 コマンド:

```bash
npm install -g ccmux
```

使い方も単純だ:

```bash
# セッションを作る (tmux window + git worktree が自動作成される)
ccmux new feat/auth

# どこからでも再接続
ccmux attach feat/auth

# アクティブセッション一覧
ccmux list

# 終了
ccmux close feat/auth
```

これだけで、上で書いた 4 層防御が全部有効になる。

---

## 内部構造を解説する

### L2: keepalive デーモンの仕組み

Claude Code は、ターミナルサイズ変更シグナル (`SIGWINCH`) をウィンドウリサイズとして解釈する。これを 120 秒ごとに送り続けることで、「ユーザーがアクティブに操作している」とアイドル検出器を思わせる。

```typescript
// keepalive.ts (簡略版)
const pid = parseInt(readFileSync(pidFile, "utf-8"));
setInterval(() => {
  process.kill(pid, "SIGWINCH");
}, intervalSec * 1000);
```

### L4: git worktree による作業分離

`ccmux new feat/auth` は単に tmux を起動するだけではない。**`git worktree add`** で、そのセッション専用の作業ディレクトリを独立して作成する。

```
~/worktrees/
  feat-auth/      ← ccmux new feat/auth が作った
  feat-payment/   ← ccmux new feat/payment が作った
  fix-bug-123/    ← ccmux new fix/bug-123 が作った
```

**複数の Claude Code セッションが同時に動いても、ファイルが干渉しない**。feat/auth の変更が feat/payment に影響しない。

マージは人間がやる。Claude が各 worktree でコードを書き、人間が最終的に統合する。このフローが一番安全だと思っている。

---

## 1 分でセットアップ

```bash
# 1. インストール
npm install -g ccmux

# 2. 環境チェック
ccmux doctor

# 3. 初期設定 (ウィザード形式)
ccmux init

# 4. 最初のセッションを作る
ccmux new test-session

# 5. セッションを切り離す
# Ctrl+B D

# 6. 再接続
ccmux attach test-session
```

---

## スマホ・タブレットからの作業を前提に設計した

ccmux を作った直接のきっかけは、**スマホの Termius から NucBox M7 (自宅の mini PC) に SSH して Claude Code を使う** というワークスタイルだ。

自宅のデスクに座っていなくても、電車の中でも、カフェでも、Claude にコードを書かせたかった。

そのためには:
- SSH が切れても作業が消えない (tmux)
- どのデバイスからでも `ccmux attach <name>` で復帰できる (セッション管理)
- スマホの 4G が不安定でも keepalive が維持する (SIGWINCH + ServerAliveInterval)

この 3 つが全部揃って、初めて「スマホ作業」が現実的になった。

### 推奨構成 (NucBox + Tailscale + Termius)

```
スマホ (Termius)
    ↓ Tailscale VPN
NucBox M7 (自宅、24h 電源 ON)
    → WSL2 (Ubuntu)
        → tmux (ccmux が管理)
            → Claude Code (複数セッション)
```

SSH 設定 (`~/.ssh/config`):

```
Host nucbox
  HostName 100.x.x.x
  User rikuto
  ServerAliveInterval 60
  ServerAliveCountMax 10
```

WSL2 の `.bashrc`:

```bash
export CLAUDE_CODE_STREAM_TIMEOUT=0
export CLAUDE_CODE_AUTO_COMPACT_WINDOW=0.45

if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
  tmux attach-session -t ccmux 2>/dev/null || tmux new-session -s ccmux
fi
```

---

## v1.0 に入っているもの

```
ccmux new <name>            tmux window + git worktree + keepalive でセッション作成
ccmux attach [name]         セッションに接続 (シェルインジェクション対策済み)
ccmux list                  セッション一覧 (--format human|json|names)
ccmux close <name>          セッション終了 + worktree 削除 (dirty guard あり)
ccmux doctor                依存チェック (tmux/claude-code/git バージョン確認)
ccmux init                  対話式セットアップウィザード
ccmux daemon start          バックグラウンドモニター (切れたセッションを自動復旧)
ccmux cost                  セッション別コスト (ccusage 連携、USD/JPY 表示)
ccmux install-completion    シェル補完インストール (bash/zsh/fish)
```

---

## よくある質問

**Q: macOS で動きますか？**

動く。tmux が入っていれば (`brew install tmux`) 同じように動作する。`ccmux doctor` を走らせて全部緑になれば準備完了。

**Q: WSL2 以外の Linux でも使えますか？**

使える。Ubuntu / Debian / Fedora など、tmux と Node.js が入れば動く。

**Q: git worktree が汚れた状態で `ccmux close` するとどうなりますか？**

dirty guard が働いて、確認なしでは削除しない。`ccmux close <name> --force` で強制削除できる。

---

## 試してみる

```bash
npm install -g ccmux
ccmux doctor
ccmux init
```

GitHub: [thinkyou0714/think-you-lab/apps/ccmux](https://github.com/thinkyou0714/think-you-lab/tree/main/apps/ccmux)

⭐ 便利だと思ったら Star をもらえると嬉しいです。
