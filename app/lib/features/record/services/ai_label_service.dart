import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

// ─── モデル ───────────────────────────────────────────────────────────

class SakeLabelData {
  final String brand;
  final String brewery;
  final String prefecture;
  final List<String> tags;

  const SakeLabelData({
    required this.brand,
    required this.brewery,
    required this.prefecture,
    required this.tags,
  });
}

// ─── スキーマ／プロンプト（Vertex AI 用）────────────────────────────────

final _sakeLabelSchema = Schema.object(
  properties: {
    'brand': Schema.string(description: '日本酒の銘柄名（例：獺祭、新政）'),
    'brewery': Schema.string(description: '蔵元の名前（例：旭酒造、新政酒造）'),
    'prefecture': Schema.string(
        description: '蔵元の所在都道府県。正式名称（例：京都府、新潟県）'),
    'tags': Schema.array(
      items: Schema.string(),
      description: '特定名称・酒米・精米歩合・製法・フレーバー等のスペック',
    ),
  },
);

const _labelPrompt =
    '添付された日本酒のラベル画像から、銘柄(brand)・蔵元(brewery)・'
    '蔵元の所在都道府県(prefecture)を読み取ってください。'
    '都道府県は「青森県」「京都府」「東京都」「大阪府」のような正式名称で返してください。'
    'それ以外のスペック（特定名称、酒米、精米歩合、製法、フレーバーなど）はすべて tags 配列に抽出してください。'
    '値が読み取れない場合は空文字または空配列にしてください。';

// ─── インターフェース ──────────────────────────────────────────────────

/// AI ラベル解析サービスのインターフェース。
///
/// [AiLabelService.create] ファクトリで実装を切り替える:
///   - `--dart-define=USE_MOCK_AI=true` → モック（テスト・ローカル開発用）
///   - デフォルト → Vertex AI（本番）
///   - `useMock: true/false` を直接渡すことも可（単体テスト向け）
abstract class AiLabelService {
  Future<SakeLabelData> analyzeLabel(Uint8List imageBytes);

  factory AiLabelService.create({bool? useMock}) {
    final mock = useMock ??
        const bool.fromEnvironment('USE_MOCK_AI', defaultValue: false);
    return mock ? _MockAiLabelService() : _VertexAiLabelService();
  }
}

// ─── 本番実装（Vertex AI）────────────────────────────────────────────

class _VertexAiLabelService implements AiLabelService {
  @override
  Future<SakeLabelData> analyzeLabel(Uint8List imageBytes) async {
    final model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _sakeLabelSchema,
      ),
    );

    final response = await model.generateContent([
      Content.multi([
        TextPart(_labelPrompt),
        InlineDataPart('image/jpeg', imageBytes),
      ]),
    ]);

    final raw =
        jsonDecode(response.text ?? '{}') as Map<String, dynamic>;
    return SakeLabelData(
      brand: raw['brand'] as String? ?? '',
      brewery: raw['brewery'] as String? ?? '',
      prefecture: raw['prefecture'] as String? ?? '',
      tags: List<String>.from(raw['tags'] as List? ?? []),
    );
  }
}

// ─── モック実装（テスト・ローカル開発用）──────────────────────────────

class _MockAiLabelService implements AiLabelService {
  @override
  Future<SakeLabelData> analyzeLabel(Uint8List imageBytes) async {
    // 実際の解析時間を模倣
    await Future.delayed(const Duration(milliseconds: 800));
    return const SakeLabelData(
      brand: '獺祭',
      brewery: '旭酒造',
      prefecture: '山口県',
      tags: ['純米大吟醸', '磨き二割三分', '精米歩合23%', 'フルーティ'],
    );
  }
}
