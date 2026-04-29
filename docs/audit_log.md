# sakeflow 監査ログ

> 最新エントリーが先頭（降順）

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
