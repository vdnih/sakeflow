# sakeflow WBS（作業分解構成図）

> 最終更新: 2026-04-29  
> ステータス定義: ⬜TODO / 🔄IN_PROGRESS / ✅DONE / ❌BLOCKED / 🔁REDO

---

## Phase 1: MVP（blog 公開 + app 基本機能）

### D-01: ドキュメント整備

| タスク ID | タスク名 | ステータス | 成果物 |
|---------|---------|----------|-------|
| D-01-01 | CLAUDE.md 作成 | ✅ | `CLAUDE.md` |
| D-01-02 | PRODUCT_VISION.md 作成 | ✅ | `docs/PRODUCT_VISION.md` |
| D-01-03 | ブランド PRD.md 作成 | ✅ | `docs/PRD.md` |
| D-01-04 | 全体 ARCHITECTURE.md 作成 | ✅ | `docs/ARCHITECTURE.md` |
| D-01-05 | app PRD.md 作成 | ✅ | `docs/app/PRD.md` |
| D-01-06 | app SPEC.md 作成 | ✅ | `docs/app/SPEC.md` |
| D-01-07 | app SOFTWARE_ARCHITECTURE.md 作成 | ✅ | `docs/app/SOFTWARE_ARCHITECTURE.md` |
| D-01-08 | app FIREBASE_ARCHITECTURE.md 作成 | ✅ | `docs/app/FIREBASE_ARCHITECTURE.md` |
| D-01-09 | blog PRD.md 作成 | ✅ | `docs/blog/PRD.md` |
| D-01-10 | blog ARCHITECTURE.md 作成 | ✅ | `docs/blog/ARCHITECTURE.md` |
| D-01-11 | functions ARCHITECTURE.md 作成 | ✅ | `docs/functions/ARCHITECTURE.md` |

### I-01: blog MVP 実装

| タスク ID | タスク名 | ステータス | 対象ファイル |
|---------|---------|----------|------------|
| I-01-01 | トップページ実装 | ✅ | `blog/app/page.tsx` |
| I-01-02 | 記事一覧ページ | 🔄 | `blog/app/articles/` |
| I-01-03 | 記事詳細ページ | 🔄 | `blog/app/articles/[id]/` |
| I-01-04 | カテゴリ別一覧ページ | ⬜ | `blog/app/categories/` |
| I-01-05 | 検索ページ | ⬜ | `blog/app/search/` |
| I-01-06 | Vercel デプロイ設定 | ✅ | Vercel プロジェクト設定 |

### I-02: app MVP 実装

| タスク ID | タスク名 | ステータス | 対象ファイル |
|---------|---------|----------|------------|
| I-02-01 | Firebase 初期化 | ✅ | `app/lib/firebase_options.dart` |
| I-02-02 | 認証機能（F05）| ✅ | `app/lib/auth_gate.dart` |
| I-02-03 | ホーム画面（S04）| ✅ | `app/lib/home_screen.dart` |
| I-02-04 | AI ラベル認識画面（S05, F01）| ✅ | `app/lib/ai_label_screen.dart` |
| I-02-05 | 飲酒記録登録画面（S10, F08）| ⬜ | `app/lib/features/record/` |
| I-02-06 | お酒詳細画面（S06）| ⬜ | `app/lib/features/sake_detail/` |
| I-02-07 | レビュー投稿画面（S07, F04）| ⬜ | `app/lib/features/review/` |
| I-02-08 | プロフィール画面（S08, F06）| ⬜ | `app/lib/features/profile/` |
| I-02-09 | 設定画面（S09, F07）| ⬜ | `app/lib/features/settings/` |
| I-02-10 | Firebase Hosting デプロイ | ✅ | `firebase.json` |

### I-03: functions MVP 実装

| タスク ID | タスク名 | ステータス | 対象ファイル |
|---------|---------|----------|------------|
| I-03-01 | AI ラベル認識 Function | ✅ | `functions/src/index.ts` |
| I-03-02 | OpenAI API 統合 | ✅ | `functions/src/index.ts` |
| I-03-03 | Firestore 結果保存 | ✅ | `functions/src/index.ts` |

---

## Phase 2: 拡張機能

| タスク ID | タスク名 | ステータス | 概要 |
|---------|---------|----------|------|
| I-04-01 | パーソナライズ推薦（F02）| ⬜ | ユーザー好みに基づく推薦ロジック |
| I-04-02 | SNS シェア機能 | ⬜ | 記録・レビューのシェア |
| I-04-03 | ランキング・統計（app）| ⬜ | よく飲むお酒の可視化 |
| I-04-04 | blog ↔ app 連携 | ⬜ | 記事からアプリへの導線 |

---

## Phase 3: コミュニティ

| タスク ID | タスク名 | ステータス | 概要 |
|---------|---------|----------|------|
| I-05-01 | ユーザー間フォロー | ⬜ | フォロー・フォロワー機能 |
| I-05-02 | お酒ランキング（コミュニティ）| ⬜ | ユーザー投票ベースランキング |
| I-05-03 | モバイルアプリ対応 | ⬜ | iOS / Android ネイティブ対応 |
