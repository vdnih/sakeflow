import 'package:countries_world_map/countries_world_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../tasting_note/models/tasting_note.dart';
import '../tasting_note/repositories/tasting_note_repository.dart';
import 'models/prefecture_stats.dart';
import 'services/prefecture_aggregator.dart';
import 'utils/prefecture_normalizer.dart';

class MapTab extends StatelessWidget {
  MapTab({super.key});

  final TastingNoteRepository _repo = TastingNoteRepository();

  static const _localColor = Color(0xFF4527A0); // 濃い deepPurple
  static const _drankColor = Color(0xFFD1C4E9); // 薄い deepPurple
  static const _emptyColor = Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('マップ'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('ログインが必要です'))
          : StreamBuilder<List<TastingNote>>(
              stream: _repo.listNotes(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('エラー: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = PrefectureAggregator.aggregate(snapshot.data!);
                return _buildContent(context, stats);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, PrefectureStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatsCard(stats),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SimpleMap(
                instructions: SMapJapan.instructions,
                defaultColor: _emptyColor,
                colors: _buildColorMap(stats),
                countryBorder: const CountryBorder(
                  color: Colors.white,
                  width: 0.5,
                ),
                callback: (id, name, _) => _onTapPrefecture(context, id, name),
              ),
            ),
          ),
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

  Widget _buildStatsCard(PrefectureStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statColumn('飲んだ都道府県', stats.drankCount, _drankColor),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _statColumn('飲みに行った都道府県', stats.drankLocalCount, _localColor),
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
          style: const TextStyle(fontSize: 12, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87),
            children: [
              TextSpan(
                text: '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const TextSpan(
                text: ' / 47',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
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
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _onTapPrefecture(BuildContext context, String id, String name) {
    final official = _officialFromJpCode(id) ?? name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(official),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // id は "JP-13" 形式で渡ってくる
  String? _officialFromJpCode(String jpCode) {
    if (jpCode.length != 5 || !jpCode.startsWith('JP-')) return null;
    final n = int.tryParse(jpCode.substring(3));
    if (n == null || n < 1 || n > 47) return null;
    return PrefectureNormalizer.officialNames[n - 1];
  }
}
