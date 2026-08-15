# app リファクタリング提案

> 作成: 2026-08-15  
> 位置づけ: 提案のみ。本ドキュメント自体はコードを変更しない。着手する際は該当項目を GitHub Issue化し、この表の行を Issue へのリンクに置き換える。

開発再開に向けた棚卸しの過程で見つかった、実装済みだが積み残されている改善項目。優先度は「触ったときに事故りやすい／ユーザー影響が大きい」順。

## 1. 200行超ウィジェットの分割

CLAUDE.md 自身のルール（「ウィジェットが 200 行を超えたら分割する」）に違反している画面が7つある。重い順：

| ファイル | 行数 | 備考 |
|---|---|---|
| `app/lib/features/tasting_note/screens/tasting_note_detail_screen.dart` | 704 | 表示・編集・削除確認ダイアログが1ファイルに同居。最優先候補 |
| `app/lib/features/home/home_tab.dart` | 509 | |
| `app/lib/features/record/ai_label_screen.dart` | 428 | AI解析中の状態遷移が多く、UIとロジックが混在 |
| `app/lib/features/collection/collection_tab.dart` | 343 | |
| `app/lib/features/analysis/screens/taste_dashboard_screen.dart` | 251 | |
| `app/lib/features/analysis/screens/ai_suggestion_screen.dart` | 232 | |
| `app/lib/features/map/map_tab.dart` | 210 | |

**進め方**: CLAUDE.md の既存方針通り、機能追加のついでに分割しない。分割は独立した PR で行う。まず `tasting_note_detail_screen.dart` から着手し、表示部分・編集フォーム・削除確認ダイアログをサブウィジェットに切り出す。

## 2. UI層のテスト空白

`docs/app/TESTING_POLICY.md` は Widget 25% / E2E 5% を目標に掲げているが、実態は乖離している。

- ウィジェットテストは `app/test/widget_test.dart`（`BottlePlaceholder` のみ）しか無い。項目1で分割する7画面には1つもテストが無い。
- `app/integration_test/` ディレクトリ自体が存在せず、E2E は 0%。
- PR #24 で追加された `TastingNoteRepository.deleteNote()` / `SakeRepository.decrementOrDeleteSake()` にもリポジトリ層のユニットテストが無い（`app/test/features/tasting_note/repositories/tasting_note_repository_test.dart` / `app/test/features/collection/repositories/sake_repository_test.dart` に追加余地あり）。

**進め方**: 項目1の分割とセットで進めるのが安い（サブウィジェットに切り出した時点でテストも書く）。まずは削除フローのリポジトリ層テスト追加が最小コストで効果が高い。

## 3. Google Sign-In のプレースホルダ

`app/lib/main.dart:33` の `GoogleProvider(clientId: 'YOUR_GOOGLE_CLIENT_ID')` が未設定のまま。Web では `firebase_options.dart` 経由の設定で動作している可能性が高いが未検証。モバイル対応（iOS/Android）に着手する際は確実に踏むので、その前に実際のクライアント ID を設定するか、Web 専用なら該当行を削除して意図を明示する。

## 4. blog（Next.js 13）のバージョン更新

`blog/` は Next.js 13.4（App Router）のまま、実質1年以上依存更新が無い。15系への更新は App Router 前提のため移行難度は中程度。

**前提条件**: 更新前に最低限の CI（項目5）を入れる。テスト・CIが無い状態でのメジャーバージョン更新はリグレッションに気付けない。着手時は ADR を起票する。

## 5. blog の CI 不在

モノレポなのに `.github/workflows/ci.yml`（Flutter 用）は `app/` しか対象にしていない。`blog/` には lint も build も検証する CI が無い。最低限 `npm run build` が通ることを検証する workflow を追加する。
