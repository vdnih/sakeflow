# sakeflow 監査ログ

> 最新エントリーが先頭（降順）

---

## 2026-05-02

### テイスティングノート・コレクション機能の実装

- **内容**: 飲酒記録を「テイスティングノート（日時単位のイベントログ）」と「コレクション（銘柄単位のエンティティ）」に分離してFirestoreに保存し、それぞれ一覧画面で閲覧できるよう実装
- **変更ファイル**:
  - 新規: `docs/adr/0001-distributed-user-db-strategy.md` — アーキテクチャ方針3点をADRとして記録
  - 新規: `app/lib/features/tasting_note/models/tasting_note.dart`
  - 新規: `app/lib/features/collection/models/sake.dart`
  - 新規: `app/lib/features/tasting_note/repositories/tasting_note_repository.dart`
  - 新規: `app/lib/features/collection/repositories/sake_repository.dart`
  - 新規: `app/lib/features/tasting_note/screens/tasting_note_detail_screen.dart`
  - 更新: `app/lib/features/record/ai_label_screen.dart` — 保存フローをtasting_note作成に変更
  - 更新: `app/lib/features/home/home_tab.dart` — テイスティングノート一覧を実装
  - 更新: `app/lib/features/collection/collection_tab.dart` — コレクション一覧を実装
  - 更新: `functions/src/index.ts` — `onAiLabelJobCompleted` を追加（AI解析完了時にtasting_note更新 + sake upsert）
  - 更新: `docs/app/SPEC.md` — データモデル更新
  - 更新: `docs/feature_registry.md`
- **理由**: AI解析結果がFirestoreの`ai_label_jobs`に保存されるだけで、ユーザーの飲酒記録として永続化されていなかった。記録・一覧閲覧の基本機能を実装する
- **決定事項**:
  - **分散型DB** — 中央日本酒マスターDBは持たず、ユーザーごとに独立した`sakes`コレクションを管理（詳細: ADR-0001）
  - **画像認識特化** — 入力補完はAIラベル認識のみ。テキストサジェストは実装しない（詳細: ADR-0001）
  - **エンティティ/イベント分離** — `users/{userId}/sakes`（銘柄）と`users/{userId}/tasting_notes`（飲酒ログ）を別コレクションで管理。tasting_notes側に非正規化。書き込みはFirestore WriteBatchでアトミック性確保（詳細: ADR-0001）
  - AI解析→ノート/コレクション更新はCloud Function側（`onAiLabelJobCompleted`）に集約し、クライアントの責務を軽減

---

### ボトムナビゲーションバー実装・feature-based 構成への移行

- **内容**: アプリのナビゲーション体系を再設計。ボトムナビゲーションバー（4タブ）と右下フローティングアクションボタン（記録）を実装
- **変更ファイル**:
  - `app/lib/features/shell/main_shell.dart`（新規）: `IndexedStack` + `BottomNavigationBar` + `FloatingActionButton` を持つシェルウィジェット
  - `app/lib/features/home/home_tab.dart`（新規）: ホームタブ
  - `app/lib/features/map/map_tab.dart`（新規）: マップタブ（プレースホルダー）
  - `app/lib/features/analysis/analysis_tab.dart`（新規）: 分析タブ（プレースホルダー）
  - `app/lib/features/collection/collection_tab.dart`（新規）: コレクションタブ（プレースホルダー）
  - `app/lib/features/record/ai_label_screen.dart`（移動）: `lib/` 直下から `features/record/` へ
  - `app/lib/auth_gate.dart`（修正）: `HomeScreen` → `MainShell` に切り替え
  - `app/lib/main.dart`（修正）: `/home` ルートを `MainShell` に、`/ai-label` ルートを削除
- **決定事項**:
  - 記録アクションはナビバーの中央タブではなく、右下 FAB（`FloatingActionButtonLocation.endFloat`）に配置。最頻アクションを親指の届く位置に置くため
  - タブ数は4（ホーム・マップ・分析・コレクション）。記録は FAB 専用にしナビバーを5項目にしない
  - タブ切り替えは `IndexedStack` でスクロール位置等を保持

---

### CI/CD 権限修正・Cloud Functions 本番デプロイ完了

- **内容**: 画像認識機能が本番環境で動作しない問題を調査・修正。CI/CD の Cloud Functions デプロイステップが権限エラーで失敗し続けていたため、最新コードが本番に反映されていなかった
- **調査手順**:
  1. Firebase MCP で `ai_label_jobs` コレクションを確認 → 関数は起動・成功しているが `result` が旧フォーマット（JSON 文字列）で保存されていた
  2. GitHub Actions ログを確認 → PR #6 マージ時（CI/CD 追加）以降のデプロイが全て `failure`
  3. エラーを段階的に特定・解消（下記「決定事項」参照）
- **変更ファイル**:
  - GCP IAM ポリシー変更（コード変更なし）
  - Cloud Billing API 有効化（プロジェクト設定変更）
- **理由**: PR #5 で `index.ts` を `brand/brewery/tags` マップ形式に刷新したが、CI/CD が壊れていたため旧コードが本番に残り続けていた。アプリ側は新フォーマットを期待しているため動作不良が発生
- **決定事項**:
  - `github-action-943912018@sakeflow.iam.gserviceaccount.com`（GitHub Actions SA）に以下の権限を追加：
    - `Service Account User`（`iam.serviceAccounts.actAs`）
    - `Secret Manager Secret Accessor`（`secretmanager.versions.access`）
    - `Secret Manager Viewer`（`secretmanager.secrets.get`）— `firebase deploy` のデプロイ時シークレット存在確認に必要
  - Cloud Billing API（`cloudbilling.googleapis.com`）を有効化
  - 修正後、run `25248049013` を再実行し全ステップ成功・最新コードのデプロイを確認

---

### blog 実装状況の現状反映 + Firebase App Hosting 移行方針の記録

- **内容**:
  - `docs/feature_registry.md` の blog 機能 B01〜B06 を実態に合わせて更新（🟡/⚪ → 🟢 RELEASED）
  - `docs/WBS.md` の I-01 タスクを実装完了状態に更新; I-01-06 を Firebase App Hosting デプロイ設定に変更
  - `docs/blog/ARCHITECTURE.md` を全面改訂（ディレクトリ構成を実装済み全ページに更新、ホスティングを Vercel → Firebase App Hosting に変更、環境変数の設定場所を Secret Manager に変更）
  - `docs/ARCHITECTURE.md` を更新（構成図・テーブル・デプロイフロー図の Vercel 記述を Firebase App Hosting に変更）
  - `blog/apphosting.yaml` を新規作成（Firebase App Hosting のバックエンド設定ファイル）
  - `CLAUDE.md` のホスティング欄を更新
- **変更ファイル**:
  - 更新: `docs/feature_registry.md`
  - 更新: `docs/WBS.md`
  - 更新: `docs/blog/ARCHITECTURE.md`（v1.0 → v1.1）
  - 更新: `docs/ARCHITECTURE.md`（v1.0 → v1.1）
  - 新規: `blog/apphosting.yaml`
  - 更新: `CLAUDE.md`
- **理由**: プロジェクトを長期間触れていない状態からの再開。コードベース上はブログの全主要機能（記事一覧・詳細・カテゴリ・検索・ページネーション・OGP）が実装完了済みだがドキュメントが初期作成時のまま放置されていた。将来的な広告収益化を見据え、Vercel から Firebase（Google エコシステム）に統一する方針に変更。
- **決定事項**:
  - blog のホスティングを Vercel → Firebase App Hosting に移行する（ADR 起票は省略、方針変更のみ記録）
  - Firebase App Hosting は Next.js をネイティブサポートし、ISR/SSR/App Router が動作する
  - シークレット（`MICROCMS_SERVICE_DOMAIN`, `MICROCMS_API_KEY`）は Firebase Secret Manager で管理する
  - バックエンドの実際の登録（GitHub 接続・ブランチ設定）は手動作業として残す

---

## 2026-04-29

### docs 構成整備（初回）

- **内容**: my_career_app の docs 体系を参考に、sakeflow のドキュメント構成を整備
- **変更ファイル**:
  - 新規: `CLAUDE.md`（ルートガバナンス）
  - 新規: `docs/PRODUCT_VISION.md`
  - 新規: `docs/PRD.md`（ブランドレベル）
  - 新規: `docs/ARCHITECTURE.md`（モノレポ全体）
  - 新規: `docs/WBS.md`
  - 新規: `docs/feature_registry.md`
  - 新規: `docs/audit_log.md`（このファイル）
  - 新規: `docs/adr/`（空ディレクトリ）
  - 新規: `docs/app/PRD.md`（about.md + ui-design.md を統合）
  - 新規: `docs/app/SPEC.md`
  - 新規: `docs/app/SOFTWARE_ARCHITECTURE.md`
  - 新規: `docs/app/FIREBASE_ARCHITECTURE.md`
  - 新規: `docs/app/TESTING_POLICY.md`
  - 更新: `docs/app/ai-label-recognition.md`（整理・強化）
  - 新規: `docs/blog/PRD.md`
  - 新規: `docs/blog/ARCHITECTURE.md`
  - 新規: `docs/functions/ARCHITECTURE.md`
  - 削除: `docs/sakeflow.md`（READMEへの参照のみで内容なし）
  - 削除: `docs/app/about.md`（`docs/app/PRD.md` に統合）
  - 削除: `docs/app/ui-design.md`（`docs/app/PRD.md` に統合）
- **理由**: sakeflow でも AI エージェントによる開発を行うにあたり、コンテキストを与えるドキュメント体系が必要
- **決定事項**:
  - モノレポ構成に対応するため、グローバル（`docs/`）とコンポーネント別（`docs/app/`, `docs/blog/`, `docs/functions/`）の 2 層構造を採用
  - PRD はブランドレベル + blog 用 + app 用の 3 ファイル構成
  - WBS と feature_registry を含め、開発進捗をドキュメントで管理する

---

_ログフォーマット_:
```
## YYYY-MM-DD

### [変更タイトル]

- **内容**: 何を変更したか
- **変更ファイル**: 影響ファイル一覧
- **理由**: なぜ変更したか
- **決定事項**: 特記すべき意思決定
```
