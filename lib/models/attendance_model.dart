import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance entity recording successful check-in via QR scan
class AttendanceModel {
  final String id; // AttendanceId (PK)
  final String registrationId; // RegistrationId (FK)
  final String eventId; // EventId (FK)
  final String userId; // UserId (FK)
  final String? userName;
  final String? userEmail;
  final bool attended;
  final DateTime checkedInAt;
  final String? checkedInBy; // OrganizerId who performed the scan

  const AttendanceModel({
    required this.id,
    required this.registrationId,
    required this.eventId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.attended = true,
    required this.checkedInAt,
    this.checkedInBy,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AttendanceModel(
      id: id,
      registrationId: map['registrationId'] as String? ?? map['RegistrationId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? map['EventId'] as String? ?? '',
      userId: map['userId'] as String? ?? map['UserId'] as String? ?? '',
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      attended: map['attended'] == true || map['Attended'] == true,
      checkedInAt: parseDate(map['checkedInAt'] ?? map['CheckedInAt']),
      checkedInBy: map['checkedInBy'] as String?,
    );
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'attended': attended,
      'checkedInAt': Timestamp.fromDate(checkedInAt),
      'checkedInBy': checkedInBy,
    };
  }
}
