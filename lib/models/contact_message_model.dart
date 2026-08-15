import 'package:cloud_firestore/cloud_firestore.dart';

/// Contact message entity submitted from the Contact Us form
class ContactMessageModel {
  final String id; // MessageId (PK)
  final String? userId; // UserId (FK)
  final String name;
  final String email;
  final String subject;
  final String message;
  final DateTime submittedAt;
  final String status; // 'new', 'resolved'

  const ContactMessageModel({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.submittedAt,
    this.status = 'new',
  });

  factory ContactMessageModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ContactMessageModel(
      id: id,
      userId: map['userId'] as String? ?? map['UserId'] as String?,
      name: map['name'] as String? ?? map['Name'] as String? ?? '',
      email: map['email'] as String? ?? map['Email'] as String? ?? '',
      subject: map['subject'] as String? ?? map['Subject'] as String? ?? '',
      message: map['message'] as String? ?? map['Message'] as String? ?? '',
      submittedAt: parseDate(map['submittedAt'] ?? map['SubmittedAt']),
      status: map['status'] as String? ?? 'new',
    );
  }

  factory ContactMessageModel.fromFirestore(DocumentSnapshot doc) {
    return ContactMessageModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
    };
  }
}
