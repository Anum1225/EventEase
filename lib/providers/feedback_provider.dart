import 'dart:async';
import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/notification_repository.dart';

/// State management for post-event feedback, reviews, and real-time streaming calculations
class FeedbackProvider with ChangeNotifier {
  final FeedbackRepository _feedbackRepository;
  final NotificationRepository _notificationRepository;
  StreamSubscription<List<FeedbackModel>>? _feedbackSubscription;
  String? _currentStreamEventId;

  final Map<String, List<FeedbackModel>> _eventFeedbackCache = {};
  final Map<String, double> _eventAverageRatings = {};
  final Map<String, bool> _userSubmittedCache = {};
  bool _isLoading = false;
  String? _errorMessage;

  FeedbackProvider({
    FeedbackRepository? feedbackRepository,
    NotificationRepository? notificationRepository,
  })  : _feedbackRepository = feedbackRepository ?? FeedbackRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<FeedbackModel> getFeedbackForEvent(String eventId) =>
      _eventFeedbackCache[eventId] ?? [];

  double getAverageRating(String eventId) =>
      _eventAverageRatings[eventId] ?? 0.0;

  bool hasSubmittedForEvent(String eventId) =>
      _userSubmittedCache[eventId] ?? false;

  /// Real-time stream subscription for live comments and reviews
  void subscribeToEventFeedback(String eventId, [List<String>? organizerEventIds]) {
    if (_currentStreamEventId == eventId && _feedbackSubscription != null) {
      return;
    }
    _currentStreamEventId = eventId;
    _feedbackSubscription?.cancel();

    // 1. Instantly seed cache from local store so UI is immediate with zero stuck loading
    final initialList = _feedbackRepository.getEventFeedbackLocal(eventId, organizerEventIds);
    _eventFeedbackCache[eventId] = initialList;
    if (initialList.isNotEmpty) {
      final sum = initialList.fold<int>(0, (prev, f) => prev + f.rating);
      _eventAverageRatings[eventId] = sum / initialList.length;
    } else {
      _eventAverageRatings[eventId] = 0.0;
    }
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();

    _feedbackSubscription = _feedbackRepository.streamEventFeedback(eventId, organizerEventIds).listen((list) {
      _eventFeedbackCache[eventId] = list;
      if (list.isNotEmpty) {
        final sum = list.fold<int>(0, (prev, f) => prev + f.rating);
        _eventAverageRatings[eventId] = sum / list.length;
      } else {
        _eventAverageRatings[eventId] = 0.0;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadEventFeedback(String eventId, [List<String>? organizerEventIds]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _feedbackRepository.getEventFeedback(eventId, organizerEventIds);
      _eventFeedbackCache[eventId] = list;

      if (list.isNotEmpty) {
        final sum = list.fold<int>(0, (prev, f) => prev + f.rating);
        _eventAverageRatings[eventId] = sum / list.length;
      } else {
        _eventAverageRatings[eventId] = 0.0;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load feedback: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkUserFeedbackStatus(String userId, String eventId) async {
    try {
      final submitted = await _feedbackRepository.hasUserSubmittedFeedback(
        userId: userId,
        eventId: eventId,
      );
      _userSubmittedCache[eventId] = submitted;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submitFeedback({
    required String eventId,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
    String? organizerId,
    String? eventTitle,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _feedbackRepository.submitFeedback(
        eventId: eventId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
      );

      // Send immediate alert notification to the event's organizer
      if (organizerId != null && organizerId.isNotEmpty) {
        final starStr = List.generate(rating, (_) => '★').join();
        final commentSnippet = (comment != null && comment.trim().isNotEmpty)
            ? ': "$comment"'
            : '';
        await _notificationRepository.sendNotification(
          userId: organizerId,
          title: 'New Review on ${eventTitle ?? "Event"}',
          message: '$userName gave $rating stars ($starStr)$commentSnippet',
          type: 'feedback',
          eventId: eventId,
        );
      }

      _userSubmittedCache[eventId] = true;
      await loadEventFeedback(eventId);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }
}
