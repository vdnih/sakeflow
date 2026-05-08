# sakeflow-log テストポリシー

> バージョン: 2.0  
> 最終更新: 2026-05-08（Phase 1 MVP 完了後の実態反映）

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
| Unit test | モデル・Repository・サービス・ユーティリティ | `flutter_test` + `fake_cloud_firestore` + `mocktail` |
| Widget test | 画面・コンポーネント | `flutter_test` |
| Integration test | 認証フロー・Firebase 実連携 | `integration_test` |

---

## 使用パッケージ

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^0.3.0               # サービス・外部 API のモック
  fake_cloud_firestore: ^3.1.0   # Firestore CRUD テスト（Firebase 接続不要）
```

---

## 各層のテスト方針

### Presentation 層（Widget テスト）

- loading / data / error 各状態の Widget ツリーを検証
- ユーザーインタラクション（タップ・入力）をシミュレーション
- Firebase 依存はすべてモック化（`fake_cloud_firestore` または `mocktail`）

### Logic 層（Unit テスト）

- ビジネスルールの純粋関数テスト（`PrefectureNormalizer`, `PrefectureAggregator` 等）
- AI サービスは **モックファクトリパターン** でテスト:
  ```dart
  final service = AiLabelService.create(useMock: true);
  final result = await service.analyzeLabel(Uint8List(0));
  expect(result.brand, '獺祭');
  ```

### Data 層（Unit テスト）

- **モデル**: `fromFirestore()` → `toMap()` ラウンドトリップ検証
- **Repository**: `FakeFirebaseFirestore` を使って Firebase 接続なしで CRUD を検証
  ```dart
  final fakeFirestore = FakeFirebaseFirestore();
  final repo = TastingNoteRepository(db: fakeFirestore);
  ```

---

## 品質基準

| 基準 | 目標値 |
|-----|-------|
| Unit + Widget テスト カバレッジ | 80% 以上（Logic・Data 層） |
| `dart analyze` | エラー 0 件 |
| CI パス率 | 100% |

---

## CI 設定

GitHub Actions で以下を自動実行:

```yaml
# .github/workflows/flutter-test.yml（TODO: 追加）
- flutter test --coverage
- dart analyze
- lcov でカバレッジレポート生成
```

---

## テストファイル構成

ソースの `lib/features/` に対応する形で `app/test/features/` に配置。

```
app/test/
├── widget_test.dart                              # アプリ起動スモークテスト
└── features/
    ├── tasting_note/
    │   ├── models/
    │   │   └── tasting_note_test.dart            # Unit: モデル変換
    │   └── repositories/
    │       └── tasting_note_repository_test.dart  # Unit: CRUD（FakeFirebaseFirestore）
    ├── collection/
    │   ├── models/
    │   │   └── sake_test.dart                    # Unit: モデル変換
    │   └── repositories/
    │       └── sake_repository_test.dart          # Unit: upsertSake / listSakes
    ├── record/
    │   └── services/
    │       └── ai_label_service_test.dart         # Unit: モックファクトリ
    └── map/
        ├── utils/
        │   └── prefecture_normalizer_test.dart    # Unit: 純粋関数・表記揺れ
        └── services/
            └── prefecture_aggregator_test.dart    # Unit: 集計ロジック
```

---

## 現状

- Phase 1 MVP 実装完了（2026-05-08）
- テストは 2026-05-08 にゼロから整備開始
- Widget テスト・Integration テストは Phase 2 で追加予定
