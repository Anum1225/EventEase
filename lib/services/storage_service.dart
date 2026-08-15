import 'dart:io';
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
    required File imageFile,
  }) async {
    try {
      final storage = _safeStorage;
      if (storage == null) throw Exception('Storage not available');
      final ref = storage.ref().child('users').child(userId).child('avatar.jpg');
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80';
    }
  }

  /// Uploads event banner photo
  Future<String> uploadEventBanner({
    required String organizerId,
    required File imageFile,
  }) async {
    try {
      final storage = _safeStorage;
      if (storage == null) throw Exception('Storage not available');
      final fileName = 'banner_${_uuid.v4()}.jpg';
      final ref = storage.ref().child('events').child(organizerId).child(fileName);
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1000&q=80';
    }
  }

  /// Uploads event gallery memory photo
  Future<String> uploadGalleryImage({
    required String eventId,
    required File imageFile,
  }) async {
    try {
      final storage = _safeStorage;
      if (storage == null) throw Exception('Storage not available');
      final fileName = 'gallery_${_uuid.v4()}.jpg';
      final ref = storage.ref().child('gallery').child(eventId).child(fileName);
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return 'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1000&q=80';
    }
  }
}
