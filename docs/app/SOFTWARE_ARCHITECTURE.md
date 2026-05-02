# sakeflow-log アプリ ソフトウェアアーキテクチャ

> バージョン: 1.1  
> 最終更新: 2026-05-02

---

## アーキテクチャ方針

### 現状（Phase 1 完了）

feature-based ディレクトリ構成へ移行済み。`MainShell` がボトムナビゲーションと FAB を所有し、全タブのシェルとして機能します。

```
app/lib/
├── main.dart                    # エントリーポイント・ルーティング
├── auth_gate.dart               # 認証状態監視（MainShell へリダイレクト）
├── home_screen.dart             # 旧ホーム画面（次 PR で削除予定）
├── ai_label_screen.dart         # 旧記録画面（次 PR で削除予定）
├── firebase_options.dart        # Firebase 設定（自動生成）
├── emulator_config.dart         # ローカルエミュレータ接続（デバッグ用）
└── features/
    ├── shell/
    │   └── main_shell.dart      # ボトムナビ（4タブ）+ 記録 FAB
    ├── home/
    │   └── home_tab.dart        # ホームタブ（ユーザー情報・最近の記録）
    ├── map/
    │   └── map_tab.dart         # マップタブ（プレースホルダー）
    ├── analysis/
    │   └── analysis_tab.dart    # 分析タブ（プレースホルダー）
    ├── collection/
    │   └── collection_tab.dart  # コレクションタブ（プレースホルダー）
    └── record/
        └── ai_label_screen.dart # AI ラベル認識画面（FAB から起動）
```

### 目標構成（Phase 2 以降）

```
app/lib/
├── main.dart
├── firebase_options.dart
├── core/                          # 共通処理
│   ├── auth/
│   │   └── auth_gate.dart
│   ├── theme/                     # テーマ・カラー定義
│   └── router/                    # ルーティング定義（GoRouter 移行予定）
└── features/
    ├── shell/                     # ✅ 実装済み
    ├── home/                      # ✅ 実装済み（コンテンツ拡充予定）
    ├── map/                       # 🚧 プレースホルダー
    ├── analysis/                  # 🚧 プレースホルダー
    ├── collection/                # 🚧 プレースホルダー
    ├── record/                    # ✅ AI ラベル認識実装済み
    ├── sake_detail/               # ⚪ 未着手
    ├── review/                    # ⚪ 未着手
    ├── profile/                   # ⚪ 未着手
    └── settings/                  # ⚪ 未着手
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

| ルート | 画面 | 備考 |
|--------|------|------|
| `/login` | `SignInScreen` | Firebase UI Auth（Google OAuth） |
| `/home` | `MainShell` | ボトムナビシェル（ログイン後の起点） |

タブ間遷移は `IndexedStack` による切り替えのみ（named route 不使用）。  
記録画面（`AiLabelScreen`）は FAB から `Navigator.push` で起動。

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
