/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {onObjectFinalized} from "firebase-functions/v2/storage";
import {getFirestore} from "firebase-admin/firestore";
import {initializeApp} from "firebase-admin/app";
import {OpenAI} from "openai";
// import * as functions from "firebase-functions";
import {getStorage} from "firebase-admin/storage";
import {defineSecret} from "firebase-functions/params";

initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

const openAiKey = defineSecret("OPENAI_API_KEY");

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

export const onImageUploaded = onObjectFinalized(
  {secrets: [openAiKey]},
  async (event) => {
    const filePath = event.data.name;
    if (!filePath) return;

    // user_uploads/{userId}/{jobId}.jpg の形式かチェック
    const match = filePath.match(/^user_uploads\/([^/]+)\/([^.]+)\.jpg$/);
    if (!match) return;
    const userId = match[1];
    const jobId = match[2];

    const firestore = getFirestore();
    const jobRef = firestore.collection("ai_label_jobs").doc(jobId);

    try {
      // 画像をバッファとして取得
      const bucket = getStorage().bucket();
      const file = bucket.file(filePath);
      const [buffer] = await file.download();
      const base64Image = buffer.toString("base64");

      const openai = new OpenAI({
        apiKey: openAiKey.value(),
      });

      const systemPrompt = `
  あなたは画像からお酒の情報を抽出するAIアシスタントです。
  結果は必ずJSON形式で出力してください。
  `;

      const userPrompt = `
  この画像に写っているお酒の銘柄名（日本語、英語）、カテゴリ名（お酒の種類）、
  特徴的なタグを抽出し、次の形式でJSONで返してください：

  {
    "name_jp": "獺祭 純米大吟醸 45",
    "name_en": "Dassai Junmai Daiginjo 45",
    "category_name": "日本酒",
    "tags": ["旭酒造", "山口県", "純米大吟醸", "山田錦", "フルーティー"]
  }

  カテゴリ名は以下の選択肢から必ず1つ選んでください：
  [
    "日本酒", 
    "ワイン", 
    "ビール", 
    "ウイスキー", 
    "焼酎", 
    "リキュール", 
    "ブランデー", 
    "ジン", 
    "ウォッカ", 
    "ラム", 
    "その他"
  ]

  タグには、そのお酒の銘柄に関する様々な情報を含めてください。（例：分類、生産者、味わい、特徴 など。）

  JSON以外の文字列は含めず、値が不明な場合は null または空の配列にしてください。
  `;

      // OpenAI Vision API呼び出し
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: userPrompt,
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`,
                },
              },
            ],
          },
        ],
        max_tokens: 1024,
      });
      const result = response.choices[0].message?.content;

      // Firestoreに結果を保存
      await jobRef.update({
        status: "success",
        user_id: userId,
        result: result,
        updated_at: new Date(),
      });
    } catch (e) {
      await jobRef.update({
        status: "failed",
        user_id: userId,
        error: e instanceof Error ? e.message : String(e),
        updated_at: new Date(),
      });
    }
  }
);
