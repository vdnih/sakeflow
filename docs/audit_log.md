# sakeflow 監査ログ

> 最新エントリーが先頭（降順）

---

## 2026-05-02

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
