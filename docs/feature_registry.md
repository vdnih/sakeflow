# sakeflow 機能レジストリ

> 最終更新: 2026-04-29  
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
| B01 | 記事一覧表示 | 🟡 | `blog/app/page.tsx` | microCMS から取得 |
| B02 | 記事詳細表示 | 🟡 | `blog/app/articles/[id]/` | - |
| B03 | カテゴリ別一覧 | ⚪ | - | - |
| B04 | 記事検索 | ⚪ | - | - |
| B05 | ページネーション | ⚪ | - | - |
| B06 | OGP / SNS シェア | ⚪ | - | - |

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
