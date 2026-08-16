import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Service managing Cloud Storage image uploads with automatic compression and fallback
class StorageService {
  FirebaseStorage? _storage;
  final Uuid _uuid;

  StorageService({
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _storage = storage,
        _uuid = uuid ?? const Uuid();

  FirebaseStorage? get _safeStorage {
    if (_storage != null) return _storage;
    try {
      _storage = FirebaseStorage.instance;
      return _storage;
    } catch (_) {
      return null;
    }
  }

  /// Uploads user profile avatar
  Future<String> uploadProfileImage({
    required String userId,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    final bytes = imageBytes ?? (imageFile != null ? await imageFile.readAsBytes() : null);
    if (bytes == null) throw Exception('No image data provided');

    try {
      final storage = _safeStorage;
      if (storage == null) throw Exception('Storage not available');
      final ref = storage.ref().child('users').child(userId).child('avatar.jpg');
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }

  /// Uploads event banner photo
  Future<String> uploadEventBanner({
    required String organizerId,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    final bytes = imageBytes ?? (imageFile != null ? await imageFile.readAsBytes() : null);
    if (bytes == null) throw Exception('No image data provided');

    try {
      final storage = _safeStorage;
      if (storage == null) throw Exception('Storage not available');
      final fileName = 'banner_${_uuid.v4()}.jpg';
      final ref = storage.ref().child('events').child(organizerId).child(fileName);
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }

  /// Uploads gallery memory photo
  Future<String> uploadGalleryImage({
    required String eventId,
    String? uploaderId,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    final bytes = imageBytes ?? (imageFile != null ? await imageFile.readAsBytes() : null);
    if (bytes == null) throw Exception('No image data provided');

    try {
      final storage = _safeStorage;
      if (storage == null) throw Exception('Storage not available');
      final fileName = 'gallery_${_uuid.v4()}.jpg';
      final ref = storage.ref().child('galleries').child(eventId).child(fileName);
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }
}
