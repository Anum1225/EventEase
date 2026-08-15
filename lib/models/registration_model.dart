import 'package:cloud_firestore/cloud_firestore.dart';

/// Registration entity linking Attendee to an Event and holding the unique QR identifier
class RegistrationModel {
  final String id; // RegistrationId (PK)
  final String eventId; // EventId (FK)
  final String userId; // UserId (FK)
  final String? eventTitle;
  final DateTime? eventDate;
  final String? eventLocation;
  final String? eventBanner;
  final String? eventCategory;
  final String? userName;
  final String? userEmail;
  final DateTime registeredAt;
  final String status; // 'registered', 'cancelled'
  final String qrCode; // Encoded UUID token for scanner verification

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.eventBanner,
    this.eventCategory,
    this.userName,
    this.userEmail,
    required this.registeredAt,
    this.status = 'registered',
    required this.qrCode,
  });

  bool get isRegistered => status == 'registered';
  bool get isCancelled => status == 'cancelled';

  RegistrationModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventLocation,
    String? eventBanner,
    String? eventCategory,
    String? userName,
    String? userEmail,
    DateTime? registeredAt,
    String? status,
    String? qrCode,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      eventBanner: eventBanner ?? this.eventBanner,
      eventCategory: eventCategory ?? this.eventCategory,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  factory RegistrationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return RegistrationModel(
      id: id,
      eventId: map['eventId'] as String? ?? map['EventId'] as String? ?? '',
      userId: map['userId'] as String? ?? map['UserId'] as String? ?? '',
      eventTitle: map['eventTitle'] as String?,
      eventDate: map['eventDate'] != null ? parseDate(map['eventDate']) : null,
      eventLocation: map['eventLocation'] as String?,
      eventBanner: map['eventBanner'] as String?,
      eventCategory: map['eventCategory'] as String?,
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      registeredAt: parseDate(map['registeredAt'] ?? map['RegisteredAt']),
      status: map['status'] as String? ?? map['Status'] as String? ?? 'registered',
      qrCode: map['qrCode'] as String? ?? map['QRCode'] as String? ?? '',
    );
  }

  factory RegistrationModel.fromFirestore(DocumentSnapshot doc) {
    return RegistrationModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'eventTitle': eventTitle,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'eventLocation': eventLocation,
      'eventBanner': eventBanner,
      'eventCategory': eventCategory,
      'userName': userName,
      'userEmail': userEmail,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'status': status,
      'qrCode': qrCode,
    };
  }
}
