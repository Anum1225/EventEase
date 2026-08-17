import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../services/local_data_store.dart';

/// Repository managing atomic registrations and attendee event histories with dual-engine fallback
class RegistrationRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();
  final Uuid _uuid;

  RegistrationRepository({FirebaseFirestore? firestore, Uuid? uuid})
      : _firestore = firestore,
        _uuid = uuid ?? const Uuid();

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

  CollectionReference<Map<String, dynamic>>? get _regCol =>
      _safeFirestore?.collection(AppConstants.colRegistrations);

  CollectionReference<Map<String, dynamic>>? get _eventsCol =>
      _safeFirestore?.collection(AppConstants.colEvents);

  /// Atomic 7-step Registration Transaction preventing race conditions & duplicates
  Future<RegistrationModel> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    // 1. Try Firebase Firestore Transaction only if live credentials configured
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _safeFirestore != null && _regCol != null && _eventsCol != null) {
      try {
        // Prevent duplicate registration for the same user & event
        final existingSnap = await _regCol!
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: AppConstants.registrationStatusRegistered)
            .limit(1)
            .get();
        if (existingSnap.docs.isNotEmpty) {
          throw Exception('You are already registered for this event.');
        }

        final registrationDocRef = _regCol!.doc();
        final eventDocRef = _eventsCol!.doc(eventId);

        final registration = await _safeFirestore!.runTransaction<RegistrationModel>((transaction) async {
          final eventDoc = await transaction.get(eventDocRef);
          if (!eventDoc.exists || eventDoc.data() == null) {
            throw Exception('Event does not exist.');
          }

          final event = EventModel.fromFirestore(eventDoc);
          if (event.status != AppConstants.eventStatusApproved) {
            throw Exception('Registration is not open for this event (${event.status}).');
          }

          if (event.registeredCount >= event.maxParticipants) {
            throw Exception('Event is currently full (Capacity: ${event.maxParticipants}).');
          }

          final qrToken = 'EASE-${_uuid.v4()}-${registrationDocRef.id.substring(0, 6)}';

          final newReg = RegistrationModel(
            id: registrationDocRef.id,
            eventId: eventId,
            userId: userId,
            eventTitle: event.title,
            eventDate: event.date,
            eventLocation: event.location,
            eventBanner: event.imageUrl,
            eventCategory: event.category,
            userName: userName,
            userEmail: userEmail,
            registeredAt: DateTime.now(),
            status: AppConstants.registrationStatusRegistered,
            qrCode: qrToken,
          );

          transaction.set(registrationDocRef, newReg.toMap());
          transaction.update(eventDocRef, {
            'registeredCount': FieldValue.increment(1),
          });

          return newReg;
        });

        // Safely sync local cache without failing successful Firestore transaction
        try {
          _localStore.registerForEvent(
            eventId: eventId,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            eventTitle: registration.eventTitle ?? 'Event',
          );
        } catch (_) {}

        return registration;
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('already registered') ||
            errorMsg.contains('full') ||
            errorMsg.contains('not open') ||
            errorMsg.contains('does not exist')) {
          throw Exception(errorMsg);
        }
      }
    }

    // 2. Local database engine fallback
    final event = _localStore.getEventById(eventId);
    if (event == null) throw Exception('Event does not exist.');
    return _localStore.registerForEvent(
      eventId: eventId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      eventTitle: event.title,
    );
  }

  /// Cancel registration and decrement capacity count
  Future<void> cancelRegistration({
    required String registrationId,
    required String eventId,
  }) async {
    _localStore.cancelRegistration(registrationId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _safeFirestore != null && _regCol != null && _eventsCol != null) {
      try {
        final regDocRef = _regCol!.doc(registrationId);
        final eventDocRef = _eventsCol!.doc(eventId);

        await _safeFirestore!.runTransaction((transaction) async {
          final regDoc = await transaction.get(regDocRef);
          if (!regDoc.exists) return;

          final reg = RegistrationModel.fromFirestore(regDoc);
          if (reg.status == AppConstants.registrationStatusCancelled) return;

          transaction.update(regDocRef, {
            'status': AppConstants.registrationStatusCancelled,
          });

          transaction.update(eventDocRef, {
            'registeredCount': FieldValue.increment(-1),
          });
        });
      } catch (_) {}
    }
  }

  /// Check if an attendee is registered for a specific event
  Future<RegistrationModel?> getUserRegistrationForEvent({
    required String eventId,
    required String userId,
  }) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        final snap = await _regCol!
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: AppConstants.registrationStatusRegistered)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          return RegistrationModel.fromFirestore(snap.docs.first);
        }
      } catch (_) {}
    }

    final localList = _localStore.getUserRegistrations(userId);
    final match = localList.where((r) => r.eventId == eventId && r.isRegistered);
    return match.isNotEmpty ? match.first : null;
  }

  Stream<RegistrationModel?> streamUserRegistrationForEvent({
    required String eventId,
    required String userId,
  }) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      return _regCol!
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snap) {
        final active = snap.docs.where((d) =>
            d.data()['status'] == AppConstants.registrationStatusRegistered);
        if (active.isEmpty) {
          final localList = _localStore.getUserRegistrations(userId);
          final match = localList.where((r) => r.eventId == eventId && r.isRegistered);
          return match.isNotEmpty ? match.first : null;
        }
        return RegistrationModel.fromFirestore(active.first);
      }).handleError((_) {
        final localList = _localStore.getUserRegistrations(userId);
        final match = localList.where((r) => r.eventId == eventId && r.isRegistered);
        return match.isNotEmpty ? match.first : null;
      });
    }

    final localList = _localStore.getUserRegistrations(userId);
    final match = localList.where((r) => r.eventId == eventId && r.isRegistered);
    return Stream.value(match.isNotEmpty ? match.first : null);
  }

  /// Stream all registrations for an attendee
  Stream<List<RegistrationModel>> streamUserRegistrations(String userId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      return _regCol!
          .where('userId', isEqualTo: userId)
          .orderBy('registeredAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList())
          .handleError((_) => _localStore.getUserRegistrations(userId));
    }
    return Stream.value(_localStore.getUserRegistrations(userId));
  }

  Future<List<RegistrationModel>> getUserRegistrations(String userId, [String? userEmail]) async {
    List<RegistrationModel> list = [];
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        final snap = await _regCol!
            .where('userId', isEqualTo: userId)
            .get();
        list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
      } catch (_) {}
    }
    final localList = _localStore.getUserRegistrations(userId, userEmail);
    for (final loc in localList) {
      if (!list.any((r) => r.id == loc.id || (r.eventId == loc.eventId && r.isRegistered))) {
        list.add(loc);
      }
    }
    list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    return list;
  }

  /// Organizer: Get all registered participants for an event
  Stream<List<RegistrationModel>> streamEventParticipants(String eventId, [List<String>? organizerEventIds]) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      if (eventId.isEmpty || eventId == 'all') {
        return _regCol!
            .orderBy('registeredAt', descending: false)
            .snapshots()
            .map((snap) {
              var list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
              if (organizerEventIds != null && organizerEventIds.isNotEmpty) {
                list = list.where((r) => organizerEventIds.contains(r.eventId)).toList();
              }
              final localList = _localStore.getEventParticipants('all', organizerEventIds);
              for (final loc in localList) {
                if (!list.any((r) => r.id == loc.id)) {
                  list.add(loc);
                }
              }
              return list;
            })
            .handleError((_) => _localStore.getEventParticipants('all', organizerEventIds));
      }

      return _regCol!
          .where('eventId', isEqualTo: eventId)
          .orderBy('registeredAt', descending: false)
          .snapshots()
          .map((snap) {
            var list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
            final localList = _localStore.getEventParticipants(eventId);
            for (final loc in localList) {
              if (!list.any((r) => r.id == loc.id)) {
                list.add(loc);
              }
            }
            return list;
          })
          .handleError((_) => _localStore.getEventParticipants(eventId));
    }
    return Stream.value(_localStore.getEventParticipants(eventId, organizerEventIds));
  }

  Future<List<RegistrationModel>> getEventParticipants(String eventId, [List<String>? organizerEventIds]) async {
    List<RegistrationModel> list = [];
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        if (eventId.isEmpty || eventId == 'all') {
          final snap = await _regCol!
              .orderBy('registeredAt', descending: false)
              .get()
              .timeout(const Duration(milliseconds: 2500));
          list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
        } else {
          final snap = await _regCol!
              .where('eventId', isEqualTo: eventId)
              .orderBy('registeredAt', descending: false)
              .get()
              .timeout(const Duration(milliseconds: 2500));
          list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
        }
      } catch (_) {}
    }

    final localList = _localStore.getEventParticipants(eventId, organizerEventIds);
    for (final loc in localList) {
      if (!list.any((r) => r.id == loc.id)) {
        list.add(loc);
      }
    }

    if ((eventId.isEmpty || eventId == 'all') && organizerEventIds != null && organizerEventIds.isNotEmpty) {
      list = list.where((r) => organizerEventIds.contains(r.eventId)).toList();
    } else if (eventId.isNotEmpty && eventId != 'all') {
      list = list.where((r) => r.eventId == eventId || localList.any((l) => l.id == r.id)).toList();
    }

    list.sort((a, b) => (a.userName ?? '').compareTo(b.userName ?? ''));
    return list;
  }

  /// Lookup a registration by its QR payload code
  Future<RegistrationModel?> getRegistrationByQrCode(String qrCode) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        final snap = await _regCol!
            .where('qrCode', isEqualTo: qrCode)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 1));
        if (snap.docs.isNotEmpty) {
          return RegistrationModel.fromFirestore(snap.docs.first);
        }
      } catch (_) {}
    }
    return _localStore.getRegistrationByQr(qrCode);
  }

  /// Lookup a registration by ID
  Future<RegistrationModel?> getRegistrationById(String registrationId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        final doc = await _regCol!.doc(registrationId).get().timeout(const Duration(seconds: 1));
        if (doc.exists && doc.data() != null) {
          return RegistrationModel.fromFirestore(doc);
        }
      } catch (_) {}
    }
    return _localStore.getRegistrationById(registrationId);
  }
}
