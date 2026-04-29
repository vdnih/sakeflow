# sakeflow-log アプリ SPEC（ビジネスルール仕様）

> バージョン: 1.0  
> 最終更新: 2026-04-29

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

### records コレクション（`users/{userId}/records/{recordId}`）

| フィールド | 型 | 説明 | 必須 |
|---------|---|------|------|
| record_id | string | レコード ID（UUID） | ✅ |
| user_id | string | ユーザー ID | ✅ |
| category_name | string | お酒カテゴリ（C01-C99 の type 値） | ✅ |
| name_jp | string | 銘柄名（日本語） | ✅ |
| name_en | string | 銘柄名（英語） | - |
| tags | array<string> | タグ（生産者・味わい等） | - |
| rating | number | 評価（1.0-5.0、0.5 刻み） | - |
| note | string | テイスティングノート・メモ | - |
| image_url | string | 写真の Storage URL | - |
| job_id | string | AI ラベル認識ジョブ ID（紐付け用） | - |
| drank_at | timestamp | 飲んだ日時 | ✅ |
| created_at | timestamp | 記録作成日時 | ✅ |
| updated_at | timestamp | 最終更新日時 | ✅ |

### ai_label_jobs コレクション（`ai_label_jobs/{jobId}`）

詳細は [docs/app/ai-label-recognition.md](ai-label-recognition.md) を参照。

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
| ストレージパス | `user_uploads/{userId}/{jobId}.jpg` |

---

## セキュリティルール概要

### Firestore

```
users/{userId}: 本人のみ読み書き（uid 一致）
users/{userId}/records/{recordId}: 本人のみ読み書き
ai_label_jobs/{jobId}: user_id が uid と一致する場合のみ読み取り可
```

### Storage

```
user_uploads/{userId}/{jobId}.jpg: 本人のみ書き込み（uid 一致）
```

詳細は [docs/app/FIREBASE_ARCHITECTURE.md](FIREBASE_ARCHITECTURE.md) を参照。
