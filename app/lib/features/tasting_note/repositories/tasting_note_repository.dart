import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/tasting_note.dart';

class TastingNoteRepository {
  final FirebaseFirestore _db;

  TastingNoteRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('users').doc(userId).collection('tasting_notes');

  Future<String> createNote({
    required String userId,
    required String imageUrl,
    required String jobId,
    required DateTime drankAt,
  }) async {
    final noteId = const Uuid().v4();
    final now = DateTime.now();
    final note = TastingNote(
      noteId: noteId,
      userId: userId,
      status: TastingNoteStatus.processing,
      imageUrl: imageUrl,
      drankAt: drankAt,
      brand: '',
      brewery: '',
      prefecture: '',
      category: 'sake',
      tags: [],
      jobId: jobId,
      createdAt: now,
      updatedAt: now,
    );
    await _col(userId).doc(noteId).set(note.toMap());
    return noteId;
  }

  Future<void> updateRatingAndNote({
    required String userId,
    required String noteId,
    double? rating,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
    if (rating != null) updates['rating'] = rating;
    if (note != null) updates['note'] = note;
    await _col(userId).doc(noteId).update(updates);
  }

  Future<void> updateEditableFields({
    required String userId,
    required String noteId,
    required String brand,
    required String brewery,
    required String prefecture,
    required List<String> tags,
    double? rating,
    String? note,
    bool? drankLocally,
  }) async {
    await _col(userId).doc(noteId).update({
      'brand': brand,
      'brewery': brewery,
      'prefecture': prefecture,
      'tags': tags,
      if (rating != null) 'rating': rating,
      if (note != null) 'note': note,
      if (drankLocally != null) 'drank_locally': drankLocally,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<TastingNote> watchNote(String userId, String noteId) {
    return _col(userId).doc(noteId).snapshots().where((s) => s.exists).map(
          (s) => TastingNote.fromFirestore(s),
        );
  }

  Stream<List<TastingNote>> listNotes(String userId) {
    return _col(userId)
        .orderBy('drank_at', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => TastingNote.fromFirestore(d)).toList());
  }
}
