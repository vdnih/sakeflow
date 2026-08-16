# CLAUDE.md

Claude Code がこのリポジトリで作業するためのガイド。

**このファイルには「めったに変わらない構造の事実」と「守るべき少数のルール」だけを書く。**
件数・行数・ファイル一覧・依存パッケージのバージョンのような増減する情報は書かない（コードが唯一の情報源）。

## 1. プロジェクト概要

sakeflow はお酒と旅を楽しむためのブランド。モノレポで2コンポーネントを管理する。

| コンポーネント | 概要 | デプロイ |
|---|---|---|
| `app/` | 飲んだお酒を記録する Flutter 製アプリ（sakeflow-log） | Firebase Hosting |
| `blog/` | Next.js 製ブランドサイト（microCMS 連携） | Firebase App Hosting（rootDir: `blog/`） |

`functions/` は Firebase AI Logic への全面移行（ADR-0003）に伴い廃止済み。存在しない。

- なぜこのプロダクトか → `docs/PRODUCT_VISION.md`
- 何の機能があるか → `docs/PRD.md` / `docs/app/PRD.md` / `docs/blog/PRD.md`
- **実装の詳細は常にコード（`app/lib/`, `blog/`）を正とする。**

## 2. コマンド

```bash
# app（Flutter）
cd app
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK_AI=true   # AI をモックしてローカル起動
flutter analyze
flutter test
firebase emulators:start --only auth,firestore,storage # ログイン等の動作確認に必要

# blog（Next.js）
cd blog
npm run dev
npm run build
```

デプロイは `main` への push で GitHub Actions が自動実行する（`app/` は Firebase Hosting、`blog/` は App Hosting）。

## 3. アーキテクチャ

`app/lib/features/{home, record, collection, tasting_note, analysis, map, shell}/` の feature 単位構成（models/repositories/services/screens）。`lib` 直下は `main.dart` / `firebase_options.dart` / `emulator_config.dart` のみ。

状態管理・ルーティングは `StatefulWidget` + `setState`、`MaterialApp.routes` を正式採用（[ADR-0004](docs/adr/0004-state-management-and-routing.md)）。riverpod・go_router は導入しない。画面をまたぐ状態共有やネストしたルーティングが必要になったら ADR を起票して判断し直す。

## 4. 知らないと事故るもの

- **AI 解析は Firebase AI Logic（`FirebaseAI.googleAI()`）** 経由。OpenAI ではない（ADR-0003 で全面移行済み。CLAUDE.md やコード内コメントが OpenAI 時代のままの箇所があれば古い）。使用モデル名は `app/lib/features/record/services/ai_label_service.dart` と `app/lib/features/analysis/services/taste_analysis_service.dart` を見ること。
- **`--dart-define=USE_MOCK_AI=true` でモック AI に切り替わる。** ローカル確認・単体テストで使う。
- **ウィジェットが 200 行を超えたら分割する。** 守れていないファイルが複数残っている（Issue #38）。新規追加のついでに分割せず、分割は独立した PR で行う。
- **ログイン確認には Firebase エミュレータが要る。** `firebase emulators:start --only auth,firestore,storage` を起動してから `flutter run` すること。

## 5. Git と経緯の残し方

- `main` への直接コミットはしない。`claude/<内容がわかる名前>` ブランチ → PR → squash merge。
- commit prefix は `feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `chore:`。スコープは `(app)` / `(blog)` / `(docs)`。
- PR 説明は `.github/pull_request_template.md`（`## なぜ` / `## 何をしたか` / `## 検討したが採らなかった案` / `## 検証`）に従う。
- 後戻りしにくい技術判断は `docs/adr/NNNN-kebab-case-title.md` に残す（**4桁採番**。既存の 0001〜 を継続する）。
- 残課題・後続タスクは GitHub Issue で管理する。ドキュメントのステータス表を第二のバックログにしない。

## 6. ドキュメント

| 知りたいこと | 参照先 |
|---|---|
| なぜこのプロダクトか | `docs/PRODUCT_VISION.md` |
| 機能一覧・実装状況 | `docs/PRD.md`, `docs/feature_registry.md` |
| テスト方針 | `docs/app/TESTING_POLICY.md` |
| アーキテクチャ | `docs/ARCHITECTURE.md`, `docs/app/SOFTWARE_ARCHITECTURE.md`, `docs/blog/ARCHITECTURE.md` |
| なぜその設計にしたか | `docs/adr/` |
| 意思決定・変更の記録 | `docs/audit_log.md` |

設計ドキュメントとコードが食い違っていたら、**コードが正**。気付いた時点でドキュメント側を直すか、直せない場合は PR 説明に食い違いを記録する。
