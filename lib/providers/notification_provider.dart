import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// State management for in-app notifications and real-time streaming badge counters
class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentSubscribedUserId;

  NotificationProvider({NotificationRepository? notificationRepository})
      : _notificationRepository = notificationRepository ?? NotificationRepository();

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Subscribe to real-time stream of notifications for user
  void subscribeToUserNotifications(String userId) {
    if (_currentSubscribedUserId == userId && _notificationSubscription != null) {
      return;
    }
    _currentSubscribedUserId = userId;
    _notificationSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _notificationSubscription = _notificationRepository
        .streamUserNotifications(userId)
        .listen((notifs) {
      _notifications = notifs;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Unsubscribe from notification stream (e.g. on logout)
  void unsubscribe() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentSubscribedUserId = null;
    _notifications = [];
    notifyListeners();
  }

  Future<void> loadUserNotifications(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationRepository.getUserNotifications(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load notifications: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      try {
        await _notificationRepository.markAsRead(notificationId);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead(String userId) async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _notificationRepository.markAllAsRead(userId);
    } catch (_) {}
  }

  /// Organizer: Broadcast announcement
  Future<bool> sendAnnouncement({
    required String eventId,
    required String title,
    required String message,
  }) async {
    try {
      await _notificationRepository.broadcastToEventParticipants(
        eventId: eventId,
        title: title,
        message: message,
        type: 'announcement',
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send announcement: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
