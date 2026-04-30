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

    // ローカルエミュレータでは AI 呼び出しをスキップしてモックデータを返す
    // VertexAI 移行後もこのパターンを維持すること
    if (process.env.FUNCTIONS_EMULATOR === "true") {
      await jobRef.update({
        status: "success",
        user_id: userId,
        result: {
          brand: "テスト日本酒",
          brewery: "テスト酒造",
          tags: ["純米大吟醸", "山田錦", "精米歩合50%"],
        },
        updated_at: new Date(),
      });
      return;
    }

    try {
      // 画像をバッファとして取得
      const bucket = getStorage().bucket();
      const file = bucket.file(filePath);
      const [buffer] = await file.download();
      const base64Image = buffer.toString("base64");

      const openai = new OpenAI({
        apiKey: openAiKey.value(),
      });

      const userPrompt =
        "添付された日本酒のラベル画像から、銘柄(brand)と蔵元(brewery)を読み取ってください。" +
        "それ以外のスペック（特定名称、酒米、精米歩合、製法、フレーバーなど）はすべて tags 配列に抽出してください。" +
        "値が読み取れない場合は空文字または空配列にしてください。";

      // OpenAI Vision API呼び出し（Structured Outputs）
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              {type: "text", text: userPrompt},
              {
                type: "image_url",
                image_url: {url: `data:image/jpeg;base64,${base64Image}`},
              },
            ],
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "sake_label",
            strict: true,
            schema: {
              type: "object",
              properties: {
                brand: {
                  type: "string",
                  description: "日本酒の銘柄名（例：獺祭、新政）",
                },
                brewery: {
                  type: "string",
                  description: "蔵元の名前（例：旭酒造、新政酒造）",
                },
                tags: {
                  type: "array",
                  items: {type: "string"},
                  description: "特定名称・酒米・精米歩合・製法・フレーバー等のスペック",
                },
              },
              required: ["brand", "brewery", "tags"],
              additionalProperties: false,
            },
          },
        },
        max_tokens: 1024,
      });

      const raw = response.choices[0].message?.content ?? "{}";
      const {brand, brewery, tags} = JSON.parse(raw) as {
        brand: string;
        brewery: string;
        tags: string[];
      };

      // Firestoreに構造化 map として保存
      await jobRef.update({
        status: "success",
        user_id: userId,
        result: {brand, brewery, tags},
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
