# sakeflow ブログ アーキテクチャ

> バージョン: 1.1  
> 最終更新: 2026-05-02

---

## 技術スタック

| 項目 | 詳細 |
|-----|------|
| フレームワーク | Next.js 13.4（App Router） |
| 言語 | TypeScript 4.9 |
| CMS | microCMS（ヘッドレス CMS） |
| スタイリング | CSS Modules |
| ホスティング | Firebase App Hosting |
| Node.js | >=18.x |

---

## ディレクトリ構成

```
blog/
├── app/                          # Next.js App Router
│   ├── layout.tsx                # ルートレイアウト（Header/Nav/Footer）
│   ├── page.tsx                  # トップページ（記事一覧）
│   ├── not-found.tsx             # 404 ページ
│   ├── globals.css               # グローバルスタイル
│   ├── p/
│   │   └── [current]/
│   │       └── page.tsx          # トップ一覧ページネーション
│   ├── articles/
│   │   └── [slug]/
│   │       └── page.tsx          # 記事詳細（ISR + ドラフトプレビュー対応）
│   ├── categories/
│   │   └── [categoryId]/
│   │       ├── page.tsx          # カテゴリ別記事一覧
│   │       └── p/
│   │           └── [current]/
│   │               └── page.tsx  # カテゴリ別ページネーション
│   └── search/
│       ├── page.tsx              # 全文検索結果
│       └── p/
│           └── [current]/
│               └── page.tsx      # 検索結果ページネーション
├── components/                   # 共有コンポーネント
│   ├── Header/
│   ├── Footer/
│   ├── Navigation/
│   ├── ArticleList/
│   ├── Pagination/
│   └── SearchField/
├── libs/
│   ├── microcms.ts               # microCMS クライアント・型定義・API 関数
│   └── utils.ts                  # ユーティリティ関数（コードハイライト等）
├── constants/
│   └── index.ts                  # 静的定数（ページあたり記事数等）
├── public/                       # 静的アセット
│   ├── sakeflow-logo.svg
│   ├── ogp.png
│   └── ...
└── apphosting.yaml               # Firebase App Hosting 設定
```

---

## microCMS 連携

### クライアント設定（`blog/libs/microcms.ts`）

```typescript
const client = createClient({
  serviceDomain: process.env.MICROCMS_SERVICE_DOMAIN,  // 必須
  apiKey: process.env.MICROCMS_API_KEY,                 // 必須
});
```

### 主要関数

| 関数名 | 説明 | エンドポイント |
|------|------|--------------|
| `getList(queries?)` | 記事一覧取得 | `GET /blogs` |
| `getDetail(id, queries?)` | 記事詳細取得 | `GET /blogs/{id}` |
| `getCategoryList()` | カテゴリ一覧取得 | `GET /categories` |
| `getCategory(id)` | カテゴリ詳細取得 | `GET /categories/{id}` |

### 型定義

```typescript
type Category = { name: string; value: string } & MicroCMSContentId & MicroCMSDate;
type Writer   = { name: string; profile: string; image?: MicroCMSImage } & MicroCMSContentId & MicroCMSDate;
type Blog     = { title: string; content: string; thumbnail?: MicroCMSImage; category: Category; writer: Writer; description: string };
type Article  = Blog & MicroCMSContentId & MicroCMSDate;  // 記事取得時の型
```

---

## データ取得戦略

| ページ | 戦略 | 理由 |
|------|------|------|
| トップページ・ページネーション | ISR（60s） | 記事一覧は更新頻度が低い；高速配信 |
| 記事詳細 | ISR（60s） + ドラフトプレビュー | 静的生成でパフォーマンス最大化；`dk` パラメータでプレビュー |
| カテゴリ別一覧 | ISR（60s） | カテゴリは変更頻度が低い |
| 検索 | SSR（Client-side fetch） | クエリパラメータに依存 |

---

## 環境変数

| 変数名 | 説明 | 設定場所 |
|------|------|---------|
| `MICROCMS_SERVICE_DOMAIN` | microCMS サービスドメイン | Firebase Secret Manager（`apphosting.yaml` 経由） |
| `MICROCMS_API_KEY` | microCMS API キー | Firebase Secret Manager（`apphosting.yaml` 経由） |
| `BASE_URL` | サイトの公開 URL | `apphosting.yaml` の `env.value` |

---

## Firebase App Hosting デプロイ

### 設定ファイル（`blog/apphosting.yaml`）

Firebase App Hosting のバックエンド設定。シークレットは Secret Manager を参照し、ビルド時・実行時の両方で利用可能にする。

```yaml
runConfig:
  runtime: nodejs20

env:
  - variable: MICROCMS_SERVICE_DOMAIN
    secret: MICROCMS_SERVICE_DOMAIN
    availability:
      - BUILD
      - RUNTIME

  - variable: MICROCMS_API_KEY
    secret: MICROCMS_API_KEY
    availability:
      - BUILD
      - RUNTIME

  - variable: BASE_URL
    value: https://blog.sakeflow.jp
    availability:
      - BUILD
      - RUNTIME
```

### バックエンド登録手順（初回のみ・手動）

```bash
# 1. Secret Manager にシークレットを登録
firebase apphosting:secrets:set MICROCMS_SERVICE_DOMAIN
firebase apphosting:secrets:set MICROCMS_API_KEY

# 2. App Hosting バックエンドを作成（Firebase コンソール推奨）
#    - GitHub リポジトリを接続
#    - ルートディレクトリ: blog/
#    - デプロイ対象ブランチ: main
```

### デプロイフロー

- `main` ブランチへの push で自動ビルド・デプロイ
- Firebase App Hosting が Next.js を自動検出し、SSR/ISR/App Router をネイティブサポート

---

## SEO 対応

- 各ページに `generateMetadata` で `title`, `description` を設定
- 記事詳細ページに OGP タグ（`og:image`, `og:description`）を設定
- `robots.txt` および `sitemap.xml` の生成（TODO: Phase 2）
