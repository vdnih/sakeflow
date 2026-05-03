# sakeflow

sakeflowはお酒や旅を楽しむためのブランドです。

- **sakeflow** ブログサイトでは、旅行やお酒に関する情報を発信しています。
- **sakeflow-log** は、飲んだお酒を記録できるアプリです。

## ディレクトリ構成

```
sakeflow/
├── app/                       # Flutter製アプリ本体（Firebase Hosting対象）
│   ├── lib/
│   ├── build/
│   └── ...
│
├── blog/                      # ブランドサイト（Next.js、Vercelでホスティング）
│   └── ...
│
├── functions/                 # Firebase Functions（OpenAI連携など）
│   └── src/
│
├── docs/                      # 要件・設計・GA設計など（Cursorで管理）
│   └── ...
│
├── .github/workflows/         # GitHub Actions（Firebase deploy用）
├── firebase.json              # Firebase Hosting/Functions設定
├── .firebaserc                # Firebaseプロジェクト接続情報
└── README.md
```

### 各ディレクトリの説明
- **app/**: Flutter製のアプリ本体。Firebase Hostingでホスティングされます。
- **blog/**: ブランドサイト（Next.js製）。Vercelでホスティングされます。
- **functions/**: Firebase Functionsのコード（OpenAI連携などを含む）。
- **docs/**: 要件定義・設計・Google Analytics設計などのドキュメント。Cursorで管理。
- **.github/workflows/**: GitHub Actionsのワークフロー定義（Firebaseデプロイ用）。
- **firebase.json**: Firebase HostingやFunctionsの設定ファイル。
- **.firebaserc**: Firebaseプロジェクトの接続情報。
- **cors.json**: Firebase Storage バケットの CORS 設定。

## Firebase Storage の CORS 設定

Flutter Web (CanvasKit) から `Image.network` で Storage 上の画像を取得する際、ブラウザは XHR + Range リクエストを送るため、バケット側に CORS 設定が必要です。
バケットに CORS 設定が無いと `Access-Control-Allow-Origin` エラーで画像表示が失敗します。

`cors.json` を変更した際は、以下のコマンドで Storage バケットに反映してください。

```bash
gcloud storage buckets update gs://sakeflow.firebasestorage.app --cors-file=cors.json
# もしくは
gsutil cors set cors.json gs://sakeflow.firebasestorage.app
```

設定確認:

```bash
gcloud storage buckets describe gs://sakeflow.firebasestorage.app --format="default(cors_config)"
```
