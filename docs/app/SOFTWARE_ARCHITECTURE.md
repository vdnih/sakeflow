# sakeflow-log アプリ ソフトウェアアーキテクチャ

> バージョン: 1.2  
> 最終更新: 2026-05-03

---

## アーキテクチャ方針

### 現状（Phase 1 + デザインシステム導入完了）

feature-based ディレクトリ構成 + `core/theme/` によるデザイントークン集約完了。
`MainShell` がフローティングボトムナビゲーション（4タブ + 中央 FAB）を所有し、全タブのシェルとして機能する。

```
app/lib/
├── main.dart                       # エントリーポイント・MaterialApp（AppTheme.dark 適用）
├── firebase_options.dart           # Firebase 設定（自動生成）
├── emulator_config.dart            # ローカルエミュレータ接続（デバッグ用）
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         # カラートークン定数（kBgBase, kAccentMain, ...）
│   │   ├── app_text_styles.dart    # NotoSerifJP 見出しヘルパ
│   │   └── app_theme.dart          # ThemeData（AppTheme.dark）
│   └── widgets/
│       └── bottle_placeholder.dart # 銘柄→暗色背景マッピング
└── features/
    ├── shell/
    │   ├── main_shell.dart         # IndexedStack + FloatingBottomNav
    │   └── widgets/
    │       └── floating_bottom_nav.dart  # ピル型ナビ + 中央 FAB
    ├── home/
    │   └── home_tab.dart           # ヒーロー + 統計 + ノート一覧
    ├── map/
    │   ├── map_tab.dart            # 都道府県マップ
    │   ├── models/
    │   │   └── prefecture_stats.dart
    │   ├── services/
    │   │   └── prefecture_aggregator.dart
    │   └── utils/
    │       └── prefecture_normalizer.dart
    ├── analysis/
    │   └── analysis_tab.dart       # 🚧 別途作業中
    ├── collection/
    │   ├── collection_tab.dart     # 銘柄グリッド + カテゴリフィルター
    │   ├── models/
    │   │   └── sake.dart
    │   └── repositories/
    │       └── sake_repository.dart
    ├── tasting_note/
    │   ├── models/
    │   │   └── tasting_note.dart
    │   ├── repositories/
    │   │   └── tasting_note_repository.dart
    │   └── screens/
    │       └── tasting_note_detail_screen.dart  # ヒーロー画像 + 評価 + 保存
    └── record/
        └── ai_label_screen.dart    # ビューファインダー + ステートマシン UI
```

> 旧ファイル（`lib/home_screen.dart` / `lib/ai_label_screen.dart` / `lib/auth_gate.dart`）は
> 2026-05-03 に削除済み（[ADR-0002](../adr/0002-design-system-and-theme-architecture.md)）。

### 目標構成（Phase 2 以降）

```
app/lib/
├── main.dart
├── firebase_options.dart
├── core/                          # 共通処理
│   ├── auth/                      # ⚪ 未着手（認証ロジック切り出し）
│   ├── theme/                     # ✅ 実装済み（ADR-0002）
│   ├── widgets/                   # ✅ 実装済み（共有ウィジェット）
│   └── router/                    # ⚪ 未着手（GoRouter 移行予定）
└── features/
    ├── shell/                     # ✅ 実装済み（フローティングナビ）
    ├── home/                      # ✅ 実装済み
    ├── map/                       # ✅ 実装済み
    ├── analysis/                  # 🚧 別途作業中
    ├── collection/                # ✅ 実装済み
    ├── record/                    # ✅ AI ラベル認識実装済み
    ├── tasting_note/              # ✅ 実装済み
    ├── sake_detail/               # ⚪ 未着手
    ├── review/                    # ⚪ 未着手
    ├── profile/                   # ⚪ 未着手
    └── settings/                  # ⚪ 未着手
```

---

## デザインシステム

> 詳細な決定背景: [ADR-0002](../adr/0002-design-system-and-theme-architecture.md)

### Single Source of Truth

すべてのデザイントークンは `app/lib/core/theme/` に集約する。各 Widget は以下のいずれかの経路でのみ
スタイルを取得する。**Widget 内に色・サイズ・フォントを直書きすることは禁止。**

| 取得対象 | 経路 | 例 |
|---------|------|-----|
| Material 標準色 | `Theme.of(context).colorScheme` | `colorScheme.primary` |
| アプリ独自トークン | `app_colors.dart` の定数 | `kSurface2`, `kAccentMain` |
| 見出しタイポ | `AppTextStyles` メソッド | `AppTextStyles.headingLarge()` |

### カラートークン（ダークテーマ）

| トークン | 値 | 用途 |
|---------|-----|------|
| `kBgBase` | `#0C0C0F` | 最背面（Scaffold） |
| `kSurface1` | `#141418` | カード背面 |
| `kSurface2` | `#1C1C22` | カード本体 |
| `kSurface3` | `#252530` | ホバー状態・入力欄 |
| `kTextPrimary` | `#F0EEE8` | 本文 |
| `kTextSub` | `#8A8A96` | サブテキスト |
| `kTextMuted` | `#4A4A58` | ミュートテキスト |
| `kBorderDefault` | `rgba(255,255,255,0.08)` | 通常ボーダー |
| `kBorderHover` | `rgba(255,255,255,0.15)` | ホバー時ボーダー |
| `kAccentMain` | `#D4922A` | プライマリアクセント（アンバー） |
| `kAccentSoft` | アンバー 15% | バッジ・タグ背景 |
| `kAccentGlow` | アンバー 30% | FAB シャドウ等 |

### タイポグラフィ

| スタイル | フォント | サイズ | 太さ |
|---------|---------|-------|-----|
| `AppTextStyles.headingLarge` | Noto Serif JP | 22 | w700 |
| `AppTextStyles.headingMedium` | Noto Serif JP | 15 | w600 |
| `AppTextStyles.headingSmall` | Noto Serif JP | 13 | w600 |
| 本文 | OS デフォルト | 13–14 | w400 |
| サブテキスト | OS デフォルト | 11–12 | w400 |
| ラベル・バッジ | OS デフォルト | 9–10 | w600 |

### 形状・スペーシング規約

- **角丸**: 8 / 12 / 14 / 16 / 20 / 99 のいずれか
- **スペーシング**: 4 / 6 / 8 / 10 / 12 / 14 / 16 / 20 / 24 のいずれか
- **エレベーション**: `BoxShadow` 経由で個別指定（`Card.elevation` は 0 を維持）

### 新規 Widget 追加時のチェックリスト

- [ ] `Colors.deepPurple` 等の Material 直書きカラーを使っていない
- [ ] 色は `Theme.of(context)` または `kXxx` 定数経由
- [ ] 見出しは `AppTextStyles.heading{Large|Medium|Small}` を経由
- [ ] 角丸・スペーシングが規約値のいずれか
- [ ] 200 行を超えるなら private widget に分割

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
