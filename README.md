# sakeflow

sakeflowはお酒や旅を楽しむためのブランドです。

- **sakeflow** ブログサイトでは、旅行やお酒に関する情報を発信しています。
- **sakeflow-log** は、飲んだお酒を記録できるアプリです。

## ディレクトリ構成

```
sakeflow/
├── apps/
│   └── sakeflow_log/          # Flutter製アプリ本体（Firebase Hosting対象）
│       ├── lib/
│       ├── build/
│       └── ...
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
- **apps/sakeflow_log/**: Flutter製のアプリ本体。Firebase Hostingでホスティングされます。
- **blog/**: ブランドサイト（Next.js製）。Vercelでホスティングされます。
- **functions/**: Firebase Functionsのコード（OpenAI連携などを含む）。
- **docs/**: 要件定義・設計・Google Analytics設計などのドキュメント。Cursorで管理。
- **.github/workflows/**: GitHub Actionsのワークフロー定義（Firebaseデプロイ用）。
- **firebase.json**: Firebase HostingやFunctionsの設定ファイル。
- **.firebaserc**: Firebaseプロジェクトの接続情報。
