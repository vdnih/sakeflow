# sakeflow-log テストポリシー

> バージョン: 1.0  
> 最終更新: 2026-04-29

---

## テスト戦略

### テストピラミッド（目標）

```
         ┌───┐
         │E2E│  5%（Integration test）
        ┌┴───┴┐
        │Widget│ 25%（Widget test）
       ┌┴──────┴┐
       │  Unit  │ 70%（Unit test）
       └────────┘
```

| テスト種別 | 対象 | ツール |
|---------|------|-------|
| Unit test | ビジネスロジック・Repository | `flutter_test` + `mocktail` |
| Widget test | 画面・コンポーネント | `flutter_test` |
| Integration test | 認証フロー・Firebase 連携 | `integration_test` |

---

## 各層のテスト方針

### Presentation 層（Widget テスト）

- 状態変化（loading / data / error）ごとに Widget ツリーを検証
- ユーザーインタラクション（タップ・入力）のシミュレーション
- Firebase 依存はモック化

### Logic 層（Unit テスト）

- State 変化のテスト（状態遷移の検証）
- ビジネスルールの純粋関数テスト（バリデーション等）

### Data 層（Unit テスト）

- Firestore ドキュメント ↔ Dart オブジェクトの変換テスト
- Repository の CRUD 操作テスト（`FakeFirebaseFirestore` 等を利用）

---

## 品質基準

| 基準 | 目標値 |
|-----|-------|
| Unit + Widget テスト カバレッジ | 80% 以上（Logic 層） |
| `dart analyze` | エラー 0 件 |
| CI パス率 | 100% |

---

## CI 設定

GitHub Actions で以下を自動実行：

```yaml
- flutter test --coverage
- dart analyze
- lcov でカバレッジレポート生成
```

> TODO: `.github/workflows/` に Flutter テスト用ワークフローを追加

---

## テストファイル構成

テストファイルはソースファイルと対応する構造で `app/test/` に配置します。

```
app/test/
├── features/
│   ├── label_recognition/
│   │   └── label_recognition_service_test.dart
│   └── record/
│       └── record_repository_test.dart
└── core/
    └── auth/
        └── auth_gate_test.dart
```

---

## 現状

- テストは未実装（Phase 1 初期段階）
- Phase 2 の機能実装と並行してテストを追加する方針
