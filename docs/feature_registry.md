# sakeflow 機能レジストリ

> 最終更新: 2026-05-02  
> ステータス: 🟢RELEASED / 🟡IN_PROGRESS / ⚪PLANNED / 🔴BLOCKED

---

## app（sakeflow-log）

| 機能 ID | 機能名 | ステータス | 実装ファイル | テストファイル | 画面 ID |
|--------|------|---------|-----------|------------|--------|
| F01 | AI ラベル認識 | 🟡 | `app/lib/ai_label_screen.dart` | - | S05 |
| F02 | パーソナライズ推薦 | ⚪ | - | - | S04 |
| F03 | 飲酒記録 | ⚪ | - | - | S04, S06 |
| F04 | レビュー投稿 | ⚪ | - | - | S07 |
| F05 | ユーザー認証 | 🟢 | `app/lib/auth_gate.dart`, `app/lib/main.dart` | - | S02, S03 |
| F06 | プロフィール編集 | ⚪ | - | - | S08 |
| F07 | 設定変更 | ⚪ | - | - | S09 |
| F08 | 判別→記録連携 | ⚪ | - | - | S10 |

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

| 機能 ID | 機能名 | ステータス | 実装ファイル | トリガー |
|--------|------|---------|-----------|--------|
| CF01 | AI ラベル認識 | 🟢 | `functions/src/index.ts` (`onImageUploaded`) | Storage onObjectFinalized |
| CF02 | CI/CD 自動デプロイ | 🟢 | `.github/workflows/firebase-hosting-merge.yml` | main push |

---

## ステータス定義

| ステータス | 説明 |
|---------|------|
| 🟢 RELEASED | 本番稼働中 |
| 🟡 IN_PROGRESS | 実装中・開発中 |
| ⚪ PLANNED | 計画済み・未着手 |
| 🔴 BLOCKED | ブロック中（依存関係・課題あり） |
| 🔵 MODIFY | 改修・変更中 |
