import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/feedback_model.dart';
import '../services/local_data_store.dart';

/// Repository managing post-event feedback and ratings with dual-engine fallback
class FeedbackRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  FeedbackRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

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

  CollectionReference<Map<String, dynamic>>? get _feedbackCol =>
      _safeFirestore?.collection(AppConstants.colFeedback);

  String _generateDocId(String userId, String eventId) => '${userId}_$eventId';

  Future<bool> hasUserSubmittedFeedback({required String userId, required String eventId}) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        final doc = await _feedbackCol!.doc(_generateDocId(userId, eventId)).get();
        if (doc.exists) return true;
      } catch (_) {}
    }
    return _localStore.hasSubmittedFeedback(userId, eventId);
  }

  Future<FeedbackModel?> getUserFeedback({required String userId, required String eventId}) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        final doc = await _feedbackCol!.doc(_generateDocId(userId, eventId)).get();
        if (doc.exists && doc.data() != null) {
          return FeedbackModel.fromFirestore(doc);
        }
      } catch (_) {}
    }
    final list = _localStore.getEventFeedback(eventId);
    final match = list.where((f) => f.userId == userId);
    return match.isNotEmpty ? match.first : null;
  }

  Future<void> submitFeedback({
    required String eventId,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
  }) async {
    _localStore.submitFeedback(
      eventId: eventId,
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment,
    );

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        final docId = _generateDocId(userId, eventId);
        final docRef = _feedbackCol!.doc(docId);

        final feedback = FeedbackModel(
          id: docId,
          eventId: eventId,
          userId: userId,
          userName: userName,
          rating: rating.clamp(1, 5),
          comment: comment,
          submittedAt: DateTime.now(),
        );

        await docRef.set(feedback.toMap());
      } catch (_) {}
    }
  }

  List<FeedbackModel> getEventFeedbackLocal(String eventId, [List<String>? organizerEventIds]) {
    final local = _localStore.getEventFeedback(eventId.isEmpty ? 'all' : eventId);
    if ((eventId.isEmpty || eventId == 'all') && organizerEventIds != null && organizerEventIds.isNotEmpty) {
      final matching = local.where((f) => organizerEventIds.contains(f.eventId)).toList();
      if (matching.isNotEmpty) {
        return matching;
      }
    }
    return local;
  }

  Stream<List<FeedbackModel>> streamEventFeedback(String eventId, [List<String>? organizerEventIds]) async* {
    // 1. Instantly yield local cached feedback
    yield getEventFeedbackLocal(eventId, organizerEventIds);

    // 2. If live firebase is active, listen to firestore snapshots safely
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        Query<Map<String, dynamic>> query = _feedbackCol!;
        if (eventId.isNotEmpty && eventId != 'all') {
          query = query.where('eventId', isEqualTo: eventId);
        }
        await for (final snap in query.snapshots()) {
          var list = snap.docs.map((d) => FeedbackModel.fromFirestore(d)).toList();
          if (eventId.isEmpty || eventId == 'all') {
            if (organizerEventIds != null && organizerEventIds.isNotEmpty) {
              final matching = list.where((f) => organizerEventIds.contains(f.eventId)).toList();
              if (matching.isNotEmpty) {
                list = matching;
              }
            }
          }
          final localList = _localStore.getEventFeedback(eventId.isEmpty ? 'all' : eventId);
          for (final loc in localList) {
            if (!list.any((f) => f.id == loc.id)) {
              if (organizerEventIds == null || organizerEventIds.isEmpty || organizerEventIds.contains(loc.eventId) || list.isEmpty) {
                list.add(loc);
              }
            }
          }
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          yield list;
        }
      } catch (_) {
        yield getEventFeedbackLocal(eventId, organizerEventIds);
      }
    }
  }

  Future<List<FeedbackModel>> getEventFeedback(String eventId, [List<String>? organizerEventIds]) async {
    List<FeedbackModel> list = [];
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        if (eventId.isEmpty || eventId == 'all') {
          final snap = await _feedbackCol!
              .get()
              .timeout(const Duration(milliseconds: 2500));
          list = snap.docs.map((d) => FeedbackModel.fromFirestore(d)).toList();
        } else {
          final snap = await _feedbackCol!
              .where('eventId', isEqualTo: eventId)
              .get()
              .timeout(const Duration(milliseconds: 2500));
          list = snap.docs.map((d) => FeedbackModel.fromFirestore(d)).toList();
        }
      } catch (_) {}
    }

    final localList = _localStore.getEventFeedback(eventId.isEmpty ? 'all' : eventId);
    for (final loc in localList) {
      if (!list.any((d) => d.id == loc.id)) {
        list.add(loc);
      }
    }

    if ((eventId.isEmpty || eventId == 'all') && organizerEventIds != null && organizerEventIds.isNotEmpty) {
      final matching = list.where((f) => organizerEventIds.contains(f.eventId)).toList();
      if (matching.isNotEmpty) {
        list = matching;
      }
    }

    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  /// Aggregation: Calculate average rating for an event
  Future<double> getAverageRatingForEvent(String eventId) async {
    final list = await getEventFeedback(eventId);
    if (list.isEmpty) return 0.0;
    final sum = list.fold<int>(0, (prev, curr) => prev + curr.rating);
    return sum / list.length;
  }

  /// Admin: Fetch all feedback system-wide for reporting
  Future<List<FeedbackModel>> getAllFeedback() async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        final snap = await _feedbackCol!.get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => FeedbackModel.fromFirestore(d)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getAllFeedback();
  }

  /// Admin: Delete inappropriate feedback
  Future<void> deleteFeedback(String feedbackId) async {
    _localStore.deleteFeedback(feedbackId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _feedbackCol != null) {
      try {
        await _feedbackCol!.doc(feedbackId).delete();
      } catch (_) {}
    }
  }
}
