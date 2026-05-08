# sakeflow 機能レジストリ

> 最終更新: 2026-05-08（Firebase AI Logic 移行 + Cloud Functions 削除）  
> ステータス: 🟢RELEASED / 🟡IN_PROGRESS / ⚪PLANNED / 🔴BLOCKED

---

## app（sakeflow-log）

| 機能 ID | 機能名 | ステータス | 実装ファイル | テストファイル | 画面 ID | 備考 |
|--------|------|---------|-----------|------------|--------|------|
| F00 | ボトムナビゲーション | 🟢 | `app/lib/features/shell/main_shell.dart`, `app/lib/features/shell/widgets/floating_bottom_nav.dart` | - | S01 | 2026-05-03 にフローティング型に刷新 |
| F01 | AI ラベル認識 | 🟢 | `app/lib/features/record/ai_label_screen.dart` | - | S05 | 2026-05-08: firebase_ai (Vertex AI) に移行。即時解析・ポーリング廃止 |
| F02 | パーソナライズ推薦 | 🟢 | `app/lib/features/analysis/screens/ai_suggestion_screen.dart`, `app/lib/features/analysis/services/taste_analysis_service.dart` | - | S04 | 2026-05-08: firebase_ai (Vertex AI) に移行。Cloud Functions 廃止 |
| F03 | テイスティングノート保存・一覧 | 🟢 | `app/lib/features/tasting_note/`, `app/lib/features/home/home_tab.dart` | - | S06 | 2026-05-03 にリデザイン適用 |
| F04 | テイスティングノート詳細・編集 | 🟢 | `app/lib/features/tasting_note/screens/tasting_note_detail_screen.dart` | - | S07 | 2026-05-03 にヒーロー画像 + 5 ボタン評価に刷新 |
| F05 | ユーザー認証 | 🟢 | `app/lib/main.dart` | - | S02, S03 | 2026-05-03 に `auth_gate.dart` 削除（未使用） |
| F06 | プロフィール編集 | ⚪ | - | - | S08 | - |
| F07 | 設定変更 | ⚪ | - | - | S09 | - |
| F08 | コレクション自動登録・一覧 | 🟢 | `app/lib/features/collection/` | - | S13 | 2026-05-03 に 2 列グリッド + フィルターチップに刷新 |
| F09 | マップ（都道府県制覇） | ⚪ | `app/lib/features/map/` | - | S11 | UI 雛形は実装済（ステータス完了は別 PR） |
| F10 | テイスト分析 | 🟢 | `app/lib/features/analysis/` | - | S12 | 2026-05-08: firebase_ai に移行完了 |
| F11 | レビュー投稿 | ⚪ | - | - | S10 | - |
| F12 | デザインシステム | 🟢 | `app/lib/core/theme/`, `app/lib/core/widgets/` | - | - | 2026-05-03 導入（[ADR-0002](adr/0002-design-system-and-theme-architecture.md)） |

## blog（sakeflow ブログサイト）

| 機能 ID | 機能名 | ステータス | 実装ファイル | 備考 |
|--------|------|---------|-----------|------|
| B01 | 記事一覧表示 | 🟢 | `blog/app/page.tsx`, `blog/app/p/[current]/page.tsx` | microCMS から取得・ISR |
| B02 | 記事詳細表示 | 🟢 | `blog/app/articles/[slug]/page.tsx` | ドラフトプレビュー対応 |
| B03 | カテゴリ別一覧 | 🟢 | `blog/app/categories/[categoryId]/page.tsx`, `blog/app/categories/[categoryId]/p/[current]/page.tsx` | ページネーション込み |
| B04 | 記事検索 | 🟢 | `blog/app/search/page.tsx`, `blog/app/search/p/[current]/page.tsx` | IME 対応済み |
| B05 | ページネーション | 🟢 | 全一覧ページに実装済み | `blog/app/p/[current]/` パターン |
| B06 | OGP / SNS シェア | 🟢 | 各ページの `generateMetadata` | og:image, og:description 設定済み |

## functions（Cloud Functions）

> **Cloud Functions は 2026-05-08 に全廃止**しました。AI 機能は Firebase AI Logic（`firebase_ai`）に移行しています。
> 詳細: [ADR-0003](adr/0003-migrate-openai-to-firebase-ai-logic.md)

| 機能 ID | 機能名 | ステータス | 備考 |
|--------|------|---------|------|
| CF01 | AI ラベル認識 | ❌ 削除 | F01 として Flutter 側に移行 |
| CF02 | CI/CD 自動デプロイ | 🟢 | `.github/workflows/` — Functions 部分は削除済み |
| CF03 | AI解析完了→ノート/コレクション更新 | ❌ 削除 | Flutter 側で同期処理に統合 |
| CF04 | テイスト分析（AI傾向分析・推薦） | ❌ 削除 | F02 として Flutter 側に移行 |

---

## ステータス定義

| ステータス | 説明 |
|---------|------|
| 🟢 RELEASED | 本番稼働中 |
| 🟡 IN_PROGRESS | 実装中・開発中 |
| ⚪ PLANNED | 計画済み・未着手 |
| 🔴 BLOCKED | ブロック中（依存関係・課題あり） |
| 🔵 MODIFY | 改修・変更中 |
