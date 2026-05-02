# sakeflow 監査ログ

> 最新エントリーが先頭（降順）

---

## 2026-05-02

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
