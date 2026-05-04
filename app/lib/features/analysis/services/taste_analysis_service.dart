import 'package:cloud_functions/cloud_functions.dart';

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
  final FirebaseFunctions _functions;

  TasteAnalysisService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<TasteAnalysisResult> analyze() async {
    final callable = _functions.httpsCallable('analyzeTaste');
    final res = await callable.call<Map<Object?, Object?>>();
    final data = Map<String, dynamic>.from(res.data);
    final list = (data['suggestions'] as List? ?? [])
        .map((e) => TasteSuggestion.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return TasteAnalysisResult(
      tendency: data['tendency'] as String? ?? '',
      suggestions: list,
    );
  }
}
