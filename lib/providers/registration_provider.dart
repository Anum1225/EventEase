import 'package:flutter/material.dart';
import '../models/registration_model.dart';
import '../repositories/registration_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/notification_repository.dart';

/// State management for Attendee registrations, ticket passes, and favorites
class RegistrationProvider with ChangeNotifier {
  final RegistrationRepository _registrationRepository;
  final FavoriteRepository _favoriteRepository;
  final NotificationRepository _notificationRepository;

  List<RegistrationModel> _registrations = [];
  Set<String> _favoriteEventIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  RegistrationProvider({
    RegistrationRepository? registrationRepository,
    FavoriteRepository? favoriteRepository,
    NotificationRepository? notificationRepository,
  })  : _registrationRepository = registrationRepository ?? RegistrationRepository(),
        _favoriteRepository = favoriteRepository ?? FavoriteRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository();

  List<RegistrationModel> get registrations => _registrations;
  Set<String> get favoriteEventIds => _favoriteEventIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RegistrationModel> get upcomingRegistrations {
    final now = DateTime.now();
    return _registrations
        .where((r) =>
            r.isRegistered &&
            (r.eventDate == null || r.eventDate!.isAfter(now.subtract(const Duration(hours: 12)))))
        .toList();
  }

  List<RegistrationModel> get completedRegistrations {
    final now = DateTime.now();
    return _registrations
        .where((r) =>
            r.isRegistered &&
            r.eventDate != null &&
            r.eventDate!.isBefore(now.subtract(const Duration(hours: 12))))
        .toList();
  }

  List<RegistrationModel> get cancelledRegistrations {
    return _registrations.where((r) => r.isCancelled).toList();
  }

  bool isRegisteredForEvent(String eventId) {
    return _registrations.any((r) => r.eventId == eventId && r.isRegistered);
  }

  RegistrationModel? getRegistrationForEvent(String eventId) {
    try {
      return _registrations.firstWhere((r) => r.eventId == eventId && r.isRegistered);
    } catch (_) {
      return null;
    }
  }

  bool isEventFavorited(String eventId) => _favoriteEventIds.contains(eventId);

  Future<void> loadUserData(String userId, [String? userEmail]) async {
    if (_registrations.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final regs = await _registrationRepository.getUserRegistrations(userId, userEmail);
      final favs = await _favoriteRepository.getUserFavorites(userId);
      _registrations = regs;
      _favoriteEventIds = favs.map((f) => f.eventId).toSet();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load attendee data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atomic 7-Step Registration Action
  Future<RegistrationModel?> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    required String eventTitle,
  }) async {
    // Prevent duplicate registration at provider level
    if (isRegisteredForEvent(eventId)) {
      _errorMessage = 'You are already registered for this event.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reg = await _registrationRepository.registerForEvent(
        eventId: eventId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

      _registrations.insert(0, reg);

      // Trigger Confirmation Notification
      await _notificationRepository.sendNotification(
        userId: userId,
        title: 'Registration Confirmed! 🎉',
        message: 'You have successfully secured a spot for "$eventTitle". Your QR ticket pass is ready in My Events.',
        type: 'registration_confirm',
        eventId: eventId,
      );

      _isLoading = false;
      notifyListeners();
      return reg;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel registration
  Future<bool> cancelRegistration({
    required String registrationId,
    required String eventId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _registrationRepository.cancelRegistration(
        registrationId: registrationId,
        eventId: eventId,
      );
      await loadUserData(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel registration: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle Favorite
  Future<void> toggleFavorite({
    required String userId,
    required String eventId,
  }) async {
    final currentlyFav = _favoriteEventIds.contains(eventId);
    if (currentlyFav) {
      _favoriteEventIds.remove(eventId);
    } else {
      _favoriteEventIds.add(eventId);
    }
    notifyListeners();

    try {
      await _favoriteRepository.toggleFavorite(userId: userId, eventId: eventId);
    } catch (e) {
      // Revert on error
      if (currentlyFav) {
        _favoriteEventIds.add(eventId);
      } else {
        _favoriteEventIds.remove(eventId);
      }
      notifyListeners();
    }
  }
}
