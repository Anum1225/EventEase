import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';

/// State management for post-event feedback, reviews, and average rating calculations
class FeedbackProvider with ChangeNotifier {
  final FeedbackRepository _feedbackRepository;

  final Map<String, List<FeedbackModel>> _eventFeedbackCache = {};
  final Map<String, double> _eventAverageRatings = {};
  final Map<String, bool> _userSubmittedCache = {};
  bool _isLoading = false;
  String? _errorMessage;

  FeedbackProvider({FeedbackRepository? feedbackRepository})
      : _feedbackRepository = feedbackRepository ?? FeedbackRepository();

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

  Future<void> loadEventFeedback(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _feedbackRepository.getEventFeedback(eventId);
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
}
