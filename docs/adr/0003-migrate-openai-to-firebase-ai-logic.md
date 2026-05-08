# ADR-0003: OpenAI → Firebase AI Logic（Vertex AI）への移行

> ステータス: Accepted  
> 日付: 2026-05-08  
> 決定者: プロジェクトオーナー + Claude Code

---

## 背景・問題

sakeflow-log アプリの AI 機能（ラベル認識・テイスト分析）は、OpenAI API を呼び出す Cloud Functions を経由して実装されていた。このアーキテクチャには以下の問題があった：

1. **複雑な非同期フロー**: 写真撮影後、Storage → Cloud Functions × 2 段トリガー → Firestore 更新 → Flutter ポーリングという多段処理が必要だった
2. **中間データ**: `ai_label_jobs` コレクションが調整専用の中間テーブルとして存在し、ビジネスデータとは無関係な複雑さを持ち込んでいた
3. **UX の遅延**: バックグラウンド処理のため、ユーザーが AI 解析結果を確認するまでにポーリング待機が発生していた
4. **OpenAI 依存**: Firebase エコシステム外の API キー管理と外部サービス依存
5. **Cloud Functions の維持コスト**: AI 処理のためだけに Node.js Functions インフラを維持する必要があった

---

## 決定事項

**Firebase AI Logic（`firebase_ai` パッケージ、Vertex AI バックエンド）を使用し、AI 処理をクライアント側（Flutter）に移行する。**

- パッケージ: `firebase_ai ^3.11.0`
- バックエンド: `FirebaseAI.vertexAI()`（API キー不要、Firebase Auth による認証）
- モデル: `gemini-3.1-flash-lite`

---

## 新しいアーキテクチャ

### ラベル認識フロー（`ai_label_screen.dart`）

```
旧: 写真 → Storage upload → onImageUploaded(CF) → ai_label_jobs → onAiLabelJobCompleted(CF) → tasting_notes/sakes 更新 → ポーリング

新: 写真 → firebase_ai で即時解析 → tasting_notes 作成(ready) + sakes upsert + Storage upload（並列）
```

### テイスト分析フロー（`taste_analysis_service.dart`）

```
旧: Flutter → analyzeTaste(onCall CF) → Firestore集計 → OpenAI → 結果返却

新: Flutter → AnalysisRepository（Firestore読み取り） → firebase_ai → 結果表示
```

---

## 削除した要素

| 要素 | 理由 |
|-----|------|
| `functions/src/index.ts` の AI 関数 3 本 | Firebase AI Logic に代替 |
| `ai_label_jobs` Firestore コレクション | Flutter が即時結果を受け取るため調整不要 |
| `TastingNoteStatus.processing / failed` | 非同期処理がなくなるためステータス管理不要 |
| `TastingNote.jobId` フィールド | ジョブ追跡が不要になるため |
| `cloud_functions` Flutter パッケージ | 使用箇所なくなるため |
| Cloud Functions インフラ設定（`firebase.json`） | 全関数削除のため |

---

## 選択の理由

### Firebase AI Logic を選んだ理由

1. **即時 UX**: クライアント側で AI を呼び出すことで、解析結果を数秒で表示できる。ポーリング・ステータス管理が不要
2. **コードのシンプル化**: Cloud Functions 3 本・Firestore コレクション 1 本・ステータス状態機械がすべて不要になる
3. **セキュリティ**: API キーは Firebase インフラ内に閉じており、クライアントコードに露出しない。Firebase Auth と App Check で保護
4. **Firebase エコシステム統合**: 同一プロジェクト内の Vertex AI を使用。IAM によるアクセス制御

### Vertex AI バックエンドを選んだ理由（Google AI Studio ではなく）

- プロジェクトはすでに Blaze プランで稼働中
- API キー管理が不要（サービスアカウント IAM 認証）
- `FirebaseAI.vertexAI()` は Firebase Auth と自然に統合される
- App Check によるアクセス保護が可能

### `gemini-3.1-flash-lite` を選んだ理由

- 最もコスト効率が高い Gemini マルチモーダルモデル（$0.25/M tokens）
- Vision（画像入力）と構造化出力（`responseSchema`）に対応
- 高速なレスポンス（ラベル認識・テイスト分析の用途に最適）

---

## トレードオフ・リスク

| リスク | 対策 |
|------|------|
| クライアント側の処理増加（Firestore 集計 + AI 呼び出し） | `AnalysisRepository`（既存）を再利用。Flutter のメインスレッドで実行 |
| Vertex AI の従量課金 | `gemini-3.1-flash-lite` は安価。想定ユースケースでは月数円〜数百円程度 |
| `firebase_ai` パッケージのエミュレータ非対応 | 実機・実 Firebase プロジェクトでのテストが必要 |
| App Check 未設定の場合の不正利用リスク | 本番環境では App Check の設定を推奨 |

---

## 手動作業（実装後に必要）

1. GCP コンソールで Vertex AI API を有効化
2. Firebase コンソールで Firebase AI Logic を有効化（Vertex AI バックエンド）
3. Firebase コンソールで App Check を設定（本番環境保護）
4. Secret Manager から `OPENAI_API_KEY` を削除（確認後）
5. Firebase コンソールで既存の Cloud Functions を手動削除

---

## 関連ドキュメント

- [docs/app/SPEC.md](../app/SPEC.md)
- [docs/ARCHITECTURE.md](../ARCHITECTURE.md)
- [docs/app/ai-label-recognition.md](../app/ai-label-recognition.md)
