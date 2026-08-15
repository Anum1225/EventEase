import 'package:cloud_firestore/cloud_firestore.dart';

/// Favorite entity representing an Attendee's saved event bookmark
class FavoriteModel {
  final String id; // FavoriteId (PK)
  final String userId; // UserId (FK)
  final String eventId; // EventId (FK)
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.createdAt,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return FavoriteModel(
      id: id,
      userId: map['userId'] as String? ?? map['UserId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? map['EventId'] as String? ?? '',
      createdAt: parseDate(map['createdAt'] ?? map['CreatedAt']),
    );
  }

  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    return FavoriteModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
