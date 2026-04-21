# PR Review Comment Classification Patterns

## MUST-FIX パターン（コード変更が必要）

### 明示的な変更要求
- "〜してください" / "please change" / "fix this" / "update"
- "〜にすべき" / "should be" / "needs to be"
- "間違っています" / "wrong" / "incorrect" / "bug"
- "〜を使ってください" / "use X instead" / "replace with"

### 技術的指摘
- 型エラー: "型が違う" / "wrong type" / "type mismatch"
- セキュリティ: "脆弱性" / "XSS" / "SQLインジェクション" / "exposed"
- パフォーマンス: "O(n²)" / "N+1" / "メモリリーク" / "memory leak"
- テスト不足: "テストを追加" / "add test" / "test coverage"
- エラーハンドリング: "エラー処理" / "exception handling" / "try/catch"

### 要求動詞パターン
```
(fix|change|update|modify|remove|delete|add|implement|refactor|rename|move)
(直して|変えて|修正して|削除して|追加して|実装して|リファクタして)
```

## ACK パターン（返答のみ）

### 提案・オプショナル
- "nit:" / "nitpick:" / "(nit)"
- "optional" / "任意" / "〜でもいいかも"
- "〜という選択肢もある" / "alternatively"
- "LGTM with" / "approve with"
- "minor:" / "小さな指摘"

### 称賛・確認
- "いいですね" / "good" / "nice" / "well done" / "LGTM"
- "ありがとうございます" / "thanks" / "great work"
- 質問形式でない "〜ですね" / "I see" / "understood"

## DISCUSS パターン（議論・質問）

### 疑問・設計議論
- "なぜ〜?" / "why" / "what's the reason" / "rationale"
- "どう思いますか?" / "what do you think" / "thoughts?"
- "〜は検討しましたか?" / "did you consider" / "have you thought about"
- "設計上の懸念" / "design concern" / "architecture question"

### 仕様確認
- "仕様通りですか?" / "is this intentional" / "by design?"
- "要件確認" / "requirement" / "spec"
- "影響範囲" / "impact" / "scope of change"

## SKIP パターン

### 無視してよいコメント
- emoji のみ（👍 😄 🎉 など）
- "resolved" / "解決済み" のみ
- outdated（スレッド上の返答で既に解決されているもの）
- "Already addressed" のみ

## 分類優先度

```
1. セキュリティ脆弱性の指摘      → MUST-FIX（無条件）
2. データ損失・破壊的変更の指摘  → MUST-FIX（無条件）
3. MUST-FIX パターンに一致      → MUST-FIX
4. SKIP パターンに一致          → SKIP
5. ACK パターンに一致           → ACK
6. DISCUSS パターンに一致       → DISCUSS
7. どれにも一致しない           → ACK（保守的デフォルト）
```

## 返答文テンプレート

### MUST-FIX 返答（日本語）
```
ご指摘ありがとうございます。{変更内容} を修正しました。
```

### MUST-FIX 返答（英語）
```
Thanks for the feedback. I've addressed this by {変更内容}.
```

### ACK 返答（日本語）
```
ご指摘ありがとうございます。承知しました。
```

### ACK 返答（英語）
```
Thanks for the note. Acknowledged.
```

### DISCUSS 返答（日本語）
```
{質問への回答 or 反論}。この実装にした理由は {理由} です。
ご意見があればお聞かせください。
```

### DISCUSS 返答（英語）
```
{Answer or counter-point}. The reason for this implementation is {reason}.
Happy to discuss further if needed.
```
