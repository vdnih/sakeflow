# sakeflow-log アプリ SPEC（ビジネスルール仕様）

> バージョン: 1.2  
> 最終更新: 2026-05-08

---

## お酒カテゴリ定義

| カテゴリ ID | 日本語名 | 英語名（type 値）| アイコン（案）|
|-----------|--------|--------------|------------|
| C01 | 日本酒 | `sake` | 🍶 |
| C02 | ワイン | `wine` | 🍷 |
| C03 | ビール | `beer` | 🍺 |
| C04 | ウイスキー | `whisky` | 🥃 |
| C05 | 焼酎 | `shochu` | - |
| C06 | リキュール | `liqueur` | - |
| C07 | ブランデー | `brandy` | - |
| C08 | ジン | `gin` | - |
| C09 | ウォッカ | `vodka` | - |
| C10 | ラム | `rum` | - |
| C99 | その他 | `other` | - |

カテゴリは AI ラベル認識が自動判別しますが、ユーザーが修正可能です。

---

## データモデル

### users コレクション（`users/{userId}`）

| フィールド | 型 | 説明 | 必須 |
|---------|---|------|------|
| uid | string | Firebase Auth UID | ✅ |
| display_name | string | 表示名 | ✅ |
| email | string | メールアドレス | ✅ |
| photo_url | string | プロフィール画像 URL | - |
| created_at | timestamp | 登録日時 | ✅ |
| updated_at | timestamp | 最終更新日時 | ✅ |

### tasting_notes コレクション（`users/{userId}/tasting_notes/{noteId}`）

飲酒イベントログ。同じ銘柄を複数回飲んだ場合、飲むたびに1ドキュメントが追加される。

| フィールド | 型 | 説明 | 必須 |
|---------|---|------|------|
| note_id | string | ノート ID（UUID） | ✅ |
| user_id | string | ユーザー ID | ✅ |
| sake_id | string | sakes コレクションへの参照 | ✅ |
| image_url | string | 写真の Storage URL | ✅ |
| drank_at | timestamp | 飲んだ日時 | ✅ |
| location | map | `{lat, lng, place_name}` ※ Phase 2 | - |
| brand | string | 銘柄名 ※ AI 抽出・ユーザー修正可 | - |
| brewery | string | 蔵元名 ※ AI 抽出・ユーザー修正可 | - |
| prefecture | string | 都道府県 ※ AI 抽出・ユーザー修正可 | - |
| category | string | お酒カテゴリ（type 値）デフォルト "sake" | - |
| tags | array\<string\> | 特定名称・酒米・精米歩合・製法・フレーバー等のスペック | - |
| rating | number | 評価（1.0-5.0、0.5 刻み） | - |
| note | string | テイスティングメモ（最大 1000 文字） | - |
| drank_locally | boolean | 産地の都道府県で飲んだ場合 true | - |
| created_at | timestamp | 記録作成日時 | ✅ |
| updated_at | timestamp | 最終更新日時 | ✅ |

### sakes コレクション（`users/{userId}/sakes/{sakeId}`）

銘柄エンティティ。同じ銘柄は1ドキュメント。tasting_notes から自動集計される。

| フィールド | 型 | 説明 | 必須 |
|---------|---|------|------|
| sake_id | string | 銘柄 ID（UUID） | ✅ |
| user_id | string | ユーザー ID | ✅ |
| brand | string | 銘柄名（重複排除キー） | ✅ |
| brewery | string | 蔵元名 | - |
| prefecture | string | 都道府県 | - |
| category | string | お酒カテゴリ（type 値） | ✅ |
| image_url | string | 最新の写真 URL | - |
| tasting_count | number | 飲んだ回数（自動集計） | ✅ |
| avg_rating | number | 平均評価（自動集計） | - |
| first_drank_at | timestamp | 初めて飲んだ日時 | ✅ |
| last_drank_at | timestamp | 直近に飲んだ日時 | ✅ |
| created_at | timestamp | 作成日時 | ✅ |
| updated_at | timestamp | 最終更新日時 | ✅ |

---

## 認証フロー

### Web（Phase 1）

```
ユーザー → ログインボタン → Firebase Auth（Google Sign-In ポップアップ）
       → コールバック処理 → トークン取得 → ホーム画面遷移
```

実装上の特徴：
- `firebase_ui_auth` + `firebase_ui_oauth_google` パッケージを使用
- `AuthGate`（`app/lib/auth_gate.dart`）で認証状態を監視・ルーティング制御
- Web 専用フロー（`signInWithPopup`）

### モバイル（Phase 3 予定）

- `google_sign_in` パッケージを使用
- ディープリンクによるコールバック処理

---

## バリデーションルール

### 記録登録時

| フィールド | ルール |
|---------|------|
| category_name | 上記カテゴリ定義の type 値のみ許可 |
| rating | 1.0 〜 5.0 の範囲、0.5 刻み |
| note | 最大 1000 文字 |
| image_url | Firebase Storage の URL のみ許可 |

### AI ラベル認識時

| 項目 | ルール |
|-----|------|
| 画像形式 | JPEG のみ（.jpg 拡張子） |
| 画像サイズ | TODO: 最大サイズ制限を設定 |
| ストレージパス | `user_uploads/{userId}/{imageId}.jpg` |
| AI | Firebase AI Logic（`firebase_ai`）、クライアント側で同期実行 |

---

## セキュリティルール概要

### Firestore

```
users/{userId}: 本人のみ読み書き（uid 一致）
users/{userId}/tasting_notes/{noteId}: 本人のみ読み書き
users/{userId}/sakes/{sakeId}: 本人のみ読み書き
```

### Storage

```
user_uploads/{userId}/{jobId}.jpg: 本人のみ書き込み（uid 一致）
```

詳細は [docs/app/FIREBASE_ARCHITECTURE.md](FIREBASE_ARCHITECTURE.md) を参照。
