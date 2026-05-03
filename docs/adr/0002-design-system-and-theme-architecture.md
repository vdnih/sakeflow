# ADR-0002: デザインシステムと Flutter テーマアーキテクチャ

- **ステータス**: 採用
- **決定日**: 2026-05-03
- **決定者**: vdnih

---

## 背景・課題

sakeflow-log の Phase 1 実装は機能優先で進めたため、UI 上に以下の負債が蓄積していた。

1. **デザイン定数の散在** — `Colors.deepPurple` / `Colors.orange` / `Colors.grey[100]` などのハードコードカラーが 8 ファイル以上に分散しており、ブランドカラーを変更すると全画面を編集する必要があった。
2. **タイポグラフィ統一なし** — `TextStyle` を画面ごとに直接記述。フォント・サイズ・太さの基準が曖昧。
3. **ブランドアイデンティティの欠如** — Material のデフォルト青/紫テーマ + オレンジ FAB という脈絡のない組み合わせで、「お酒と旅」というブランド世界観を表現できていなかった。
4. **設計レビュー軸の不在** — 新規画面追加時に「どの色を使うべきか」が決まっておらず、エージェントが毎回独自判断で実装していた。

ハンドオフバンドル `sakeflow-app-proto`（Claude Design 出力）を起点に、デザイン体系をコードで表現するアーキテクチャを定義する。

---

## 決定内容

### 方針1: デザイントークンの単一の真実の源（Single Source of Truth）

すべての色・タイポグラフィ・形状定義を **`app/lib/core/theme/`** 配下に集約する。

```
app/lib/core/theme/
├── app_colors.dart        # カラートークン定数（kBgBase, kAccentMain, ...）
├── app_text_styles.dart   # NotoSerifJP 見出しヘルパ（headingLarge / Medium / Small）
└── app_theme.dart         # ThemeData 構築（AppTheme.dark）
```

各 Widget からの参照ルール:

| 取得対象 | 推奨 | 例 |
|---------|------|-----|
| Material 標準色 | `Theme.of(context).colorScheme.primary` | AppBar、Card 等の自動継承 |
| アプリ独自トークン | `app_colors.dart` の定数を直接 import | `kSurface2`, `kTextSub` |
| 見出しタイポグラフィ | `AppTextStyles.headingLarge()` | NotoSerifJP 22px w700 |

`Colors.deepPurple` 等の Material 直書きは **禁止**（PR レビューで弾く）。

### 方針2: ダーク単一テーマ（Phase 1）

ダークテーマ（`Brightness.dark`）のみを実装する。`themeMode: ThemeMode.dark` で固定。

**採用理由:**
- ブランドコンセプト「深夜の酒場 × ミニマリズム」は黒基調が前提
- ライト/ダーク両対応はコード量・QA 範囲が倍増する
- 飲酒記録という用途上、夜間に開かれるシーンが多く、ダークテーマが体験に合致

**許容するトレードオフ:**
- 日中・屋外での視認性が落ちる可能性
- 将来ライトテーマ要望が出た際に `AppTheme.light` を追加する形で拡張する

### 方針3: ブランドカラー（アンバー）と和タイポグラフィ

| トークン | 値 | 用途 |
|---------|-----|------|
| `kBgBase` | `#0C0C0F` | 最背面 |
| `kSurface1` | `#141418` | カード背面 |
| `kSurface2` | `#1C1C22` | カード |
| `kSurface3` | `#252530` | ホバー・インプット |
| `kTextPrimary` | `#F0EEE8` | 本文 |
| `kTextSub` | `#8A8A96` | サブテキスト |
| `kTextMuted` | `#4A4A58` | ミュート |
| `kAccentMain` | `#D4922A` | プライマリアクセント（アンバー） |
| `kAccentSoft` | `#26D4922A`（15%） | バッジ・タグ背景 |
| `kAccentGlow` | `#4DD4922A`（30%） | FAB シャドウ等 |

見出しフォント: **Noto Serif JP**（`google_fonts: ^6.0.0` 経由で実行時取得）

**採用理由:**
- アンバーは琥珀色を連想させ、酒の世界観と親和する暖色系
- セリフ体（特に和文セリフ）がブランドの落ち着いた質感を表現する
- `google_fonts` は Flutter エコシステムのデファクトで保守性が高い

**許容するトレードオフ:**
- `google_fonts` は初回ロード時にネットワーク経由でフォントを取得するため、起動直後の見た目が一瞬システムフォントになる（致命的ではない）
- 将来ローカルアセット化する選択肢は残す

### 方針4: フローティングボトムナビゲーション

ボトムナビゲーションは **角丸ピル + 中央 FAB** のフローティングデザインに刷新する。

実装: `app/lib/features/shell/widgets/floating_bottom_nav.dart`

- 4 タブ（ホーム / マップ / 分析 / コレクション）+ 中央 FAB（カメラ起動）
- Stack + ClipRRect + BackdropFilter（blur 20）でガラスモーフィズム表現
- 標準の `BottomNavigationBar` は使わない

**採用理由:**
- ブランド世界観に合致するモダンな見た目
- 中央 FAB に「記録」アクションを置くことでアプリのメインタスクへの動線を強調

**許容するトレードオフ:**
- `BackdropFilter` は Flutter Web の `html` レンダラ環境で blur が劣化する。本アプリは `canvaskit`（デフォルト）想定のため許容
- 標準ウィジェットを使わない分、アクセシビリティ（フォーカス遷移）はカスタム実装が必要

---

## 結果として得られる構造

```dart
// main.dart
MaterialApp(
  theme: AppTheme.dark,
  themeMode: ThemeMode.dark,
  // ...
)

// 各 Widget では Theme.of(context) または kXxx 定数経由
backgroundColor: kBgBase,
style: AppTextStyles.headingLarge(),
```

新規画面・新規 Widget を追加する際は、以下のチェックリストを満たすこと:

- [ ] `Colors.xxx` を直書きしていない（黒/白の極端なケースを除く）
- [ ] 角丸は 8 / 12 / 14 / 16 / 20 / 99 のいずれか
- [ ] スペーシングは 4 / 6 / 8 / 10 / 12 / 14 / 16 / 20 / 24 のいずれか
- [ ] 見出しは `AppTextStyles.heading{Large|Medium|Small}` を経由

---

## 関連ドキュメント

- [docs/app/SOFTWARE_ARCHITECTURE.md](../app/SOFTWARE_ARCHITECTURE.md) — 「デザインシステム」セクション
- [CLAUDE.md](../../CLAUDE.md) — Vibe コーディングポリシー（app セクション）
