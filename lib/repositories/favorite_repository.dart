import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/favorite_model.dart';
import '../services/local_data_store.dart';

/// Repository managing user bookmarking and saved events with dual-engine fallback
class FavoriteRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  FavoriteRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

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

  CollectionReference<Map<String, dynamic>>? get _favCol =>
      _safeFirestore?.collection(AppConstants.colFavorites);

  String _generateFavDocId(String userId, String eventId) => '${userId}_$eventId';

  Future<bool> isEventFavorited({required String userId, required String eventId, String? userEmail}) async {
    if (_localStore.isFavorite(userId, eventId, userEmail)) return true;
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _favCol != null) {
      try {
        final doc = await _favCol!.doc(_generateFavDocId(userId, eventId)).get().timeout(const Duration(milliseconds: 1500));
        if (doc.exists) return true;
      } catch (_) {}
    }
    return false;
  }

  Stream<bool> streamIsFavorited({required String userId, required String eventId, String? userEmail}) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _favCol != null) {
      return _favCol!.doc(_generateFavDocId(userId, eventId)).snapshots().map((doc) => doc.exists).handleError((_) => _localStore.isFavorite(userId, eventId, userEmail));
    }
    return Stream.value(_localStore.isFavorite(userId, eventId, userEmail));
  }

  Future<void> toggleFavorite({required String userId, required String eventId, String? userEmail}) async {
    _localStore.toggleFavorite(userId, eventId, userEmail);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _favCol != null) {
      try {
        final docRef = _favCol!.doc(_generateFavDocId(userId, eventId));
        final doc = await docRef.get().timeout(const Duration(milliseconds: 1500));

        if (doc.exists) {
          await docRef.delete();
        } else {
          final fav = FavoriteModel(
            id: docRef.id,
            userId: userId,
            eventId: eventId,
            createdAt: DateTime.now(),
          );
          await docRef.set(fav.toMap());
        }
      } catch (_) {}
    }
  }

  Stream<List<FavoriteModel>> streamUserFavorites(String userId, [String? userEmail]) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _favCol != null) {
      return _favCol!
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map((d) => FavoriteModel.fromFirestore(d)).toList();
            final localList = _localStore.getUserFavorites(userId, userEmail);
            for (final loc in localList) {
              if (!list.any((l) => l.eventId == loc.eventId)) {
                list.add(loc);
              }
            }
            return list;
          })
          .handleError((_) => _localStore.getUserFavorites(userId, userEmail));
    }
    return Stream.value(_localStore.getUserFavorites(userId, userEmail));
  }

  Future<List<FavoriteModel>> getUserFavorites(String userId, [String? userEmail]) async {
    final localList = _localStore.getUserFavorites(userId, userEmail);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _favCol != null) {
      try {
        final snap = await _favCol!
            .where('userId', isEqualTo: userId)
            .get()
            .timeout(const Duration(milliseconds: 2000));
        var list = snap.docs.map((d) => FavoriteModel.fromFirestore(d)).toList();
        for (final loc in localList) {
          if (!list.any((l) => l.eventId == loc.eventId)) {
            list.add(loc);
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (_) {}
    }
    return localList;
  }
}
