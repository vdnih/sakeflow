import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeflow_log/features/collection/models/sake.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  Sake baseSake({double? avgRating}) {
    final now = DateTime(2024, 6, 15, 12, 0, 0);
    return Sake(
      sakeId: 'sake-001',
      userId: 'user-001',
      brand: '獺祭',
      brewery: '旭酒造',
      prefecture: '山口県',
      category: 'sake',
      imageUrl: 'https://example.com/image.jpg',
      tastingCount: 3,
      avgRating: avgRating,
      firstDrankAt: now,
      lastDrankAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('Sake.fromFirestore / toMap ラウンドトリップ', () {
    test('全フィールドが正しく変換される（avgRating あり）', () async {
      final original = baseSake(avgRating: 4.2);
      final col = fakeFirestore.collection('sakes');
      await col.doc(original.sakeId).set(original.toMap());

      final doc = await col.doc(original.sakeId).get();
      final restored = Sake.fromFirestore(doc);

      expect(restored.sakeId, original.sakeId);
      expect(restored.userId, original.userId);
      expect(restored.brand, original.brand);
      expect(restored.brewery, original.brewery);
      expect(restored.prefecture, original.prefecture);
      expect(restored.category, original.category);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.tastingCount, original.tastingCount);
      expect(restored.avgRating, closeTo(4.2, 0.001));
      expect(restored.firstDrankAt.millisecondsSinceEpoch,
          original.firstDrankAt.millisecondsSinceEpoch);
      expect(restored.lastDrankAt.millisecondsSinceEpoch,
          original.lastDrankAt.millisecondsSinceEpoch);
    });

    test('avgRating が null でも正しく変換される', () async {
      final original = baseSake(avgRating: null);
      final col = fakeFirestore.collection('sakes');
      await col.doc(original.sakeId).set(original.toMap());

      final doc = await col.doc(original.sakeId).get();
      final restored = Sake.fromFirestore(doc);

      expect(restored.avgRating, isNull);
      expect(restored.tastingCount, 3);
    });

    test('toMap に avgRating: null は含まれない', () {
      final sake = baseSake(avgRating: null);
      final map = sake.toMap();
      expect(map.containsKey('avg_rating'), false);
    });

    test('toMap に avgRating が含まれる（非 null）', () {
      final sake = baseSake(avgRating: 3.5);
      final map = sake.toMap();
      expect(map['avg_rating'], closeTo(3.5, 0.001));
    });

    test('Timestamp が正しく保存・復元される', () async {
      final original = baseSake();
      final col = fakeFirestore.collection('sakes');
      await col.doc(original.sakeId).set(original.toMap());

      final doc = await col.doc(original.sakeId).get();
      final data = doc.data() as Map<String, dynamic>;

      expect(data['first_drank_at'], isA<Timestamp>());
      expect(data['last_drank_at'], isA<Timestamp>());
      expect(data['created_at'], isA<Timestamp>());
    });
  });
}
