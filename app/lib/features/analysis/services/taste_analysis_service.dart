import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../repositories/analysis_repository.dart';
import '../../collection/models/sake.dart';

// AI レスポンス スキーマ
final _tasteAnalysisSchema = Schema.object(
  properties: {
    'tendency': Schema.string(
        description: 'ユーザーの好みの傾向を日本語で2-3文'),
    'suggestions': Schema.array(
      items: Schema.object(
        properties: {
          'brand': Schema.string(description: '推薦銘柄名'),
          'reason': Schema.string(description: '推薦理由（日本語）'),
          'category_or_style': Schema.string(
              description: '特定名称や系統（純米大吟醸 / 生酛 等）'),
        },
      ),
    ),
  },
);

class TasteSuggestion {
  final String brand;
  final String reason;
  final String categoryOrStyle;

  TasteSuggestion({
    required this.brand,
    required this.reason,
    required this.categoryOrStyle,
  });

  factory TasteSuggestion.fromMap(Map<String, dynamic> m) => TasteSuggestion(
        brand: m['brand'] as String? ?? '',
        reason: m['reason'] as String? ?? '',
        categoryOrStyle: m['category_or_style'] as String? ?? '',
      );
}

class TasteAnalysisResult {
  final String tendency;
  final List<TasteSuggestion> suggestions;

  TasteAnalysisResult({required this.tendency, required this.suggestions});
}

class TasteAnalysisService {
  final _analysisRepo = AnalysisRepository();
  final bool _useMock;

  /// [useMock] を省略すると `--dart-define=USE_MOCK_AI=true` の値を使用する。
  /// 単体テスト時は `TasteAnalysisService(useMock: true)` で直接指定可能。
  TasteAnalysisService({bool? useMock})
      : _useMock = useMock ??
            const bool.fromEnvironment('USE_MOCK_AI', defaultValue: false);

  Future<TasteAnalysisResult> analyze() async {
    if (_useMock) return _mockResult();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('ログインが必要です');

    // Firestore から上位銘柄を取得（既存 AnalysisRepository を再利用）
    final topByCount = await _analysisRepo.rankByCount(userId).first;
    final topByRating = await _analysisRepo.rankByRating(userId).first;

    if (topByCount.isEmpty && topByRating.isEmpty) {
      throw Exception('分析するための飲酒記録がまだありません');
    }

    // プロンプト構築
    final prompt = _buildPrompt(topByCount, topByRating);

    // firebase_ai で解析
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _tasteAnalysisSchema,
      ),
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final raw =
        jsonDecode(response.text ?? '{}') as Map<String, dynamic>;

    final suggestions = (raw['suggestions'] as List? ?? [])
        .map((e) => TasteSuggestion.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return TasteAnalysisResult(
      tendency: raw['tendency'] as String? ?? '',
      suggestions: suggestions,
    );
  }

  // ─── モックデータ ────────────────────────────────────────────────────

  Future<TasteAnalysisResult> _mockResult() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return TasteAnalysisResult(
      tendency: 'フルーティで軽快な純米大吟醸を好む傾向があります。'
          '特に山口県・秋田県の蔵元を高く評価しており、'
          '香りが華やかで後味がすっきりしたタイプが好みのようです。',
      suggestions: [
        TasteSuggestion(
          brand: '新政 No.6',
          reason: '現代的な秋田酵母で醸した純米酒。クリーンな酸味とフルーティな香りが特徴で、あなたの好みにマッチします。',
          categoryOrStyle: '純米酒',
        ),
        TasteSuggestion(
          brand: '十四代 龍の落とし子',
          reason: '山形を代表する人気銘柄。華やかな吟醸香と上品な甘みが、軽快な飲み口を好むあなたに合います。',
          categoryOrStyle: '純米大吟醸',
        ),
        TasteSuggestion(
          brand: '鍋島 Special Yellow Label',
          reason: '佐賀県のモダンな一本。マスカットを思わせる香りと爽やかなキレが、フルーティ志向のあなたにおすすめです。',
          categoryOrStyle: '純米吟醸',
        ),
      ],
    );
  }

  // ─── プロンプト構築 ──────────────────────────────────────────────────

  String _buildPrompt(List<Sake> topByCount, List<Sake> topByRating) {
    final byCount = topByCount.map((s) => {
          'brand': s.brand,
          'brewery': s.brewery,
          'prefecture': s.prefecture,
          'tasting_count': s.tastingCount,
          'avg_rating': s.avgRating,
        });
    final byRating = topByRating.map((s) => {
          'brand': s.brand,
          'brewery': s.brewery,
          'prefecture': s.prefecture,
          'avg_rating': s.avgRating,
          'tasting_count': s.tastingCount,
        });

    return 'あなたは日本酒に詳しいソムリエです。'
        'ユーザーの飲酒履歴ランキングから好みの傾向を読み取り、'
        '次に飲むと喜びそうな日本酒を3〜5件提案してください。'
        'ランキング:\n'
        '${jsonEncode({'topByCount': byCount.toList(), 'topByRating': byRating.toList()})}';
  }
}
