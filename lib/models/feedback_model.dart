import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback entity submitted by attendees for completed events
class FeedbackModel {
  final String id; // FeedbackId (PK)
  final String eventId; // EventId (FK)
  final String userId; // UserId (FK)
  final String? userName;
  final int rating; // 1 to 5
  final String? comment;
  final DateTime submittedAt;

  const FeedbackModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    required this.submittedAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    int parseRating(dynamic val) {
      if (val is int) return val.clamp(1, 5);
      if (val is num) return val.toInt().clamp(1, 5);
      if (val is String) return (int.tryParse(val) ?? 5).clamp(1, 5);
      return 5;
    }

    return FeedbackModel(
      id: id,
      eventId: map['eventId'] as String? ?? map['EventId'] as String? ?? '',
      userId: map['userId'] as String? ?? map['UserId'] as String? ?? '',
      userName: map['userName'] as String?,
      rating: parseRating(map['rating'] ?? map['Rating']),
      comment: map['comment'] as String? ?? map['Comment'] as String?,
      submittedAt: parseDate(map['submittedAt'] ?? map['SubmittedAt']),
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    return FeedbackModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
