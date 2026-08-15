import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification entity representing in-app notices for critical event milestones
class NotificationModel {
  final String id; // NotificationId (PK)
  final String userId; // UserId (FK)
  final String? eventId; // EventId (FK)
  final String title;
  final String message;
  final String type; // 'registration_confirm', 'reminder', 'event_update', 'event_cancelled', 'announcement', 'feedback_request'
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.eventId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? map['UserId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? map['EventId'] as String?,
      title: map['title'] as String? ?? map['Title'] as String? ?? '',
      message: map['message'] as String? ?? map['Message'] as String? ?? '',
      type: map['type'] as String? ?? 'announcement',
      isRead: map['isRead'] == true || map['IsRead'] == true,
      createdAt: parseDate(map['createdAt'] ?? map['CreatedAt']),
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    return NotificationModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
