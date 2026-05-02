import 'package:cloud_firestore/cloud_firestore.dart';

class Sake {
  final String sakeId;
  final String userId;
  final String brand;
  final String brewery;
  final String prefecture;
  final String category;
  final String imageUrl;
  final int tastingCount;
  final double? avgRating;
  final DateTime firstDrankAt;
  final DateTime lastDrankAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Sake({
    required this.sakeId,
    required this.userId,
    required this.brand,
    required this.brewery,
    required this.prefecture,
    required this.category,
    required this.imageUrl,
    required this.tastingCount,
    this.avgRating,
    required this.firstDrankAt,
    required this.lastDrankAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sake.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sake(
      sakeId: data['sake_id'] as String,
      userId: data['user_id'] as String,
      brand: data['brand'] as String? ?? '',
      brewery: data['brewery'] as String? ?? '',
      prefecture: data['prefecture'] as String? ?? '',
      category: data['category'] as String? ?? 'sake',
      imageUrl: data['image_url'] as String? ?? '',
      tastingCount: data['tasting_count'] as int? ?? 0,
      avgRating: (data['avg_rating'] as num?)?.toDouble(),
      firstDrankAt: (data['first_drank_at'] as Timestamp).toDate(),
      lastDrankAt: (data['last_drank_at'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sake_id': sakeId,
      'user_id': userId,
      'brand': brand,
      'brewery': brewery,
      'prefecture': prefecture,
      'category': category,
      'image_url': imageUrl,
      'tasting_count': tastingCount,
      if (avgRating != null) 'avg_rating': avgRating,
      'first_drank_at': Timestamp.fromDate(firstDrankAt),
      'last_drank_at': Timestamp.fromDate(lastDrankAt),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
