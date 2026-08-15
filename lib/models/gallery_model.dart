import 'package:cloud_firestore/cloud_firestore.dart';

/// Gallery entity representing event memory photo uploads
class GalleryModel {
  final String id; // MediaId (PK)
  final String eventId; // EventId (FK)
  final String uploadedBy; // UploadedBy (FK) - organizer or admin
  final String? uploaderName;
  final String imageUrl;
  final String? caption;
  final DateTime uploadedAt;

  const GalleryModel({
    required this.id,
    required this.eventId,
    required this.uploadedBy,
    this.uploaderName,
    required this.imageUrl,
    this.caption,
    required this.uploadedAt,
  });

  factory GalleryModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return GalleryModel(
      id: id,
      eventId: map['eventId'] as String? ?? map['EventId'] as String? ?? '',
      uploadedBy: map['uploadedBy'] as String? ?? map['UploadedBy'] as String? ?? '',
      uploaderName: map['uploaderName'] as String?,
      imageUrl: map['imageUrl'] as String? ?? map['ImageUrl'] as String? ?? '',
      caption: map['caption'] as String? ?? map['Caption'] as String?,
      uploadedAt: parseDate(map['uploadedAt'] ?? map['UploadedAt']),
    );
  }

  factory GalleryModel.fromFirestore(DocumentSnapshot doc) {
    return GalleryModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'imageUrl': imageUrl,
      'caption': caption,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
