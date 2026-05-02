import 'package:cloud_firestore/cloud_firestore.dart';

enum TastingNoteStatus {
  processing,
  ready,
  failed;

  static TastingNoteStatus fromString(String value) {
    return switch (value) {
      'ready' => TastingNoteStatus.ready,
      'failed' => TastingNoteStatus.failed,
      _ => TastingNoteStatus.processing,
    };
  }

  String toValue() => name;
}

class TastingNote {
  final String noteId;
  final String userId;
  final String? sakeId;
  final TastingNoteStatus status;
  final String imageUrl;
  final DateTime drankAt;
  final String brand;
  final String brewery;
  final String prefecture;
  final String category;
  final List<String> tags;
  final double? rating;
  final String? note;
  final String jobId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TastingNote({
    required this.noteId,
    required this.userId,
    this.sakeId,
    required this.status,
    required this.imageUrl,
    required this.drankAt,
    required this.brand,
    required this.brewery,
    required this.prefecture,
    required this.category,
    required this.tags,
    this.rating,
    this.note,
    required this.jobId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TastingNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TastingNote(
      noteId: data['note_id'] as String,
      userId: data['user_id'] as String,
      sakeId: data['sake_id'] as String?,
      status: TastingNoteStatus.fromString(data['status'] as String? ?? 'processing'),
      imageUrl: data['image_url'] as String? ?? '',
      drankAt: (data['drank_at'] as Timestamp).toDate(),
      brand: data['brand'] as String? ?? '',
      brewery: data['brewery'] as String? ?? '',
      prefecture: data['prefecture'] as String? ?? '',
      category: data['category'] as String? ?? 'sake',
      tags: List<String>.from(data['tags'] as List? ?? []),
      rating: (data['rating'] as num?)?.toDouble(),
      note: data['note'] as String?,
      jobId: data['job_id'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'user_id': userId,
      if (sakeId != null) 'sake_id': sakeId,
      'status': status.toValue(),
      'image_url': imageUrl,
      'drank_at': Timestamp.fromDate(drankAt),
      'brand': brand,
      'brewery': brewery,
      'prefecture': prefecture,
      'category': category,
      'tags': tags,
      if (rating != null) 'rating': rating,
      if (note != null) 'note': note,
      'job_id': jobId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  TastingNote copyWith({
    String? sakeId,
    TastingNoteStatus? status,
    String? brand,
    String? brewery,
    String? prefecture,
    String? category,
    List<String>? tags,
    double? rating,
    String? note,
    DateTime? updatedAt,
  }) {
    return TastingNote(
      noteId: noteId,
      userId: userId,
      sakeId: sakeId ?? this.sakeId,
      status: status ?? this.status,
      imageUrl: imageUrl,
      drankAt: drankAt,
      brand: brand ?? this.brand,
      brewery: brewery ?? this.brewery,
      prefecture: prefecture ?? this.prefecture,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      jobId: jobId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
