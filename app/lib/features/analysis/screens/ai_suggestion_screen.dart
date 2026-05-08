import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/taste_analysis_service.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  late Future<TasteAnalysisResult> _future;
  final _service = TasteAnalysisService();

  @override
  void initState() {
    super.initState();
    _future = _service.analyze();
  }

  void _retry() => setState(() => _future = _service.analyze());

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: kBgBase,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: kSurface1,
            padding: EdgeInsets.only(top: top + 20, left: 20, right: 20, bottom: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: kTextPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('AI 傾向分析', style: AppTextStyles.headingLarge()),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<TasteAnalysisResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kAccentMain),
                        SizedBox(height: 16),
                        Text('AIが傾向を分析中...',
                            style: TextStyle(color: kTextSub)),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  final msg = snapshot.error.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Color(0xFFE05A4E)),
                          const SizedBox(height: 12),
                          Text(msg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kTextSub)),
                          const SizedBox(height: 16),
                          _OutlineButton(label: '再試行', onTap: _retry),
                        ],
                      ),
                    ),
                  );
                }
                final result = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    _TendencyCard(tendency: result.tendency),
                    const SizedBox(height: 20),
                    Text('おすすめの日本酒',
                        style: AppTextStyles.headingMedium()),
                    const SizedBox(height: 12),
                    ...result.suggestions
                        .map((s) => _SuggestionCard(s: s)),
                    const SizedBox(height: 16),
                    Center(
                      child: _OutlineButton(
                          label: 'もう一度分析する', onTap: _retry),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TendencyCard extends StatelessWidget {
  final String tendency;

  const _TendencyCard({required this.tendency});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccentGlow),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: kAccentMain, size: 18),
              const SizedBox(width: 8),
              Text('あなたの傾向',
                  style: AppTextStyles.headingSmall(color: kAccentMain)),
            ],
          ),
          const SizedBox(height: 10),
          Text(tendency,
              style: const TextStyle(
                  color: kTextPrimary, height: 1.6, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final TasteSuggestion s;

  const _SuggestionCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderDefault),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_drink, color: kAccentMain, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.brand,
                    style: AppTextStyles.headingSmall(),
                    overflow: TextOverflow.ellipsis),
              ),
              if (s.categoryOrStyle.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kAccentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s.categoryOrStyle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: kAccentMain,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.reason,
              style: const TextStyle(
                  fontSize: 13, color: kTextSub, height: 1.4)),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: kAccentMain),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: kAccentMain, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: kAccentMain, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
