# sakeflow-log Firebase アーキテクチャ

> バージョン: 1.0  
> 最終更新: 2026-04-29

---

## 使用 Firebase サービス一覧

| サービス | 用途 | 実装状況 |
|---------|------|---------|
| Firebase Authentication | ユーザー認証（Google Sign-In） | ✅ 実装済み |
| Cloud Firestore | データベース（記録・ジョブ管理） | 🔄 一部実装 |
| Firebase Storage | 画像ファイル保存 | 🔄 一部実装 |
| Firebase Hosting | Web アプリのホスティング | ✅ 実装済み |

---

## Firebase Authentication

### プロバイダー

- **Google Sign-In**（Phase 1: Web ポップアップ）
- **匿名認証**（TODO: ゲストモード用途で検討）

### 実装パッケージ

```yaml
firebase_auth: ^5.5.3
firebase_ui_auth: ^1.16.1
firebase_ui_oauth_google: ^1.4.1
```

### 認証フロー（Web）

```
SignInScreen (firebase_ui_auth)
    → Google Sign-In ポップアップ
    → Firebase Auth コールバック
    → AuthGate が認証状態を検知
    → /home へリダイレクト
```

実装: `app/lib/auth_gate.dart`, `app/lib/main.dart`

---

## Cloud Firestore

### スキーマ設計

#### `users/{userId}`

```
{
  uid: string,
  display_name: string,
  email: string,
  photo_url: string | null,
  created_at: Timestamp,
  updated_at: Timestamp
}
```

#### `users/{userId}/records/{recordId}`

```
{
  record_id: string,       // UUID
  user_id: string,
  category_name: string,   // "sake" | "wine" | "beer" | ...
  name_jp: string,
  name_en: string | null,
  tags: string[],
  rating: number | null,   // 1.0-5.0
  note: string | null,
  image_url: string | null,
  job_id: string | null,   // AI ラベル認識ジョブとの紐付け
  drank_at: Timestamp,
  created_at: Timestamp,
  updated_at: Timestamp
}
```

#### `ai_label_jobs/{jobId}`

詳細は [docs/app/ai-label-recognition.md](ai-label-recognition.md) を参照。

### インデックス設計

| コレクション | フィールド | 用途 |
|-----------|---------|------|
| `records` | `user_id` + `drank_at` (DESC) | ユーザーの記録一覧（新しい順） |
| `records` | `user_id` + `category_name` | カテゴリ別フィルタ |
| `ai_label_jobs` | `user_id` + `created_at` (DESC) | ユーザーのジョブ履歴 |

---

## Firebase Storage

### ストレージパス設計

| パス | 用途 | 最大サイズ |
|-----|------|---------|
| `user_uploads/{userId}/{jobId}.jpg` | AI ラベル認識用画像 | TODO: 制限を設定 |
| `records/{userId}/{recordId}.jpg` | 飲酒記録の写真 | TODO: 制限を設定 |

---

## Firebase Hosting

設定ファイル: `firebase.json`

```json
{
  "hosting": {
    "public": "app/build/web",
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

- Flutter web ビルド出力（`app/build/web`）を Firebase Hosting に配信
- SPA（シングルページアプリケーション）のため、全ルートを `index.html` にリライト

---

## セキュリティルール

### Firestore セキュリティルール（設計）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // users: 本人のみ読み書き
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // records: 本人のみ読み書き
      match /records/{recordId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // ai_label_jobs: 本人のみ読み書き
    match /ai_label_jobs/{jobId} {
      allow read: if request.auth != null 
                  && request.auth.uid == resource.data.user_id;
      allow write: if request.auth != null 
                   && request.auth.uid == request.resource.data.user_id;
    }
  }
}
```

### Storage セキュリティルール（設計）

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_uploads/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /records/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Firebase プロジェクト設定

設定ファイル: `app/lib/firebase_options.dart`（`flutterfire configure` で自動生成）  
プロジェクト接続情報: `.firebaserc`
