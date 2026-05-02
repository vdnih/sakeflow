# sakeflow — Claude Code ガバナンスドキュメント

## プロジェクト概要

sakeflow はお酒と旅を楽しむためのブランドです。モノレポ構成で以下の3コンポーネントを管理しています。

| コンポーネント | 技術スタック | ホスティング |
|--------------|------------|------------|
| `blog/` | Next.js 13 + TypeScript + microCMS | Firebase App Hosting |
| `app/` | Flutter + Dart 3 + Firebase | Firebase Hosting |
| `functions/` | TypeScript + Node.js 20 + OpenAI API | Firebase Functions |

詳細な設計・要件はドキュメント体系（[docs/](#ドキュメント体系)）を参照してください。

---

## 技術スタック（固定）

### blog（ブランドサイト）
- **フレームワーク**: Next.js 13.4 (App Router)
- **言語**: TypeScript 4.9
- **CMS**: microCMS（headless CMS）
  - エンドポイント: `blogs`, `categories`
  - コンテンツ型: `Article` (Blog + MicroCMSContentId + MicroCMSDate)
- **スタイリング**: CSS Modules
- **デプロイ**: Firebase App Hosting（GitHub 連携自動デプロイ）

### app（sakeflow-log アプリ）
- **フレームワーク**: Flutter（Dart >=3.7.2）
- **対応プラットフォーム**: Web（主）, iOS, Android, macOS, Windows, Linux
- **状態管理**: TODO（導入予定。Riverpod v2 推奨）
- **ルーティング**: MaterialApp.routes（GoRouter 移行検討中）
- **Firebase 利用サービス**:
  - firebase_auth 5.5.3 + firebase_ui_auth（Google Sign-In）
  - cloud_firestore 5.6.7
  - firebase_storage 12.4.5
- **デプロイ**: Firebase Hosting (`app/build/web` → `firebase.json` で設定)

### functions（Cloud Functions）
- **ランタイム**: Node.js 20
- **言語**: TypeScript 5.4
- **モジュール形式**: ESModule
- **主な関数**:
  - `onImageUploaded`: Storage トリガー（AI ラベル認識）
  - `helloWorld`: HTTP トリガー（開発用）
- **外部 API**: OpenAI API（gpt-4o Vision）
- **シークレット管理**: Firebase Secret (`OPENAI_API_KEY`)

---

## Vibe コーディングポリシー

### エージェント実行モデル

```
Design（設計）→ Implementation（実装）の 2 フェーズ実行
設計フェーズを省略して直接実装を開始しない
```

### 各コンポーネントのデフォルト決定ルール

#### blog（Next.js）
- コンポーネントは `app/` 配下の Page / Layout または `components/` 配下の共有コンポーネントに分類する
- データ取得は `libs/microcms.ts` の既存関数を優先再利用する
- スタイルは CSS Modules を使用する（Tailwind 等は未導入のため追加しない）
- 型定義は `libs/microcms.ts` に集約する

#### app（Flutter）
- ウィジェットが 200 行を超えたら分割する（Widget の単一責任原則）
- Firebase Auth の認証状態は `auth_gate.dart` の AuthGate で一元管理する
- 将来の feature-based ディレクトリ構成移行を前提に、新機能は `lib/features/` 配下に配置する
- Web プラットフォーム優先で実装する（モバイル対応は Phase 2）

#### functions（Cloud Functions）
- v2 API（`firebase-functions/v2`）を使用する
- API キー等のシークレットは `defineSecret` で管理し、コードに直接記載しない
- 各 Function は 1 ファイル 1 責務を原則とする（`src/index.ts` からエクスポートする）

---

## Git ルール

- **メインブランチ**: `main`（直接 push 禁止）
- **作業ブランチ**: `feature/*` または Claude Code が生成する `claude/*` ブランチ
- **コミット規約**: Conventional Commits
  - `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`
  - スコープは `(blog)`, `(app)`, `(functions)`, `(docs)` を使用
  - 例: `feat(app): AI ラベル認識画面の UI 実装`
- **PR 作成**: `gh pr create` を使用してメインブランチへマージ

---

## ドキュメント体系

ドキュメントは以下の階層で管理します。上位ほど変更頻度が低く、下位は実装に近い詳細を記載します。

```
docs/PRODUCT_VISION.md   ← 憲法（ブランドの使命・ビジョン）
docs/PRD.md              ← ブランドレベルのプロダクト要件
docs/app/PRD.md          ← アプリの機能要件
docs/blog/PRD.md         ← ブログの機能要件
docs/*/SPEC.md           ← ビジネスルール・データモデル
docs/*/ARCHITECTURE.md   ← 技術アーキテクチャ
docs/adr/                ← アーキテクチャ決定記録（ADR）
docs/WBS.md              ← 作業分解・フェーズ管理
docs/feature_registry.md ← 機能実装状況トラッキング
docs/audit_log.md        ← 意思決定・変更ログ
```

### ドキュメント更新ルール

- **PRODUCT_VISION.md / PRD.md**: プロダクト方針変更時のみ更新（変更は audit_log.md に記録）
- **SPEC.md / ARCHITECTURE.md**: 仕様・設計変更時に更新（ADR を起票してから変更）
- **feature_registry.md**: 機能実装開始・完了時に毎回更新
- **audit_log.md**: 全ての重要な意思決定・変更を即時記録

---

## ディレクトリ構成

```
sakeflow/
├── CLAUDE.md                    ← このファイル
├── README.md
├── firebase.json                ← Firebase Hosting/Functions 設定
├── .firebaserc                  ← Firebase プロジェクト接続情報
├── blog/                        ← Next.js ブランドサイト
│   ├── app/                     ← Next.js App Router ページ
│   ├── components/              ← 共有コンポーネント
│   ├── libs/                    ← ユーティリティ（microcms.ts 等）
│   ├── constants/               ← 静的定数
│   └── public/                  ← 静的アセット
├── app/                         ← Flutter アプリ
│   ├── lib/                     ← Dart ソースコード
│   │   ├── main.dart
│   │   ├── auth_gate.dart
│   │   ├── features/            ← 機能別ディレクトリ（移行先）
│   │   └── firebase_options.dart
│   └── build/web/               ← Firebase Hosting デプロイ対象
├── functions/                   ← Firebase Cloud Functions
│   └── src/
│       └── index.ts
└── docs/                        ← ドキュメント体系
    ├── PRODUCT_VISION.md
    ├── PRD.md
    ├── ARCHITECTURE.md
    ├── WBS.md
    ├── feature_registry.md
    ├── audit_log.md
    ├── adr/
    ├── app/
    └── blog/
```
