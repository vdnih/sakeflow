import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/map/services/prefecture_aggregator.dart';
import 'package:sakeflow_log/features/tasting_note/models/tasting_note.dart';

TastingNote _note({
  required String prefecture,
  bool drankLocally = false,
}) {
  final now = DateTime(2024, 1, 1);
  return TastingNote(
    noteId: 'id',
    userId: 'user1',
    imageUrl: '',
    drankAt: now,
    brand: 'brand',
    brewery: 'brewery',
    prefecture: prefecture,
    category: 'sake',
    tags: [],
    drankLocally: drankLocally,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PrefectureAggregator.aggregate', () {
    test('空のリスト → 空の PrefectureStats', () {
      final stats = PrefectureAggregator.aggregate([]);
      expect(stats.drank, isEmpty);
      expect(stats.drankLocal, isEmpty);
    });

    test('ノートがある → drank に JP コードが追加される', () {
      final stats = PrefectureAggregator.aggregate([
        _note(prefecture: '東京都'),
        _note(prefecture: '大阪府'),
      ]);
      expect(stats.drank, containsAll(['JP-13', 'JP-27']));
      expect(stats.drank.length, 2);
    });

    test('drankLocally=true → drankLocal にも追加される', () {
      final stats = PrefectureAggregator.aggregate([
        _note(prefecture: '新潟県', drankLocally: true),
        _note(prefecture: '山形県', drankLocally: false),
      ]);
      expect(stats.drank, containsAll(['JP-15', 'JP-06']));
      expect(stats.drankLocal, contains('JP-15'));
      expect(stats.drankLocal, isNot(contains('JP-06')));
    });

    test('同じ都道府県の複数ノート → drank に重複なし', () {
      final stats = PrefectureAggregator.aggregate([
        _note(prefecture: '東京都'),
        _note(prefecture: '東京都'),
        _note(prefecture: '東京都'),
      ]);
      expect(stats.drank.length, 1);
      expect(stats.drank, contains('JP-13'));
    });

    test('不明な prefecture → スキップされる', () {
      final stats = PrefectureAggregator.aggregate([
        _note(prefecture: ''),
        _note(prefecture: 'unknown'),
        _note(prefecture: '東京都'),
      ]);
      expect(stats.drank, {'JP-13'});
    });

    test('略称でも認識される', () {
      final stats = PrefectureAggregator.aggregate([
        _note(prefecture: '東京'),
        _note(prefecture: 'osaka'),
      ]);
      expect(stats.drank, containsAll(['JP-13', 'JP-27']));
    });
  });
}
