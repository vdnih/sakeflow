# sakeflow モノレポ アーキテクチャ

> バージョン: 1.2  
> 最終更新: 2026-05-08

---

## 全体構成図

```
┌────────────────────────────────────────────────────────────────┐
│                         ユーザー                                │
└───────────┬──────────────────────────┬─────────────────────────┘
            │ ブラウザ                  │ ブラウザ / iOS / Android
            ▼                          ▼
┌───────────────────────┐   ┌─────────────────────────────────┐
│   sakeflow blog       │   │   sakeflow-log app              │
│   (Next.js 13)        │   │   (Flutter Web / Mobile)        │
│   Firebase App        │   │   Firebase Hosting              │
│   Hosting             │   │                                 │
└───────────┬───────────┘   └──────────────┬──────────────────┘
            │                              │
            │ microCMS API                 │ Firebase SDK
            ▼                              │ + firebase_ai (Vertex AI)
┌───────────────────────┐   ┌─────────────▼───────────────────┐
│   microCMS            │   │   Firebase                      │
│   (Headless CMS)      │   │   ├── Authentication            │
│   - blogs endpoint    │   │   ├── Firestore                 │
│   - categories        │   │   ├── Storage                   │
│   endpoint            │   │   ├── Hosting                   │
└───────────────────────┘   │   └── AI Logic (Vertex AI)      │
                            │       gemini-3.1-flash-lite      │
                            └─────────────────────────────────┘
```

---

## コンポーネント概要

### blog（`blog/`）

| 項目 | 詳細 |
|-----|------|
| フレームワーク | Next.js 13.4（App Router） |
| ホスティング | Firebase App Hosting（GitHub 連携自動デプロイ） |
| CMS | microCMS（headless CMS） |
| データ取得 | SSG/ISR（記事一覧・詳細）、SSR（検索） |
| 主な依存 | microcms-js-sdk, cheerio, highlight.js |
| 環境変数 | `MICROCMS_SERVICE_DOMAIN`, `MICROCMS_API_KEY`（Secret Manager） |

詳細: [docs/blog/ARCHITECTURE.md](blog/ARCHITECTURE.md)

### app（`app/`）

| 項目 | 詳細 |
|-----|------|
| フレームワーク | Flutter（Dart >=3.7.2） |
| ホスティング | Firebase Hosting（`app/build/web` をデプロイ） |
| 認証 | Firebase Authentication + firebase_ui_auth |
| データベース | Cloud Firestore |
| ストレージ | Firebase Storage |
| AI | Firebase AI Logic（`firebase_ai`）+ Vertex AI + `gemini-3.1-flash-lite` |
| 主な対応 | Web（主）, iOS, Android |

詳細: [docs/app/SOFTWARE_ARCHITECTURE.md](app/SOFTWARE_ARCHITECTURE.md) / [docs/app/FIREBASE_ARCHITECTURE.md](app/FIREBASE_ARCHITECTURE.md)

### functions（`functions/`）

> **注**: AI 機能は Firebase AI Logic に移行しました（[ADR-0003](adr/0003-migrate-openai-to-firebase-ai-logic.md)）。
> Cloud Functions は現在使用していません。将来必要になった場合は `firebase init functions` で再生成します。

---

## デプロイフロー

```
GitHub main ブランチへの push
         │
         ├──→ Firebase App Hosting（blog/）
         │     └── Next.js ビルド → Firebase インフラ（SSR/ISR/CDN）
         │
         └──→ GitHub Actions（app/）
               ├── Flutter web ビルド（app/build/web）
               └── firebase deploy --only hosting
```

### GitHub Actions ワークフロー

`.github/workflows/` に Firebase デプロイ用ワークフローが定義されています。

---

## セキュリティ境界

| サービス | 認証方式 | アクセス制御 |
|---------|---------|------------|
| Firestore | Firebase Auth UID | セキュリティルール（uid ベース） |
| Storage | Firebase Auth UID | セキュリティルール（uid ベース） |
| Firebase AI Logic | Firebase Auth + App Check | Vertex AI IAM（サービスアカウント） |
| microCMS | API Key（Secret Manager） | Firebase App Hosting 経由 |

---

## Firebase プロジェクト

`.firebaserc` で定義されているプロジェクトを使用します。  
プロジェクト ID は `firebase.json` および `app/lib/firebase_options.dart` を参照してください。
