import 'package:cloud_firestore/cloud_firestore.dart';
import '../../collection/models/sake.dart';

class AnalysisRepository {
  final FirebaseFirestore _db;

  AnalysisRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('sakes');

  Stream<List<Sake>> rankByCount(String userId, {int limit = 10}) {
    return _col(userId)
        .orderBy('tasting_count', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => Sake.fromFirestore(d)).toList());
  }

  Stream<List<Sake>> rankByRating(String userId, {int limit = 10}) {
    return _col(userId)
        .where('avg_rating', isGreaterThan: 0)
        .orderBy('avg_rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => Sake.fromFirestore(d)).toList());
  }
}
