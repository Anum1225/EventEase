import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/gallery_model.dart';
import '../services/local_data_store.dart';

/// Repository managing event photo memories and admin moderation with dual-engine fallback
class GalleryRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  GalleryRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? get _safeFirestore {
    if (_firestore != null) return _firestore;
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      try {
        _firestore = FirebaseFirestore.instance;
        return _firestore;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _galleryCol =>
      _safeFirestore?.collection(AppConstants.colGallery);

  Stream<List<GalleryModel>> streamEventGallery(String eventId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _galleryCol != null) {
      return _galleryCol!
          .where('eventId', isEqualTo: eventId)
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => GalleryModel.fromFirestore(d)).toList())
          .handleError((_) => _localStore.getEventGallery(eventId));
    }
    return Stream.value(_localStore.getEventGallery(eventId));
  }

  Future<List<GalleryModel>> getEventGallery(String eventId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _galleryCol != null) {
      try {
        final snap = await _galleryCol!
            .where('eventId', isEqualTo: eventId)
            .orderBy('uploadedAt', descending: true)
            .get();
        return snap.docs.map((d) => GalleryModel.fromFirestore(d)).toList();
      } catch (_) {}
    }
    return _localStore.getEventGallery(eventId);
  }

  /// Admin/Organizer: Upload gallery image
  Future<String> uploadPhoto({
    required String eventId,
    required String uploadedBy,
    String? uploaderName,
    required String imageUrl,
    String? caption,
  }) async {
    _localStore.addGalleryPhoto(
      eventId: eventId,
      uploadedBy: uploadedBy,
      uploaderName: uploaderName ?? 'Organizer',
      imageUrl: imageUrl,
      caption: caption,
    );

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _galleryCol != null) {
      try {
        final docRef = _galleryCol!.doc();
        final item = GalleryModel(
          id: docRef.id,
          eventId: eventId,
          uploadedBy: uploadedBy,
          uploaderName: uploaderName,
          imageUrl: imageUrl,
          caption: caption,
          uploadedAt: DateTime.now(),
        );
        await docRef.set(item.toMap());
        return docRef.id;
      } catch (_) {}
    }

    return 'gal_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Admin: Fetch all gallery images system-wide for moderation
  Future<List<GalleryModel>> getAllGalleryMedia() async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _galleryCol != null) {
      try {
        final snap = await _galleryCol!.orderBy('uploadedAt', descending: true).get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => GalleryModel.fromFirestore(d)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getAllGallery();
  }

  /// Admin: Delete inappropriate media
  Future<void> deleteMedia(String mediaId) async {
    _localStore.deleteGalleryPhoto(mediaId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _galleryCol != null) {
      try {
        await _galleryCol!.doc(mediaId).delete();
      } catch (_) {}
    }
  }
}
