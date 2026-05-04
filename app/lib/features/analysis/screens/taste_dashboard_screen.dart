import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../collection/models/sake.dart';
import '../repositories/analysis_repository.dart';
import 'ai_suggestion_screen.dart';

class TasteDashboardScreen extends StatelessWidget {
  const TasteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final repo = AnalysisRepository();
    final top = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBgBase,
        body: Column(
          children: [
            Container(
              color: kSurface1,
              padding: EdgeInsets.only(top: top + 20, left: 20, right: 20, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分析', style: AppTextStyles.headingLarge()),
                  const SizedBox(height: 16),
                  TabBar(
                    indicatorColor: kAccentMain,
                    labelColor: kAccentMain,
                    unselectedLabelColor: kTextSub,
                    dividerColor: kBorderDefault,
                    tabs: const [
                      Tab(icon: Icon(Icons.local_bar), text: 'よく飲む'),
                      Tab(icon: Icon(Icons.star), text: '高評価'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _RankingList(
                    stream: repo.rankByCount(user.uid),
                    metricBuilder: (s) => _MetricChip(
                      icon: Icons.local_bar,
                      label: '${s.tastingCount}回',
                    ),
                    emptyText: 'まだ記録がありません',
                  ),
                  _RankingList(
                    stream: repo.rankByRating(user.uid),
                    metricBuilder: (s) => _MetricChip(
                      icon: Icons.star,
                      label: s.avgRating!.toStringAsFixed(1),
                    ),
                    emptyText: 'まだ評価がついた銘柄がありません',
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kAccentMain,
          foregroundColor: kBgBase,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AIで傾向を分析'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiSuggestionScreen()),
            );
          },
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final Stream<List<Sake>> stream;
  final Widget Function(Sake) metricBuilder;
  final String emptyText;

  const _RankingList({
    required this.stream,
    required this.metricBuilder,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sake>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('エラー: ${snapshot.error}',
                style: const TextStyle(color: kTextSub)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: kAccentMain),
          );
        }
        final sakes = snapshot.data!;
        if (sakes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bar_chart, size: 72, color: kTextMuted),
                const SizedBox(height: 16),
                Text(emptyText,
                    style: const TextStyle(color: kTextSub, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: sakes.length,
          itemBuilder: (context, index) => _RankCard(
            rank: index + 1,
            sake: sakes[index],
            metric: metricBuilder(sakes[index]),
          ),
        );
      },
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final Sake sake;
  final Widget metric;

  const _RankCard({
    required this.rank,
    required this.sake,
    required this.metric,
  });

  Color _rankColor() {
    if (rank == 1) return kAccentMain;
    if (rank == 2) return const Color(0xFF8A8A96);
    if (rank == 3) return const Color(0xFF7C5A3A);
    return kTextMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _rankColor().withAlpha(30),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rankColor(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sake.brand,
                    style: AppTextStyles.headingSmall(),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sake.brewery.isNotEmpty)
                    Text(
                      sake.brewery,
                      style: const TextStyle(fontSize: 12, color: kTextSub),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (sake.prefecture.isNotEmpty)
                    Text(
                      sake.prefecture,
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                ],
              ),
            ),
            metric,
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kAccentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kAccentMain),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                color: kAccentMain,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
