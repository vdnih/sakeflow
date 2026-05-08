import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/collection/repositories/sake_repository.dart';

void main() {
  const userId = 'user-001';
  late FakeFirebaseFirestore fakeFirestore;
  late SakeRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = SakeRepository(db: fakeFirestore);
  });

  group('SakeRepository.upsertSake 新規作成', () {
    test('初回は tastingCount=1 でドキュメントが作成される', () async {
      final sakeId = await repo.upsertSake(
        userId: userId,
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        category: 'sake',
        imageUrl: 'https://example.com/image.jpg',
        drankAt: DateTime(2024, 6, 15),
        rating: 4.0,
      );

      expect(sakeId, isNotEmpty);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('sakes')
          .doc(sakeId)
          .get();
      expect(doc.exists, true);
      expect(doc.data()!['brand'], '獺祭');
      expect(doc.data()!['tasting_count'], 1);
      expect(doc.data()!['avg_rating'], closeTo(4.0, 0.001));
    });

    test('rating なしで作成した場合 avg_rating が保存されない', () async {
      final sakeId = await repo.upsertSake(
        userId: userId,
        brand: '新政',
        brewery: '新政酒造',
        prefecture: '秋田県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 6, 15),
      );

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('sakes')
          .doc(sakeId)
          .get();
      expect(doc.data()!.containsKey('avg_rating'), false);
    });
  });

  group('SakeRepository.upsertSake 既存更新', () {
    test('同じ brand の 2 回目で tastingCount がインクリメントされる', () async {
      await repo.upsertSake(
        userId: userId,
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 1, 1),
        rating: 4.0,
      );

      await repo.upsertSake(
        userId: userId,
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 6, 15),
        rating: 5.0,
      );

      final sakes = await repo.listSakes(userId).first;
      expect(sakes.length, 1);
      expect(sakes.first.tastingCount, 2);
    });

    test('2 回目に rating を渡すと avgRating が再計算される', () async {
      await repo.upsertSake(
        userId: userId,
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 1, 1),
        rating: 4.0,
      );

      await repo.upsertSake(
        userId: userId,
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 6, 15),
        rating: 2.0,
      );

      final sakes = await repo.listSakes(userId).first;
      // avgRating = (4.0 * 1 + 2.0) / 2 = 3.0
      expect(sakes.first.avgRating, closeTo(3.0, 0.001));
    });

    test('異なる brand は別ドキュメントとして作成される', () async {
      await repo.upsertSake(
        userId: userId,
        brand: '獺祭',
        brewery: '旭酒造',
        prefecture: '山口県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 1, 1),
      );

      await repo.upsertSake(
        userId: userId,
        brand: '新政',
        brewery: '新政酒造',
        prefecture: '秋田県',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 6, 15),
      );

      final sakes = await repo.listSakes(userId).first;
      expect(sakes.length, 2);
    });
  });

  group('SakeRepository.listSakes', () {
    test('last_drank_at 降順でリストが返される', () async {
      await repo.upsertSake(
        userId: userId,
        brand: '古い銘柄',
        brewery: '蔵元A',
        prefecture: '東京都',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 1, 1),
      );
      await repo.upsertSake(
        userId: userId,
        brand: '新しい銘柄',
        brewery: '蔵元B',
        prefecture: '大阪府',
        category: 'sake',
        imageUrl: '',
        drankAt: DateTime(2024, 12, 31),
      );

      final sakes = await repo.listSakes(userId).first;
      expect(sakes.length, 2);
      expect(sakes.first.brand, '新しい銘柄');
      expect(sakes.last.brand, '古い銘柄');
    });

    test('データなしで空リストを返す', () async {
      final sakes = await repo.listSakes('empty-user').first;
      expect(sakes, isEmpty);
    });
  });
}
