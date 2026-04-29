# Cloud Functions アーキテクチャ

> バージョン: 1.0  
> 最終更新: 2026-04-29

---

## 技術スタック

| 項目 | 詳細 |
|-----|------|
| ランタイム | Node.js 20 |
| 言語 | TypeScript 5.4 |
| モジュール形式 | ESModule（`"type": "module"`） |
| Firebase SDK | firebase-functions v6, firebase-admin v12 |
| 外部 API | OpenAI API（gpt-4o Vision） |
| シークレット管理 | Firebase Secret Manager |

---

## 関数一覧

| 関数名 | トリガー | 説明 | ステータス |
|------|---------|------|---------|
| `onImageUploaded` | Storage onObjectFinalized | AI ラベル認識メイン処理 | ✅ 実装済み |
| `helloWorld` | HTTPS | 開発用動作確認 | ✅ 実装済み |

---

## ディレクトリ構成

```
functions/
├── src/
│   └── index.ts       # 全関数のエントリーポイント
├── lib/               # TypeScript コンパイル出力（デプロイ対象）
├── package.json
└── tsconfig.json
```

---

## onImageUploaded（AI ラベル認識）

### トリガー

```typescript
export const onImageUploaded = onObjectFinalized(
  { secrets: [openAiKey] },
  async (event) => { ... }
);
```

- **トリガー**: Firebase Storage へのファイルアップロード完了時
- **対象パス**: `user_uploads/{userId}/{jobId}.jpg`（他パスは無視）

### 処理フロー

```
Storage にファイルアップロード
          │
          │ onObjectFinalized トリガー
          ▼
パス形式の検証（user_uploads/{userId}/{jobId}.jpg）
          │ 不一致 → return（スキップ）
          │
          ▼
Storage から画像をバッファとして取得
          │
          ▼
Base64 エンコード
          │
          ▼
OpenAI API（gpt-4o）に画像 + プロンプト送信
          │
          ├── 成功 → Firestore ai_label_jobs/{jobId} を更新
          │           { status: "success", user_id, result, updated_at }
          │
          └── 失敗 → Firestore ai_label_jobs/{jobId} を更新
                      { status: "failed", user_id, error, updated_at }
```

### OpenAI API 呼び出し

```typescript
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [
    { role: "system", content: systemPrompt },
    { role: "user", content: [{ type: "text", text: userPrompt }, { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } }] }
  ],
  max_tokens: 1024,
});
```

### AI レスポンス形式

```json
{
  "name_jp": "獺祭 純米大吟醸 45",
  "name_en": "Dassai Junmai Daiginjo 45",
  "category_name": "日本酒",
  "tags": ["旭酒造", "山口県", "純米大吟醸", "山田錦", "フルーティー"]
}
```

**カテゴリ選択肢**: 日本酒, ワイン, ビール, ウイスキー, 焼酎, リキュール, ブランデー, ジン, ウォッカ, ラム, その他

---

## シークレット管理

```typescript
const openAiKey = defineSecret("OPENAI_API_KEY");

export const onImageUploaded = onObjectFinalized(
  { secrets: [openAiKey] },
  async (event) => {
    const openai = new OpenAI({ apiKey: openAiKey.value() });
    ...
  }
);
```

- API キーは Firebase Secret Manager（`defineSecret`）で管理
- コードには直接記載しない

---

## デプロイ

### firebase.json

```json
{
  "functions": {
    "source": "functions",
    "predeploy": ["npm --prefix functions run lint", "npm --prefix functions run build"]
  }
}
```

デプロイ前に lint + TypeScript コンパイルを自動実行。

### デプロイコマンド

```bash
firebase deploy --only functions
```

---

## 今後の拡張予定

- AI レスポンスの JSON パース強化（現在は文字列レスポンスをそのまま保存）
- HTTP API エンドポイントの追加（画像アップロード経由での呼び出し対応）
- リトライロジックの実装（OpenAI API のタイムアウト・エラー対応）
- 関数のファイル分割（機能別に `src/` 配下へ）
