# sakeflow-log アプリ ソフトウェアアーキテクチャ

> バージョン: 1.0  
> 最終更新: 2026-04-29

---

## アーキテクチャ方針

### 現状（Phase 1）

フラット構成で初期実装を行っています。`app/lib/` 直下にファイルが置かれています。

```
app/lib/
├── main.dart              # エントリーポイント・ルーティング
├── auth_gate.dart         # 認証状態監視
├── home_screen.dart       # ホーム画面
├── ai_label_screen.dart   # AI ラベル認識画面
└── firebase_options.dart  # Firebase 設定（自動生成）
```

### 目標構成（Phase 2 以降）

機能追加に備え、feature-based ディレクトリ構成に移行します。

```
app/lib/
├── main.dart
├── firebase_options.dart
├── core/                          # 共通処理
│   ├── auth/
│   │   └── auth_gate.dart
│   ├── theme/                     # テーマ・カラー定義
│   └── router/                    # ルーティング定義
└── features/                      # 機能別
    ├── home/
    │   └── home_screen.dart
    ├── label_recognition/         # AI ラベル認識（F01）
    │   ├── ai_label_screen.dart
    │   └── label_recognition_service.dart
    ├── record/                    # 飲酒記録（F03, F08）
    │   ├── record_screen.dart
    │   └── record_repository.dart
    ├── sake_detail/               # お酒詳細（S06）
    ├── review/                    # レビュー（F04）
    ├── profile/                   # プロフィール（F06）
    └── settings/                  # 設定（F07）
```

---

## 3 層アーキテクチャ（目標）

```
Presentation Layer    Logic Layer       Data Layer
──────────────────    ───────────────   ──────────────────
Screen Widgets        State/Business    Repositories
（UI のみ担当）         Logic             （Firebase SDK 操作）
```

| 層 | 責務 | 例 |
|--|--|--|
| **Presentation** | 画面描画・ユーザー入力受付 | `HomeScreen`, `AiLabelScreen` |
| **Logic** | 状態管理・ビジネスロジック | TODO: Riverpod Providers 導入後 |
| **Data** | Firebase SDK 操作・外部 API | `RecordRepository`, `LabelRecognitionService` |

---

## 状態管理

### 現状

`StatefulWidget` + `setState` による基本的な状態管理。

### 移行計画（Phase 2）

Riverpod v2 の導入を推奨：
- `AsyncNotifierProvider` で非同期状態（Firestore 取得等）を管理
- `StreamProvider` で Firebase Auth 状態変化をリアクティブに監視
- `Provider` で依存性注入（Repository 等）

---

## ルーティング

### 現状

`MaterialApp.routes` による静的ルーティング（`app/lib/main.dart`）。

### 移行計画（Phase 2）

GoRouter 導入を推奨：
- ディープリンク対応（モバイル Phase 3 に必要）
- 宣言的ルーティングで保守性向上

---

## プラットフォーム対応状況

| プラットフォーム | Phase 1 | Phase 3 |
|--------------|---------|---------|
| Web | ✅ 対応（主） | ✅ |
| iOS | ⚪ 未対応 | ✅ 計画 |
| Android | ⚪ 未対応 | ✅ 計画 |
| macOS | ⚪ 未対応 | - |
| Windows | ⚪ 未対応 | - |
| Linux | ⚪ 未対応 | - |

---

## データフロー（AI ラベル認識）

```
AiLabelScreen
    │
    │ 1. image_picker で画像選択
    ▼
Firebase Storage
    │ Storage PUT (user_uploads/{userId}/{jobId}.jpg)
    │
    │ 2. Storage トリガー
    ▼
Cloud Functions (onImageUploaded)
    │
    │ 3. OpenAI API 呼び出し
    ▼
Firestore (ai_label_jobs/{jobId})
    │
    │ 4. クライアントがポーリングまたはリアルタイムリスナーで結果取得
    ▼
AiLabelScreen（結果表示）
```

詳細: [docs/app/ai-label-recognition.md](ai-label-recognition.md)
