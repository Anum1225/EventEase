import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';
import '../repositories/notification_repository.dart';
import '../services/storage_service.dart';

/// State management for Event discovery, filtering, organizer CRUD, and admin approval
class EventProvider with ChangeNotifier {
  final EventRepository _eventRepository;
  final StorageService _storageService;
  final NotificationRepository _notificationRepository;

  List<EventModel> _discoverableEvents = [];
  List<EventModel> _organizerEvents = [];
  List<EventModel> _pendingApprovalEvents = [];
  List<EventModel> _allAdminEvents = [];

  bool _isLoading = false;
  String? _errorMessage;
  Timer? _autoExpiryTimer;

  // Filter state
  String _selectedCategory = 'all';
  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _selectedLocation;
  bool _onlyAvailable = false;

  EventProvider({
    EventRepository? eventRepository,
    StorageService? storageService,
    NotificationRepository? notificationRepository,
    bool enableAutoExpiryTimer = true,
  })  : _eventRepository = eventRepository ?? EventRepository(),
        _storageService = storageService ?? StorageService(),
        _notificationRepository = notificationRepository ?? NotificationRepository() {
    // Instantaneous local cache initialization for 0ms visual render
    _discoverableEvents = _eventRepository.getDiscoverableEventsSync();
    _pendingApprovalEvents = _eventRepository.getPendingApprovalEventsSync();
    _allAdminEvents = _eventRepository.getAllEventsSync();
    loadDiscoverableEvents(silent: true);
    checkAndBroadcastExpiredEvents();
    if (enableAutoExpiryTimer &&
        !WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test')) {
      _autoExpiryTimer =
          Timer.periodic(const Duration(minutes: 1), (_) => checkAndBroadcastExpiredEvents());
    }
  }

  void stopAutoExpiryTimer() {
    _autoExpiryTimer?.cancel();
    _autoExpiryTimer = null;
  }

  @override
  void dispose() {
    _autoExpiryTimer?.cancel();
    super.dispose();
  }

  /// Automatically detect ended events, mark them completed, and send notifications
  Future<void> checkAndBroadcastExpiredEvents() async {
    try {
      final newlyCompleted = await _eventRepository.checkAndCompleteExpiredEvents();
      for (final event in newlyCompleted) {
        // Broadcast completion notice and feedback request to all registered attendees
        await _notificationRepository.broadcastToEventParticipants(
          eventId: event.id,
          title: 'Event Completed! 🎉',
          message: '"${event.title}" has concluded. Share your experience by leaving a review and rating!',
          type: 'event_completed',
        );

        // Also notify organizer
        if (event.organizerId.isNotEmpty) {
          await _notificationRepository.sendNotification(
            userId: event.organizerId,
            title: 'Event Concluded 🏁',
            message: 'Your event "${event.title}" has completed. Check attendee feedback and attendance stats.',
            type: 'event_completed',
            eventId: event.id,
          );
        }
      }
      if (newlyCompleted.isNotEmpty) {
        notifyListeners();
      }
    } catch (_) {}
  }

  List<EventModel> get discoverableEvents => _discoverableEvents;
  List<EventModel> get organizerEvents => _organizerEvents;
  List<EventModel> get pendingApprovalEvents => _pendingApprovalEvents;
  List<EventModel> get allAdminEvents => _allAdminEvents;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedLocation => _selectedLocation;
  bool get onlyAvailable => _onlyAvailable;
  bool get hasActiveFilters =>
      _selectedCategory != 'all' ||
      _searchQuery.isNotEmpty ||
      _selectedDate != null ||
      _selectedLocation != null ||
      _onlyAvailable;

  /// Load Discoverable events matching active filters with fast response
  Future<void> loadDiscoverableEvents({bool silent = false}) async {
    if (!silent && _discoverableEvents.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await _eventRepository.getDiscoverableEvents(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        searchQuery: _searchQuery,
        date: _selectedDate,
        location: _selectedLocation,
        onlyAvailable: _onlyAvailable,
      );
      _discoverableEvents = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_discoverableEvents.isEmpty) {
        _errorMessage = 'Failed to load events: ${e.toString()}';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadDiscoverableEvents();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadDiscoverableEvents();
  }

  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    loadDiscoverableEvents();
  }

  void setLocationFilter(String? location) {
    _selectedLocation = location;
    loadDiscoverableEvents();
  }

  void toggleOnlyAvailable(bool val) {
    _onlyAvailable = val;
    loadDiscoverableEvents();
  }

  void clearFilters() {
    _selectedCategory = 'all';
    _searchQuery = '';
    _selectedDate = null;
    _selectedLocation = null;
    _onlyAvailable = false;
    loadDiscoverableEvents();
  }

  /// Organizer: Load events owned by this organizer
  Future<void> loadOrganizerEvents(String organizerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _organizerEvents = await _eventRepository.getOrganizerEvents(organizerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load organizer events: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Organizer: Create a new event with optional banner image
  Future<bool> createEvent({
    required EventModel event,
    File? bannerImageFile,
    Uint8List? bannerImageBytes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl = event.imageUrl;
      if (bannerImageBytes != null || bannerImageFile != null) {
        imageUrl = await _storageService.uploadEventBanner(
          organizerId: event.organizerId,
          imageFile: bannerImageFile,
          imageBytes: bannerImageBytes,
        );
      }

      final newEvent = event.copyWith(imageUrl: imageUrl);
      await _eventRepository.createEvent(newEvent);
      await loadOrganizerEvents(event.organizerId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create event: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Organizer: Update an existing event
  Future<bool> updateEvent({
    required EventModel event,
    File? newBannerImageFile,
    Uint8List? newBannerImageBytes,
    bool isMaterialChange = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl = event.imageUrl;
      if (newBannerImageBytes != null || newBannerImageFile != null) {
        imageUrl = await _storageService.uploadEventBanner(
          organizerId: event.organizerId,
          imageFile: newBannerImageFile,
          imageBytes: newBannerImageBytes,
        );
      }

      final updatedEvent = event.copyWith(
        imageUrl: imageUrl,
        // Material changes (e.g. date/location) trigger re-approval
        status: isMaterialChange ? 'pending_approval' : event.status,
      );

      await _eventRepository.updateEvent(updatedEvent);

      // Notify registered attendees about event change
      if (isMaterialChange) {
        await _notificationRepository.broadcastToEventParticipants(
          eventId: event.id,
          title: 'Event Details Updated',
          message: 'The date/location for "${event.title}" has been updated by the organizer.',
          type: 'event_update',
        );
      }

      await loadOrganizerEvents(event.organizerId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update event: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Organizer/Admin: Cancel an event
  Future<bool> cancelEvent({
    required String eventId,
    required String reason,
    required String eventTitle,
    String? organizerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventRepository.cancelEvent(eventId, reason);

      // Broadcast cancellation notice to all registered attendees
      await _notificationRepository.broadcastToEventParticipants(
        eventId: eventId,
        title: 'Event Cancelled',
        message: 'The event "$eventTitle" has been cancelled. Reason: $reason',
        type: 'event_cancelled',
      );

      if (organizerId != null) {
        await loadOrganizerEvents(organizerId);
      }
      await loadDiscoverableEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel event: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Organizer/Admin: Mark event as completed
  Future<bool> completeEvent({
    required String eventId,
    required String eventTitle,
    String? organizerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventRepository.completeEvent(eventId);

      // Broadcast completion notice and feedback request to all registered attendees
      await _notificationRepository.broadcastToEventParticipants(
        eventId: eventId,
        title: 'Event Completed! 🎉',
        message: '"$eventTitle" has concluded. Share your experience by leaving a review and rating!',
        type: 'event_completed',
      );

      if (organizerId != null) {
        await loadOrganizerEvents(organizerId);
      }
      await loadDiscoverableEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete event: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Admin: Load pending approvals queue
  Future<void> loadPendingApprovals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingApprovalEvents = await _eventRepository.getPendingApprovalEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load approval queue: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin: Approve event
  Future<bool> approveEvent(String eventId, String organizerId, String eventTitle) async {
    try {
      await _eventRepository.approveEvent(eventId);
      await _notificationRepository.sendNotification(
        userId: organizerId,
        title: 'Event Approved!',
        message: 'Your event "$eventTitle" has been approved and is now public.',
        type: 'announcement',
        eventId: eventId,
      );
      await loadPendingApprovals();
      await loadDiscoverableEvents(silent: true);
      await loadAllAdminEvents();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve event: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Admin: Reject event
  Future<bool> rejectEvent(String eventId, String reason, String organizerId, String eventTitle) async {
    try {
      await _eventRepository.rejectEvent(eventId, reason);
      await _notificationRepository.sendNotification(
        userId: organizerId,
        title: 'Event Submission Update',
        message: 'Your event "$eventTitle" was not approved. Reason: $reason',
        type: 'announcement',
        eventId: eventId,
      );
      await loadPendingApprovals();
      await loadDiscoverableEvents(silent: true);
      await loadAllAdminEvents();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject event: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Admin: Load all events system-wide
  Future<void> loadAllAdminEvents({String? status, String? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allAdminEvents = await _eventRepository.getAllEvents(status: status, query: query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load system events: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin: Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _eventRepository.deleteEvent(eventId);
      await loadAllAdminEvents();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete event: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
