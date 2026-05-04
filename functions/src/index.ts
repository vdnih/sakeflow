/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest, onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {onObjectFinalized} from "firebase-functions/v2/storage";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {initializeApp} from "firebase-admin/app";
import {OpenAI} from "openai";
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

    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
    const useRealAI = process.env.USE_REAL_AI === "true";

    // エミュレータ かつ USE_REAL_AI=true でない場合はモックデータを返す
    if (isEmulator && !useRealAI) {
      await jobRef.update({
        status: "success",
        user_id: userId,
        result: {
          brand: "テスト日本酒",
          brewery: "テスト酒造",
          prefecture: "新潟県",
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

      // エミュレータ時は process.env.OPENAI_API_KEY (.env.local) を使用
      const openai = new OpenAI({
        apiKey: isEmulator ? process.env.OPENAI_API_KEY : openAiKey.value(),
      });

      const userPrompt =
        "添付された日本酒のラベル画像から、銘柄(brand)・蔵元(brewery)・" +
        "蔵元の所在都道府県(prefecture)を読み取ってください。" +
        "都道府県は「青森県」「京都府」「東京都」「大阪府」のような正式名称で返してください。" +
        "それ以外のスペック（特定名称、酒米、精米歩合、製法、フレーバーなど）はすべて tags 配列に抽出してください。" +
        "値が読み取れない場合は空文字または空配列にしてください。";

      // OpenAI Vision API呼び出し（Structured Outputs）
      const response = await openai.chat.completions.create({
        model: "gpt-5.4-mini",
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
                prefecture: {
                  type: "string",
                  description: "蔵元の所在都道府県（例：京都府、新潟県）。正式名称",
                },
                tags: {
                  type: "array",
                  items: {type: "string"},
                  description: "特定名称・酒米・精米歩合・製法・フレーバー等のスペック",
                },
              },
              required: ["brand", "brewery", "prefecture", "tags"],
              additionalProperties: false,
            },
          },
        },
        max_completion_tokens: 1024,
      });

      const raw = response.choices[0].message?.content ?? "{}";
      const {brand, brewery, prefecture, tags} = JSON.parse(raw) as {
        brand: string;
        brewery: string;
        prefecture: string;
        tags: string[];
      };

      // Firestoreに構造化 map として保存
      await jobRef.update({
        status: "success",
        user_id: userId,
        result: {brand, brewery, prefecture, tags},
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

export const analyzeTaste = onCall(
  {secrets: [openAiKey]},
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }

    const firestore = getFirestore();
    const sakesCol = firestore
      .collection("users")
      .doc(userId)
      .collection("sakes");

    const [byCountSnap, byRatingSnap] = await Promise.all([
      sakesCol.orderBy("tasting_count", "desc").limit(10).get(),
      sakesCol
        .where("avg_rating", ">", 0)
        .orderBy("avg_rating", "desc")
        .limit(10)
        .get(),
    ]);

    const topByCount = byCountSnap.docs.map((d) => {
      const x = d.data();
      return {
        brand: x.brand ?? "",
        brewery: x.brewery ?? "",
        prefecture: x.prefecture ?? "",
        tasting_count: x.tasting_count ?? 0,
        avg_rating: x.avg_rating ?? null,
      };
    });
    const topByRating = byRatingSnap.docs.map((d) => {
      const x = d.data();
      return {
        brand: x.brand ?? "",
        brewery: x.brewery ?? "",
        prefecture: x.prefecture ?? "",
        avg_rating: x.avg_rating ?? 0,
        tasting_count: x.tasting_count ?? 0,
      };
    });

    if (topByCount.length === 0 && topByRating.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "分析するための飲酒記録がまだありません"
      );
    }

    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
    const useRealAI = process.env.USE_REAL_AI === "true";

    if (isEmulator && !useRealAI) {
      return {
        tendency:
          "（モック）フルーティで香り高い純米大吟醸系を好む傾向があります。" +
          "新潟・山形など東日本の蔵元が多めです。",
        suggestions: [
          {
            brand: "而今",
            reason: "華やかな香りとジューシーな旨みでお好みに合いそうです",
            category_or_style: "純米吟醸",
          },
          {
            brand: "鳳凰美田",
            reason: "フルーティ系の代表格、上位銘柄と方向性が近い",
            category_or_style: "純米大吟醸",
          },
          {
            brand: "風の森",
            reason: "微発泡感とフレッシュさで新しい体験になりそう",
            category_or_style: "純米しぼり華",
          },
        ],
      };
    }

    const openai = new OpenAI({
      apiKey: isEmulator ? process.env.OPENAI_API_KEY : openAiKey.value(),
    });

    const userPrompt =
      "あなたは日本酒に詳しいソムリエです。" +
      "ユーザーの飲酒履歴ランキングから好みの傾向を読み取り、" +
      "次に飲むと喜びそうな日本酒を3〜5件提案してください。" +
      "ランキング:\n" +
      JSON.stringify({topByCount, topByRating}, null, 2);

    const response = await openai.chat.completions.create({
      model: "gpt-5.4-mini",
      messages: [{role: "user", content: userPrompt}],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "taste_analysis",
          strict: true,
          schema: {
            type: "object",
            properties: {
              tendency: {
                type: "string",
                description: "ユーザーの好みの傾向を日本語で2-3文",
              },
              suggestions: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    brand: {type: "string", description: "推薦銘柄名"},
                    reason: {type: "string", description: "推薦理由（日本語）"},
                    category_or_style: {
                      type: "string",
                      description: "特定名称や系統（純米大吟醸 / 生酛 等）",
                    },
                  },
                  required: ["brand", "reason", "category_or_style"],
                  additionalProperties: false,
                },
              },
            },
            required: ["tendency", "suggestions"],
            additionalProperties: false,
          },
        },
      },
      max_completion_tokens: 1024,
    });

    const raw = response.choices[0].message?.content ?? "{}";
    return JSON.parse(raw);
  }
);

export const onAiLabelJobCompleted = onDocumentUpdated(
  "ai_label_jobs/{jobId}",
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    if (!after || !before) return;

    // status が success に変わった場合のみ処理
    if (before.status === "success" || after.status !== "success") return;

    const userId = after.user_id as string;
    const jobId = event.params.jobId;
    const result = after.result as {
      brand: string;
      brewery: string;
      prefecture: string;
      tags: string[];
    } | undefined;
    if (!result) return;

    const firestore = getFirestore();
    const drankAt = after.created_at as Timestamp;

    // job_id が一致する tasting_note を検索
    const notesSnap = await firestore
      .collection("users")
      .doc(userId)
      .collection("tasting_notes")
      .where("job_id", "==", jobId)
      .limit(1)
      .get();

    if (notesSnap.empty) {
      logger.warn(`tasting_note not found for job_id=${jobId}`);
      return;
    }

    const noteRef = notesSnap.docs[0].ref;
    const noteData = notesSnap.docs[0].data();
    const imageUrl = noteData.image_url as string;

    // sakes コレクションで brand + user が一致するものを検索
    const sakesSnap = await firestore
      .collection("users")
      .doc(userId)
      .collection("sakes")
      .where("brand", "==", result.brand)
      .limit(1)
      .get();

    const now = new Date();
    const batch = firestore.batch();

    let sakeId: string;
    if (!sakesSnap.empty) {
      // 既存銘柄: tasting_count をインクリメント、last_drank_at を更新
      const sakeRef = sakesSnap.docs[0].ref;
      sakeId = sakesSnap.docs[0].id;
      batch.update(sakeRef, {
        brewery: result.brewery,
        prefecture: result.prefecture,
        image_url: imageUrl,
        tasting_count: FieldValue.increment(1),
        last_drank_at: drankAt,
        updated_at: now,
      });
    } else {
      // 新規銘柄を作成
      sakeId = firestore
        .collection("users")
        .doc(userId)
        .collection("sakes")
        .doc().id;
      const sakeRef = firestore
        .collection("users")
        .doc(userId)
        .collection("sakes")
        .doc(sakeId);
      batch.set(sakeRef, {
        sake_id: sakeId,
        user_id: userId,
        brand: result.brand,
        brewery: result.brewery,
        prefecture: result.prefecture,
        category: "sake",
        image_url: imageUrl,
        tasting_count: 1,
        first_drank_at: drankAt,
        last_drank_at: drankAt,
        created_at: now,
        updated_at: now,
      });
    }

    // tasting_note を ready 状態に更新
    batch.update(noteRef, {
      status: "ready",
      sake_id: sakeId,
      brand: result.brand,
      brewery: result.brewery,
      prefecture: result.prefecture,
      tags: result.tags,
      updated_at: now,
    });

    await batch.commit();
    logger.info(`tasting_note updated: noteId=${noteRef.id}, sakeId=${sakeId}`);
  }
);
