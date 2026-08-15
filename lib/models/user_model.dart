import 'package:cloud_firestore/cloud_firestore.dart';

/// User entity representing Attendees, Organizers, and Admins
class UserModel {
  final String id; // UserId (PK)
  final String name;
  final String email;
  final String? phone;
  final String role; // 'attendee', 'organizer_pending', 'organizer', 'admin'
  final String? organizerApprovalStatus; // 'pending', 'approved', 'rejected'
  final String? organizerApprovalReason;
  final String? profileImage;
  final String status; // 'active', 'deactivated'
  final DateTime createdAt;
  final String? fcmToken;
  final Map<String, bool> notificationPreferences;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.organizerApprovalStatus,
    this.organizerApprovalReason,
    this.profileImage,
    this.status = 'active',
    required this.createdAt,
    this.fcmToken,
    this.notificationPreferences = const {
      'reminders': true,
      'announcements': true,
      'feedback': true,
      'updates': true,
    },
  });

  bool get isActive => status == 'active';
  bool get isAttendee => role == 'attendee';
  bool get isOrganizer => role == 'organizer';
  bool get isOrganizerPending => role == 'organizer_pending';
  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? organizerApprovalStatus,
    String? organizerApprovalReason,
    String? profileImage,
    String? status,
    DateTime? createdAt,
    String? fcmToken,
    Map<String, bool>? notificationPreferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      organizerApprovalStatus: organizerApprovalStatus ?? this.organizerApprovalStatus,
      organizerApprovalReason: organizerApprovalReason ?? this.organizerApprovalReason,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, bool> parsePrefs(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v == true));
      }
      return {
        'reminders': true,
        'announcements': true,
        'feedback': true,
        'updates': true,
      };
    }

    return UserModel(
      id: id,
      name: map['name'] as String? ?? map['Name'] as String? ?? '',
      email: map['email'] as String? ?? map['Email'] as String? ?? '',
      phone: map['phone'] as String? ?? map['Phone'] as String?,
      role: map['role'] as String? ?? map['Role'] as String? ?? 'attendee',
      organizerApprovalStatus: map['organizerApprovalStatus'] as String?,
      organizerApprovalReason: map['organizerApprovalReason'] as String?,
      profileImage: map['profileImage'] as String? ?? map['ProfileImage'] as String?,
      status: map['status'] as String? ?? map['Status'] as String? ?? 'active',
      createdAt: parseDate(map['createdAt'] ?? map['CreatedAt']),
      fcmToken: map['fcmToken'] as String?,
      notificationPreferences: parsePrefs(map['notificationPreferences']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'organizerApprovalStatus': organizerApprovalStatus,
      'organizerApprovalReason': organizerApprovalReason,
      'profileImage': profileImage,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'fcmToken': fcmToken,
      'notificationPreferences': notificationPreferences,
    };
  }
}
