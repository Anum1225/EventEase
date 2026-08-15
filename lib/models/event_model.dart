import 'package:cloud_firestore/cloud_firestore.dart';

/// Event entity representing full event lifecycle and capacity tracking
class EventModel {
  final String id; // EventId (PK)
  final String organizerId; // OrganizerId (FK)
  final String? organizerName;
  final String? organizerEmail;
  final String title;
  final String description;
  final String category; // 'technology', 'education', 'sports', 'music', 'business', 'workshop', 'conference', 'community'
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final int maxParticipants;
  final int registeredCount;
  final String status; // 'pending_approval', 'approved', 'rejected', 'cancelled', 'completed'
  final String? rejectionReason;
  final String? cancellationReason;
  final String? rules;
  final String? contactInfo;
  final String? imageUrl;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.organizerId,
    this.organizerName,
    this.organizerEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.maxParticipants,
    this.registeredCount = 0,
    this.status = 'pending_approval',
    this.rejectionReason,
    this.cancellationReason,
    this.rules,
    this.contactInfo,
    this.imageUrl,
    required this.createdAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending_approval';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  bool get isFull => registeredCount >= maxParticipants;
  int get remainingSeats => (maxParticipants - registeredCount).clamp(0, maxParticipants);

  EventModel copyWith({
    String? id,
    String? organizerId,
    String? organizerName,
    String? organizerEmail,
    String? title,
    String? description,
    String? category,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    int? maxParticipants,
    int? registeredCount,
    String? status,
    String? rejectionReason,
    String? cancellationReason,
    String? rules,
    String? contactInfo,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredCount: registeredCount ?? this.registeredCount,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rules: rules ?? this.rules,
      contactInfo: contactInfo ?? this.contactInfo,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    int parseInt(dynamic val, int defaultValue) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    return EventModel(
      id: id,
      organizerId: map['organizerId'] as String? ?? map['OrganizerId'] as String? ?? '',
      organizerName: map['organizerName'] as String?,
      organizerEmail: map['organizerEmail'] as String?,
      title: map['title'] as String? ?? map['Title'] as String? ?? '',
      description: map['description'] as String? ?? map['Description'] as String? ?? '',
      category: map['category'] as String? ?? map['Category'] as String? ?? 'technology',
      date: parseDate(map['date'] ?? map['Date']),
      startTime: map['startTime'] as String? ?? map['StartTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? map['EndTime'] as String? ?? '',
      location: map['location'] as String? ?? map['Location'] as String? ?? '',
      maxParticipants: parseInt(map['maxParticipants'] ?? map['MaxParticipants'], 50),
      registeredCount: parseInt(map['registeredCount'] ?? map['RegisteredCount'], 0),
      status: map['status'] as String? ?? map['Status'] as String? ?? 'pending_approval',
      rejectionReason: map['rejectionReason'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      rules: map['rules'] as String?,
      contactInfo: map['contactInfo'] as String?,
      imageUrl: map['imageUrl'] as String? ?? map['ImageUrl'] as String?,
      createdAt: parseDate(map['createdAt'] ?? map['CreatedAt']),
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    return EventModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerEmail': organizerEmail,
      'title': title,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'maxParticipants': maxParticipants,
      'registeredCount': registeredCount,
      'status': status,
      'rejectionReason': rejectionReason,
      'cancellationReason': cancellationReason,
      'rules': rules,
      'contactInfo': contactInfo,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
