import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// State management for in-app notifications and unread badge counters
class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  NotificationProvider({NotificationRepository? notificationRepository})
      : _notificationRepository = notificationRepository ?? NotificationRepository();

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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
}
