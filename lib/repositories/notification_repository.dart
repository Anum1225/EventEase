import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/notification_model.dart';
import '../services/local_data_store.dart';

/// Repository managing in-app notifications and trigger dispatch with dual-engine fallback
class NotificationRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  NotificationRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

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

  CollectionReference<Map<String, dynamic>>? get _notifCol =>
      _safeFirestore?.collection(AppConstants.colNotifications);

  CollectionReference<Map<String, dynamic>>? get _regCol =>
      _safeFirestore?.collection(AppConstants.colRegistrations);

  Stream<List<NotificationModel>> streamUserNotifications(String userId, [String? userEmail]) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _notifCol != null) {
      return _notifCol!
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
            final local = _localStore.getUserNotifications(userId, userEmail);
            for (final l in local) {
              if (!list.any((rem) => rem.id == l.id)) {
                list.add(l);
              }
            }
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          })
          .handleError((_) => _localStore.getUserNotifications(userId, userEmail));
    }
    return Stream.value(_localStore.getUserNotifications(userId, userEmail));
  }

  Future<List<NotificationModel>> getUserNotifications(String userId, [String? userEmail]) async {
    final List<NotificationModel> list = [];
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _notifCol != null) {
      try {
        final snap = await _notifCol!
            .where('userId', isEqualTo: userId)
            .get()
            .timeout(const Duration(seconds: 3));
        list.addAll(snap.docs.map((d) => NotificationModel.fromFirestore(d)));
      } catch (_) {}
    }

    final local = _localStore.getUserNotifications(userId, userEmail);
    for (final l in local) {
      if (!list.any((rem) => rem.id == l.id)) {
        list.add(l);
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? eventId,
  }) async {
    _localStore.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      eventId: eventId,
    );

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _notifCol != null) {
      try {
        final docRef = _notifCol!.doc();
        final notif = NotificationModel(
          id: docRef.id,
          userId: userId,
          eventId: eventId,
          title: title,
          message: message,
          type: type,
          isRead: false,
          createdAt: DateTime.now(),
        );
        await docRef.set(notif.toMap());
      } catch (_) {}
    }
  }

  /// Sends a broadcast notification to all attendees registered for an event
  Future<void> broadcastToEventParticipants({
    required String eventId,
    required String title,
    required String message,
    required String type,
  }) async {
    _localStore.broadcastAnnouncement(
      eventId: eventId,
      title: title,
      message: message,
    );

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _safeFirestore != null && _regCol != null && _notifCol != null) {
      try {
        final regSnap = await _regCol!
            .where('eventId', isEqualTo: eventId)
            .where('status', isEqualTo: AppConstants.registrationStatusRegistered)
            .get();

        final batch = _safeFirestore!.batch();
        for (final doc in regSnap.docs) {
          final userId = doc.data()['userId'] as String?;
          if (userId != null && userId.isNotEmpty) {
            final notifDocRef = _notifCol!.doc();
            final notif = NotificationModel(
              id: notifDocRef.id,
              userId: userId,
              eventId: eventId,
              title: title,
              message: message,
              type: type,
              isRead: false,
              createdAt: DateTime.now(),
            );
            batch.set(notifDocRef, notif.toMap());
          }
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> markAsRead(String notificationId) async {
    _localStore.markNotificationAsRead(notificationId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _notifCol != null) {
      try {
        await _notifCol!.doc(notificationId).update({'isRead': true});
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead(String userId) async {
    _localStore.markAllNotificationsAsRead(userId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _safeFirestore != null && _notifCol != null) {
      try {
        final unreadSnap = await _notifCol!
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        final batch = _safeFirestore!.batch();
        for (final doc in unreadSnap.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      } catch (_) {}
    }
  }
}
