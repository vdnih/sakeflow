import 'package:cloud_firestore/cloud_firestore.dart';

class TastingNote {
  final String noteId;
  final String userId;
  final String? sakeId;
  final String imageUrl;
  final DateTime drankAt;
  final String brand;
  final String brewery;
  final String prefecture;
  final String category;
  final List<String> tags;
  final double? rating;
  final String? note;
  final bool drankLocally;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TastingNote({
    required this.noteId,
    required this.userId,
    this.sakeId,
    required this.imageUrl,
    required this.drankAt,
    required this.brand,
    required this.brewery,
    required this.prefecture,
    required this.category,
    required this.tags,
    this.rating,
    this.note,
    this.drankLocally = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TastingNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TastingNote(
      noteId: data['note_id'] as String,
      userId: data['user_id'] as String,
      sakeId: data['sake_id'] as String?,
      imageUrl: data['image_url'] as String? ?? '',
      drankAt: (data['drank_at'] as Timestamp).toDate(),
      brand: data['brand'] as String? ?? '',
      brewery: data['brewery'] as String? ?? '',
      prefecture: data['prefecture'] as String? ?? '',
      category: data['category'] as String? ?? 'sake',
      tags: List<String>.from(data['tags'] as List? ?? []),
      rating: (data['rating'] as num?)?.toDouble(),
      note: data['note'] as String?,
      drankLocally: data['drank_locally'] as bool? ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'user_id': userId,
      if (sakeId != null) 'sake_id': sakeId,
      'image_url': imageUrl,
      'drank_at': Timestamp.fromDate(drankAt),
      'brand': brand,
      'brewery': brewery,
      'prefecture': prefecture,
      'category': category,
      'tags': tags,
      if (rating != null) 'rating': rating,
      if (note != null) 'note': note,
      'drank_locally': drankLocally,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  TastingNote copyWith({
    String? sakeId,
    String? brand,
    String? brewery,
    String? prefecture,
    String? category,
    List<String>? tags,
    double? rating,
    String? note,
    bool? drankLocally,
    DateTime? updatedAt,
  }) {
    return TastingNote(
      noteId: noteId,
      userId: userId,
      sakeId: sakeId ?? this.sakeId,
      imageUrl: imageUrl,
      drankAt: drankAt,
      brand: brand ?? this.brand,
      brewery: brewery ?? this.brewery,
      prefecture: prefecture ?? this.prefecture,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      drankLocally: drankLocally ?? this.drankLocally,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
