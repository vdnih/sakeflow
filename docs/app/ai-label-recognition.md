# AI ラベル認識機能 設計ドキュメント（Firebase 構成）

> バージョン: 1.1（2026-04-29 更新: 実装実態に合わせて整理）  
> 機能 ID: F01  
> 実装ファイル: `functions/src/index.ts`（`onImageUploaded`）, `app/lib/ai_label_screen.dart`

## 1. 概要

- ユーザーが日本酒、ワイン、ビール、ウイスキー等、さまざまなお酒のラベル画像をアップロード
- Firebase Storage に保存 → Storage トリガーで Cloud Functions 起動 → Functions が OpenAI API（**gpt-4o** Vision）で画像認識
- 結果（銘柄名・カテゴリ・タグ等）を Firestore に格納
- クライアントは Firestore リアルタイムリスナーで結果を取得（ポーリング推奨から変更）
- お酒の種類は AI が自動判別し、必要に応じてユーザーが修正可能

## 2. アーキテクチャ概要

- 画像アップロードAPI（Storage直PUT or Functions経由）でFirebase Storageに画像保存
- StorageトリガーでCloud Functions起動
- FunctionsがOpenAI API（gpt-4.1 Vision等）を呼び出し、認識結果（銘柄名・種類・スペック等）をFirestoreに保存
- クライアントはジョブIDで結果取得APIをポーリング
- お酒の種類ごとに記録・検索・履歴機能でフィルタ可能

## 3. シーケンス図（テキスト）

1. クライアント → Firebase Storage: 画像アップロード
2. Storage → Cloud Functions: StorageトリガーでFunctions起動
3. Functions → OpenAI API: 画像認識リクエスト
4. Functions → Firestore: 結果保存
5. クライアント → Firestore/Functions: 結果取得リクエスト

## 4. API設計

| API名                | メソッド | パス                                 | 概要                     | ステータス |
|----------------------|----------|--------------------------------------|--------------------------|------------|
| 画像アップロード      | POST     | Storage直PUT or /ai/recognize-label  | Storageに画像をアップロードし、ジョブIDを返す | 未実装     |
| 判別結果取得         | GET      | /ai/recognize-label/{job_id}         | Firestoreから判別結果を取得 | 未実装     |

- 画像アップロードはStorage直PUT推奨（Firebase SDK利用）
- 判別結果には「お酒の種類（type）」フィールドを含める

## 5. Cloud Functions処理フロー

- Storageに画像がアップロードされる
- StorageトリガーでCloud Functionsが起動
- Functionsが画像を取得し、OpenAI API（gpt-4.1 Vision等）にリクエスト
- OpenAIのレスポンス（銘柄名・種類・スペック・信頼度など）をパース
- Firestoreに「ジョブID」「種類（type）」「結果」「ステータス（完了/失敗）」を保存

## 6. Firestore設計（概要）

コレクション: `ai_label_jobs`

| job_id (docID) | status   | result                                   | image_url | created_at        | updated_at        |
|---------------|----------|------------------------------------------|-----------|-------------------|-------------------|
| uuid          | running  | null                                     | gs://...  | 2024-06-01T12:00Z | 2024-06-01T12:00Z |
| uuid          | success  | `{brand, brewery, tags}` (Firestore map) | gs://...  | 2024-06-01T12:00Z | 2024-06-01T12:01Z |
| uuid          | failed   | null                                     | gs://...  | 2024-06-01T12:00Z | 2024-06-01T12:01Z |

※詳細なスキーマ設計・フィールド説明・サンプル・インデックス・セキュリティルールは「10. Firestoreジョブ管理スキーマ設計」を参照。

## 7. UI/UX設計

- 画像アップロード後は「判別中...」の進捗表示
- 判別完了時に「お酒の種類」「銘柄名」「スペック」等を表示
- 必要に応じてユーザーが「種類」や「銘柄名」を修正可能
- 再試行・手動入力への導線も用意
- 検索・履歴画面で「お酒の種類」ごとにフィルタ可能

## 8. 今後の拡張性

- 新しいお酒カテゴリ（リキュール、焼酎等）の追加も容易
- AIモデルのバージョン管理・精度向上
- モバイル対応（カメラ連携強化）
- Firestoreのリアルタイムリスナーによる進捗通知
- 他サービス（酒データベース等）との連携

## 9. ジョブ ID の管理

- ジョブ ID は UUID を**クライアント側で生成**し、Storage アップロード時および Firestore ドキュメント作成時に同じ ID を利用する。
- 画像は `user_uploads/{userId}/{jobId}.jpg` のパスで Firebase Storage にアップロードする（Cloud Functions の `onImageUploaded` がこのパス形式で認識）。
- Firestore では `ai_label_jobs/{jobId}` ドキュメントとしてジョブ情報を管理する。
- クライアントは自分で生成した `jobId` を保持し、Firestore の該当ドキュメントをリアルタイムリスナーで監視する。
- Storage トリガーで Cloud Functions が起動し、AI 推論 → Firestore の同じドキュメントを更新する。

### フロー例

1. クライアントで UUID を生成（`uuid` パッケージ利用）
2. 画像を `user_uploads/{userId}/{jobId}.jpg` として Firebase Storage にアップロード
3. 同時に Firestore に `ai_label_jobs/{jobId}` ドキュメント（`status: "running"`, `image_url`, `created_at` 等）を作成
4. Storage トリガーで Cloud Functions が起動し、AI 推論 → Firestore の同じドキュメントを更新
5. クライアントは Firestore の `ai_label_jobs/{jobId}` をリアルタイムリスナーで監視・結果取得

## 10. Firestoreジョブ管理スキーマ設計

### コレクション名
```
ai_label_jobs
```

### ドキュメントID
- ジョブID（UUID推奨。Cloud Functions側で生成、またはクライアントで生成してもOK）

### ドキュメント構造（フィールド例）

| フィールド名   | 型            | 説明                                         | 必須/任意 |
|----------------|---------------|----------------------------------------------|-----------|
| job_id         | string        | ジョブID（ドキュメントIDと同じ値）           | 必須      |
| user_id        | string        | ユーザーID（認証ユーザーのUID）              | 必須      |
| status         | string        | 'running' / 'success' / 'failed'             | 必須      |
| image_url      | string        | Storageの画像URL（gs://... or https://...）  | 必須      |
| result         | map/null      | AI認識結果（`brand`, `brewery`, `tags` を持つ Firestore map） | 任意 |
| error          | string/null   | エラー内容（失敗時のみ）                     | 任意      |
| created_at     | timestamp     | ジョブ作成日時                               | 必須      |
| updated_at     | timestamp     | 最終更新日時                                 | 必須      |
| ai_version     | string/null   | 使用したAIモデルのバージョン                 | 任意      |
| confidence     | number/null   | AIの信頼度スコア                             | 任意      |

### サンプルドキュメント

```json
{
  "job_id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "uid_abc123",
  "status": "success",
  "image_url": "gs://sakeflow-app/user_uploads/uid_abc123/123e4567-e89b-12d3-a456-426614174000.jpg",
  "result": {
    "brand": "獺祭",
    "brewery": "旭酒造",
    "tags": ["純米大吟醸", "磨き二割三分", "山田錦", "山口県"]
  },
  "confidence": 0.98,
  "ai_version": "gpt-4o",
  "created_at": "2024-06-01T12:00:00Z",
  "updated_at": "2024-06-01T12:01:00Z"
}
```

### ステータス値の運用例
- `running` : 画像アップロード直後、AI推論中
- `success` : AI推論完了、結果あり
- `failed`  : AI推論失敗、`error`フィールドに詳細

### インデックス設計（推奨）
- `user_id` で検索（ユーザーごとの履歴表示）
- `status` で検索（進行中ジョブの監視）
- `created_at` 降順（新しい順に並べる）

### セキュリティルール例
- `user_id`が認証ユーザーのUIDと一致する場合のみ読み書き許可
- 管理者のみ全件参照可能 