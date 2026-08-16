import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/event_model.dart';
import '../services/local_data_store.dart';

/// Repository managing event lifecycle, filtering, and admin moderation with dual-engine fallback
class EventRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();
  final Uuid _uuid = const Uuid();

  EventRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

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

  CollectionReference<Map<String, dynamic>>? get _eventsCol =>
      _safeFirestore?.collection(AppConstants.colEvents);

  /// Synchronous fast cache access for 0ms initial frame render
  List<EventModel> getDiscoverableEventsSync({String? category, String? searchQuery}) {
    return _localStore.getApprovedEvents(category: category, query: searchQuery);
  }

  List<EventModel> getOrganizerEventsSync(String organizerId) {
    return _localStore.getEventsByOrganizer(organizerId);
  }

  List<EventModel> getPendingApprovalEventsSync() {
    return _localStore.getPendingApprovalEvents();
  }

  List<EventModel> getAllEventsSync() {
    return _localStore.getAllAdminEvents();
  }

  /// Attendee: Get approved discoverable events with robust filtering & fast timeout
  Future<List<EventModel>> getDiscoverableEvents({
    String? category,
    String? searchQuery,
    DateTime? date,
    String? location,
    bool onlyAvailable = false,
  }) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        Query<Map<String, dynamic>> query = _eventsCol!
            .where('status', isEqualTo: AppConstants.eventStatusApproved);

        final snap = await query.get().timeout(const Duration(milliseconds: 2500));
        if (snap.docs.isNotEmpty) {
          var events = snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();

          if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
            events = events.where((e) => e.category.toLowerCase() == category.toLowerCase()).toList();
          }

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final qLower = searchQuery.trim().toLowerCase();
            events = events.where((e) =>
                e.title.toLowerCase().contains(qLower) ||
                e.description.toLowerCase().contains(qLower) ||
                e.location.toLowerCase().contains(qLower)).toList();
          }

          if (location != null && location.trim().isNotEmpty) {
            final lLower = location.trim().toLowerCase();
            events = events.where((e) => e.location.toLowerCase().contains(lLower)).toList();
          }

          if (date != null) {
            events = events.where((e) =>
                e.date.year == date.year &&
                e.date.month == date.month &&
                e.date.day == date.day).toList();
          }

          if (onlyAvailable) {
            events = events.where((e) => !e.isFull).toList();
          }

          events.sort((a, b) => a.date.compareTo(b.date));
          return events;
        }
      } catch (_) {}
    }

    return _localStore.getApprovedEvents(
      category: category,
      query: searchQuery,
      date: date,
      location: location,
      onlyAvailable: onlyAvailable,
    );
  }

  Future<EventModel?> getEventById(String eventId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        final doc = await _eventsCol!.doc(eventId).get().timeout(const Duration(milliseconds: 2500));
        if (doc.exists && doc.data() != null) {
          return EventModel.fromFirestore(doc);
        }
      } catch (_) {}
    }
    return _localStore.getEventById(eventId);
  }

  Stream<EventModel?> streamEventById(String eventId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      return _eventsCol!.doc(eventId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return _localStore.getEventById(eventId);
        }
        return EventModel.fromFirestore(doc);
      }).handleError((_) => _localStore.getEventById(eventId));
    }
    return Stream.value(_localStore.getEventById(eventId));
  }

  /// Organizer: Stream events owned by a specific organizer
  Stream<List<EventModel>> streamOrganizerEvents(String organizerId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      return _eventsCol!
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList())
          .handleError((_) => _localStore.getEventsByOrganizer(organizerId));
    }
    return Stream.value(_localStore.getEventsByOrganizer(organizerId));
  }

  Future<List<EventModel>> getOrganizerEvents(String organizerId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        final snap = await _eventsCol!
            .where('organizerId', isEqualTo: organizerId)
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(const Duration(milliseconds: 2500));
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getEventsByOrganizer(organizerId);
  }

  /// Organizer: Create event (always defaults to pending_approval)
  Future<String> createEvent(EventModel event) async {
    final generatedId = event.id.isNotEmpty ? event.id : 'evt_${_uuid.v4().substring(0, 8)}';
    final newEvent = event.copyWith(
      id: generatedId,
      status: AppConstants.eventStatusPendingApproval,
      registeredCount: 0,
      createdAt: DateTime.now(),
    );

    _localStore.createEvent(newEvent);

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(generatedId).set(newEvent.toMap()).timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }

    return generatedId;
  }

  /// Organizer/Admin: Update event
  Future<void> updateEvent(EventModel event) async {
    _localStore.updateEvent(event);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(event.id).update(event.toMap()).timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }
  }

  /// Organizer/Admin: Cancel event
  Future<void> cancelEvent(String eventId, String reason) async {
    _localStore.cancelEvent(eventId, reason);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(eventId).update({
          'status': AppConstants.eventStatusCancelled,
          'cancellationReason': reason,
        }).timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }
  }

  /// Admin: Get pending approval queue
  Future<List<EventModel>> getPendingApprovalEvents() async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        final snap = await _eventsCol!
            .where('status', isEqualTo: AppConstants.eventStatusPendingApproval)
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(const Duration(milliseconds: 2500));
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getPendingApprovalEvents();
  }

  /// Admin: Approve event
  Future<void> approveEvent(String eventId) async {
    _localStore.approveEvent(eventId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(eventId).update({
          'status': AppConstants.eventStatusApproved,
          'rejectionReason': FieldValue.delete(),
        }).timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }
  }

  /// Admin: Reject event with mandatory reason
  Future<void> rejectEvent(String eventId, String reason) async {
    _localStore.rejectEvent(eventId, reason);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(eventId).update({
          'status': AppConstants.eventStatusRejected,
          'rejectionReason': reason,
        }).timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }
  }

  /// Admin: Fetch all events system-wide with optional filters
  Future<List<EventModel>> getAllEvents({String? status, String? query}) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        Query<Map<String, dynamic>> q = _eventsCol!.orderBy('createdAt', descending: true);
        if (status != null && status.isNotEmpty) {
          q = q.where('status', isEqualTo: status);
        }
        final snap = await q.get().timeout(const Duration(milliseconds: 2500));
        if (snap.docs.isNotEmpty) {
          var list = snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
          if (query != null && query.trim().isNotEmpty) {
            final qLower = query.trim().toLowerCase();
            list = list.where((e) =>
                e.title.toLowerCase().contains(qLower) ||
                e.category.toLowerCase().contains(qLower) ||
                e.location.toLowerCase().contains(qLower)).toList();
          }
          return list;
        }
      } catch (_) {}
    }

    var localList = _localStore.getAllAdminEvents();
    if (status != null && status.isNotEmpty) {
      localList = localList.where((e) => e.status == status).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final qLower = query.trim().toLowerCase();
      localList = localList.where((e) =>
          e.title.toLowerCase().contains(qLower) ||
          e.category.toLowerCase().contains(qLower) ||
          e.location.toLowerCase().contains(qLower)).toList();
    }
    return localList;
  }

  /// Admin: Delete event
  Future<void> deleteEvent(String eventId) async {
    _localStore.deleteEvent(eventId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(eventId).delete().timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }
  }

  /// Mark event as completed
  Future<void> completeEvent(String eventId) async {
    final ev = _localStore.getEventById(eventId);
    if (ev != null) {
      _localStore.updateEvent(ev.copyWith(status: AppConstants.eventStatusCompleted));
    }
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _eventsCol != null) {
      try {
        await _eventsCol!.doc(eventId).update({
          'status': AppConstants.eventStatusCompleted,
        }).timeout(const Duration(milliseconds: 3000));
      } catch (_) {}
    }
  }
}
