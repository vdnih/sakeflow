# sakeflow ブログ アーキテクチャ

> バージョン: 1.0  
> 最終更新: 2026-04-29

---

## 技術スタック

| 項目 | 詳細 |
|-----|------|
| フレームワーク | Next.js 13.4（App Router） |
| 言語 | TypeScript 4.9 |
| CMS | microCMS（ヘッドレス CMS） |
| スタイリング | CSS Modules |
| ホスティング | Vercel |
| Node.js | >=18.x |

---

## ディレクトリ構成

```
blog/
├── app/                    # Next.js App Router
│   ├── layout.tsx          # ルートレイアウト
│   ├── page.tsx            # トップページ（記事一覧）
│   ├── not-found.tsx       # 404 ページ
│   ├── globals.css         # グローバルスタイル
│   └── articles/
│       └── [id]/           # 記事詳細ページ（TODO）
├── components/             # 共有コンポーネント（TODO）
├── libs/
│   ├── microcms.ts         # microCMS クライアント・型定義・API 関数
│   └── utils.ts            # ユーティリティ関数
├── constants/
│   └── index.ts            # 静的定数
└── public/                 # 静的アセット
    ├── sakeflow-logo.svg
    ├── ogp.png
    └── ...
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
| トップページ | SSG / ISR | 記事一覧は更新頻度が低い；高速配信 |
| 記事詳細 | SSG / ISR | 静的生成でパフォーマンス最大化 |
| カテゴリ一覧 | SSG | カテゴリは変更頻度が低い |
| 検索 | SSR または Client-side | クエリパラメータに依存 |

---

## 環境変数

| 変数名 | 説明 | 設定場所 |
|------|------|---------|
| `MICROCMS_SERVICE_DOMAIN` | microCMS サービスドメイン | Vercel 環境変数 |
| `MICROCMS_API_KEY` | microCMS API キー | Vercel 環境変数（Secret） |

---

## Vercel デプロイ

- GitHub main ブランチへの push で自動デプロイ
- `blog/` ディレクトリをルートとして設定
- `.npmrc` で Node.js バージョン固定

---

## SEO 対応

- 各ページに `metadata` エクスポートで `title`, `description` を設定
- 記事詳細ページに OGP タグ（`og:image`, `og:description`）を設定
- `robots.txt` および `sitemap.xml` の生成（TODO）
