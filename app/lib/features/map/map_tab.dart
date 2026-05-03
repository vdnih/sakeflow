import 'package:countries_world_map/countries_world_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../tasting_note/models/tasting_note.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';
import 'models/prefecture_stats.dart';
import 'services/prefecture_aggregator.dart';
import 'utils/prefecture_normalizer.dart';

class MapTab extends StatelessWidget {
  MapTab({super.key});

  final TastingNoteRepository _repo = TastingNoteRepository();

  static const _localColor  = kAccentMain;
  static const _drankColor  = Color(0xFF3A2E1A);
  static const _emptyColor  = Color(0xFF1C1C22);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBgBase,
      body: user == null
          ? const Center(
              child: Text('ログインが必要です',
                  style: TextStyle(color: kTextSub)))
          : StreamBuilder<List<TastingNote>>(
              stream: _repo.listNotes(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('エラー: ${snapshot.error}',
                          style: const TextStyle(color: kTextSub)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = PrefectureAggregator.aggregate(snapshot.data!);
                return _buildContent(context, stats, top);
              },
            ),
    );
  }

  Widget _buildContent(
      BuildContext context, PrefectureStats stats, double topPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          top: topPad + 20, left: 20, right: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('マップ', style: AppTextStyles.headingLarge()),
          const SizedBox(height: 4),
          Text(
            '${stats.drankCount}都道府県で記録',
            style: const TextStyle(fontSize: 12, color: kTextSub),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.2,
            child: Container(
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorderDefault),
              ),
              padding: const EdgeInsets.all(8),
              child: SimpleMap(
                instructions: SMapJapan.instructions,
                defaultColor: _emptyColor,
                colors: _buildColorMap(stats),
                countryBorder: const CountryBorder(
                  color: Color(0xFF0C0C0F),
                  width: 0.5,
                ),
                callback: (id, name, _) =>
                    _onTapPrefecture(context, id, name),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(stats),
        ],
      ),
    );
  }

  Map<String, Color> _buildColorMap(PrefectureStats stats) {
    final map = <String, Color>{};
    for (final code in stats.drank) {
      map[code] = _drankColor;
    }
    for (final code in stats.drankLocal) {
      map[code] = _localColor;
    }
    return map;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      children: [
        _legendItem(_localColor, '現地で飲んだ'),
        _legendItem(_drankColor, '飲んだ'),
        _legendItem(_emptyColor, '未経験'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: kBorderDefault),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: kTextSub)),
      ],
    );
  }

  Widget _buildInfoCard(PrefectureStats stats) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statColumn(
                '飲んだ都道府県', stats.drankCount, kAccentMain),
          ),
          Container(width: 1, height: 40, color: kBorderDefault),
          Expanded(
            child: _statColumn(
                '現地で飲んだ', stats.drankLocalCount, kAccentMain),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: kTextSub),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const TextSpan(
                text: ' / 47',
                style: TextStyle(fontSize: 12, color: kTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onTapPrefecture(BuildContext context, String id, String name) {
    final official = _officialFromJpCode(id) ?? name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(official),
        duration: const Duration(milliseconds: 800),
        backgroundColor: kSurface2,
      ),
    );
  }

  String? _officialFromJpCode(String jpCode) {
    if (jpCode.length != 5 || !jpCode.startsWith('JP-')) return null;
    final n = int.tryParse(jpCode.substring(3));
    if (n == null || n < 1 || n > 47) return null;
    return PrefectureNormalizer.officialNames[n - 1];
  }
}
