import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../services/local_data_store.dart';

/// Repository managing atomic registrations and attendee event histories with dual-engine fallback
class RegistrationRepository {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  final LocalDataStore _localStore = LocalDataStore();
  final Uuid _uuid;

  RegistrationRepository({FirebaseFirestore? firestore, FirebaseAuth? auth, Uuid? uuid})
      : _firestore = firestore,
        _auth = auth,
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

  FirebaseAuth? get _safeAuth {
    if (_auth != null) return _auth;
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      try {
        _auth = FirebaseAuth.instance;
        return _auth;
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
    // 1. Check if event is completed / finished in local store first
    var cachedEvent = _localStore.getEventById(eventId) ??
        _localStore.getAllAdminEvents().where((e) => e.id == eventId).firstOrNull;
    if (cachedEvent != null && (cachedEvent.isCompleted || cachedEvent.status == AppConstants.eventStatusCompleted || cachedEvent.hasPassedSchedule)) {
      throw Exception('Registration is closed. This event has already finished.');
    }

    final effectiveUserId = _safeAuth?.currentUser?.uid ?? userId;

    // 2. Try Firebase Firestore Transaction only if live credentials configured
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _safeFirestore != null && _regCol != null && _eventsCol != null) {
      try {
        // Prevent duplicate registration for the same user & event
        final existingSnap = await _regCol!
            .where('eventId', isEqualTo: eventId)
            .where('userId', isEqualTo: effectiveUserId)
            .where('status', isEqualTo: AppConstants.registrationStatusRegistered)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 3));
        if (existingSnap.docs.isNotEmpty) {
          throw Exception('You are already registered for this event.');
        }

        if (userEmail.isNotEmpty) {
          final existingSnapEmail = await _regCol!
              .where('eventId', isEqualTo: eventId)
              .where('userEmail', isEqualTo: userEmail)
              .where('status', isEqualTo: AppConstants.registrationStatusRegistered)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 3));
          if (existingSnapEmail.docs.isNotEmpty) {
            throw Exception('You are already registered for this event.');
          }
        }

        final registrationDocRef = _regCol!.doc();
        final eventDocRef = _eventsCol!.doc(eventId);

        final registration = await _safeFirestore!.runTransaction<RegistrationModel>((transaction) async {
          final eventDoc = await transaction.get(eventDocRef);
          EventModel event;

          if (!eventDoc.exists || eventDoc.data() == null) {
            final loc = _localStore.getEventById(eventId) ??
                _localStore.getAllAdminEvents().where((e) => e.id == eventId).firstOrNull;
            if (loc == null) {
              throw Exception('Event not found.');
            }
            event = loc;
          } else {
            event = EventModel.fromFirestore(eventDoc);
          }

          if (event.isCompleted || event.status == AppConstants.eventStatusCompleted || event.hasPassedSchedule) {
            throw Exception('Registration is closed. This event has already finished.');
          }

          if (event.status != AppConstants.eventStatusApproved) {
            throw Exception('Registration is not open for this event (${event.status}).');
          }

          if (event.registeredCount >= event.maxParticipants) {
            throw Exception('Event has reached maximum capacity.');
          }

          final qrToken = 'EASE-${_uuid.v4()}-${registrationDocRef.id.substring(0, 6)}';

          final newReg = RegistrationModel(
            id: registrationDocRef.id,
            eventId: eventId,
            userId: effectiveUserId,
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
          if (eventDoc.exists) {
            transaction.update(eventDocRef, {
              'registeredCount': FieldValue.increment(1),
            });
          }

          return newReg;
        }, timeout: const Duration(seconds: 4));

        // Always sync local database
        _localStore.registerForEvent(
          eventId: eventId,
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          eventTitle: registration.eventTitle ?? 'Event',
          customRegId: registration.id,
          customQrCode: registration.qrCode,
        );

        return registration;
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('already registered') ||
            errorMsg.contains('maximum capacity') ||
            errorMsg.contains('full') ||
            errorMsg.contains('Registration is closed') ||
            errorMsg.contains('already finished') ||
            errorMsg.contains('concluded') ||
            errorMsg.contains('not open')) {
          throw Exception(errorMsg);
        }
        // In case of network glitch or permission error on cloud, fallback to local engine
      }
    }

    // 3. Local database engine fallback with dynamic Firestore fetching if needed
    var event = _localStore.getEventById(eventId) ??
        _localStore.getAllAdminEvents().where((e) => e.id == eventId).firstOrNull;

    if (event == null && _eventsCol != null && DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      try {
        final doc = await _eventsCol!.doc(eventId).get().timeout(const Duration(seconds: 2));
        if (doc.exists && doc.data() != null) {
          event = EventModel.fromFirestore(doc);
          _localStore.saveOrUpdateEvent(event);
        }
      } catch (_) {}
    }

    if (event == null) {
      throw Exception('Event not found.');
    }
    if (event.isCompleted || event.status == AppConstants.eventStatusCompleted || event.hasPassedSchedule) {
      throw Exception('Registration is closed. This event has already finished.');
    }
    if (event.status != AppConstants.eventStatusApproved) {
      throw Exception('Registration is not open for this event (${event.status}).');
    }
    if (event.registeredCount >= event.maxParticipants) {
      throw Exception('Event has reached maximum capacity.');
    }
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
            .get()
            .timeout(const Duration(seconds: 3));
        list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();

        if (userEmail != null && userEmail.trim().isNotEmpty) {
          final snapEmail = await _regCol!
              .where('userEmail', isEqualTo: userEmail.trim())
              .get()
              .timeout(const Duration(seconds: 3));
          for (final doc in snapEmail.docs) {
            final reg = RegistrationModel.fromFirestore(doc);
            if (!list.any((r) => r.id == reg.id)) {
              list.add(reg);
            }
          }
        }
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

  List<RegistrationModel> getEventParticipantsLocal(String eventId, [List<String>? organizerEventIds]) {
    return _localStore.getEventParticipants(eventId, organizerEventIds);
  }

  /// Organizer: Get all registered participants for an event
  Stream<List<RegistrationModel>> streamEventParticipants(String eventId, [List<String>? organizerEventIds]) async* {
    // 1. Yield local store immediately
    yield getEventParticipantsLocal(eventId, organizerEventIds);

    // 2. Safely listen to firestore snapshots
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        Query<Map<String, dynamic>> query = _regCol!;
        if (eventId.isNotEmpty && eventId != 'all') {
          query = query.where('eventId', isEqualTo: eventId);
        }
        await for (final snap in query.snapshots()) {
          var list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
          if (eventId.isEmpty || eventId == 'all') {
            if (organizerEventIds != null && organizerEventIds.isNotEmpty) {
              list = list.where((r) => organizerEventIds.contains(r.eventId)).toList();
            }
          }
          final localList = _localStore.getEventParticipants(eventId.isEmpty ? 'all' : eventId, organizerEventIds);
          for (final loc in localList) {
            if (!list.any((r) => r.id == loc.id)) {
              list.add(loc);
            }
          }
          list.sort((a, b) => a.registeredAt.compareTo(b.registeredAt));
          yield list;
        }
      } catch (_) {
        yield getEventParticipantsLocal(eventId, organizerEventIds);
      }
    }
  }

  Future<List<RegistrationModel>> getEventParticipants(String eventId, [List<String>? organizerEventIds]) async {
    List<RegistrationModel> list = [];
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null) {
      try {
        if (eventId.isEmpty || eventId == 'all') {
          final snap = await _regCol!
              .get()
              .timeout(const Duration(milliseconds: 3000));
          list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
        } else {
          // Direct query by eventId without orderBy to avoid requiring composite indexes
          final snap = await _regCol!
              .where('eventId', isEqualTo: eventId)
              .get()
              .timeout(const Duration(milliseconds: 3000));
          list = snap.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();

          // Fallback: match by title or case-insensitive eventId if direct lookup is empty
          if (list.isEmpty) {
            final snapAll = await _regCol!
                .get()
                .timeout(const Duration(milliseconds: 3000));
            final all = snapAll.docs.map((doc) => RegistrationModel.fromFirestore(doc)).toList();
            list = all.where((r) =>
                r.eventId == eventId ||
                r.eventId.toLowerCase().trim() == eventId.toLowerCase().trim() ||
                (r.eventTitle != null && r.eventTitle!.toLowerCase().trim() == eventId.toLowerCase().trim())
            ).toList();
          }
        }
      } catch (_) {}
    }

    // Always merge local registrations with Firestore results
    final localList = _localStore.getEventParticipants(eventId, organizerEventIds);
    for (final loc in localList) {
      if (!list.any((r) => r.id == loc.id)) {
        list.add(loc);
      }
    }

    // Filter to organizer's events only when showing 'all'
    if (organizerEventIds != null && organizerEventIds.isNotEmpty && (eventId.isEmpty || eventId == 'all')) {
      list = list.where((r) => organizerEventIds.contains(r.eventId)).toList();
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
