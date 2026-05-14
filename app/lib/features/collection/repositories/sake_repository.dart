import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sake.dart';

class SakeRepository {
  final FirebaseFirestore _db;

  SakeRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('sakes');

  /// brand + userId で既存銘柄を検索し、あれば集計を更新、なければ新規作成する。
  /// 返り値: sakeId
  Future<String> upsertSake({
    required String userId,
    required String brand,
    required String brewery,
    required String prefecture,
    required String category,
    required String imageUrl,
    required DateTime drankAt,
    double? rating,
  }) async {
    final existing = await _col(userId)
        .where('brand', isEqualTo: brand)
        .limit(1)
        .get();

    final now = DateTime.now();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final current = Sake.fromFirestore(doc);

      final newCount = current.tastingCount + 1;
      double? newAvg;
      if (rating != null) {
        final prevTotal = (current.avgRating ?? 0) * current.tastingCount;
        newAvg = (prevTotal + rating) / newCount;
      } else {
        newAvg = current.avgRating;
      }

      await doc.reference.update({
        'brewery': brewery,
        'prefecture': prefecture,
        'image_url': imageUrl,
        'tasting_count': newCount,
        if (newAvg != null) 'avg_rating': newAvg,
        'last_drank_at': Timestamp.fromDate(drankAt),
        'updated_at': Timestamp.fromDate(now),
      });
      return doc.id;
    }

    final sakeId = const Uuid().v4();
    final sake = Sake(
      sakeId: sakeId,
      userId: userId,
      brand: brand,
      brewery: brewery,
      prefecture: prefecture,
      category: category,
      imageUrl: imageUrl,
      tastingCount: 1,
      avgRating: rating,
      firstDrankAt: drankAt,
      lastDrankAt: drankAt,
      createdAt: now,
      updatedAt: now,
    );
    await _col(userId).doc(sakeId).set(sake.toMap());
    return sakeId;
  }

  /// 銘柄情報の編集（brand変更時はsakeId単位で更新）
  Future<void> updateSake({
    required String userId,
    required String sakeId,
    required String brand,
    required String brewery,
    required String prefecture,
  }) async {
    await _col(userId).doc(sakeId).update({
      'brand': brand,
      'brewery': brewery,
      'prefecture': prefecture,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// tasting_count を 1 減らし、0 以下になった sake は同時に削除する。
  /// 返り値: 削除した場合 true。
  Future<bool> decrementOrDeleteSake({
    required String userId,
    required String sakeId,
  }) async {
    final docRef = _col(userId).doc(sakeId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return true;
      final current = Sake.fromFirestore(snap);
      final newCount = current.tastingCount - 1;
      if (newCount <= 0) {
        tx.delete(docRef);
        return true;
      }
      tx.update(docRef, {
        'tasting_count': newCount,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      return false;
    });
  }

  Stream<List<Sake>> listSakes(String userId) {
    return _col(userId)
        .orderBy('last_drank_at', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => Sake.fromFirestore(d)).toList());
  }
}
