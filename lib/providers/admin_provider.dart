import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/feedback_model.dart';
import '../models/attendance_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/notification_repository.dart';

class AdminStatistics {
  final int totalUsers;
  final int totalOrganizers;
  final int totalAttendees;
  final int totalEvents;
  final int totalApprovedEvents;
  final int totalPendingApprovals;
  final int totalRegistrations;
  final int totalCheckIns;
  final double averageSystemRating;
  final List<EventModel> popularEvents;

  const AdminStatistics({
    required this.totalUsers,
    required this.totalOrganizers,
    required this.totalAttendees,
    required this.totalEvents,
    required this.totalApprovedEvents,
    required this.totalPendingApprovals,
    required this.totalRegistrations,
    required this.totalCheckIns,
    required this.averageSystemRating,
    required this.popularEvents,
  });
}

/// State management for Administrator Dashboard, User Management, and Statistics
class AdminProvider with ChangeNotifier {
  final UserRepository _userRepository;
  final EventRepository _eventRepository;
  final FeedbackRepository _feedbackRepository;
  final AttendanceRepository _attendanceRepository;
  final NotificationRepository _notificationRepository;

  List<UserModel> _users = [];
  List<UserModel> _pendingOrganizers = [];
  AdminStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;

  String? _currentRoleFilter;
  String? _currentSearchQuery;

  AdminProvider({
    UserRepository? userRepository,
    EventRepository? eventRepository,
    FeedbackRepository? feedbackRepository,
    AttendanceRepository? attendanceRepository,
    NotificationRepository? notificationRepository,
  })  : _userRepository = userRepository ?? UserRepository(),
        _eventRepository = eventRepository ?? EventRepository(),
        _feedbackRepository = feedbackRepository ?? FeedbackRepository(),
        _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository();

  List<UserModel> get users => _users;
  List<UserModel> get pendingOrganizers => _pendingOrganizers;
  AdminStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentRoleFilter => _currentRoleFilter;
  String? get currentSearchQuery => _currentSearchQuery;

  /// Load user roster with optional filter retention
  Future<void> loadUsers({String? role, String? query, bool keepExistingFilters = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (keepExistingFilters) {
      role = role ?? _currentRoleFilter;
      query = query ?? _currentSearchQuery;
    } else {
      _currentRoleFilter = role;
      _currentSearchQuery = query;
    }

    try {
      _users = await _userRepository.getAllUsers(role: role, query: query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load users: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pending organizer applicants
  Future<void> loadPendingOrganizers() async {
    try {
      _pendingOrganizers = await _userRepository.getPendingOrganizers();
      notifyListeners();
    } catch (_) {}
  }

  /// Approve organizer applicant
  Future<bool> approveOrganizer(String userId, String email, String name) async {
    try {
      await _userRepository.approveOrganizer(userId);
      await _notificationRepository.sendNotification(
        userId: userId,
        title: 'Organizer Application Approved! 🚀',
        message: 'Congratulations $name! You can now create and host events on EventEase.',
        type: AppConstants.notifAnnouncement,
      );
      await loadPendingOrganizers();
      await loadUsers(keepExistingFilters: true);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve organizer: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Reject organizer applicant
  Future<bool> rejectOrganizer(String userId, String reason, String name) async {
    try {
      await _userRepository.rejectOrganizer(userId, reason);
      await _notificationRepository.sendNotification(
        userId: userId,
        title: 'Organizer Application Status',
        message: 'Your organizer request was not approved. Reason: $reason',
        type: AppConstants.notifAnnouncement,
      );
      await loadPendingOrganizers();
      await loadUsers(keepExistingFilters: true);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject organizer: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle User Status (Deactivate / Activate)
  Future<bool> toggleUserStatus(String userId, bool isDeactivating) async {
    try {
      await _userRepository.toggleUserStatus(userId, isDeactivating);
      await loadUsers(keepExistingFilters: true);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update user status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Compute Real-Time System Analytics & KPIs
  Future<void> computeSystemStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usersFuture = _userRepository.getAllUsers();
      final eventsFuture = _eventRepository.getAllEvents();
      final feedbackFuture = _feedbackRepository.getAllFeedback();
      final attendanceFuture = _attendanceRepository.getAllAttendance();

      final results = await Future.wait([
        usersFuture,
        eventsFuture,
        feedbackFuture,
        attendanceFuture,
      ]);

      final allUsers = results[0] as List<UserModel>;
      final allEvents = results[1] as List<EventModel>;
      final allFeedback = results[2] as List<FeedbackModel>;
      final allAttendance = results[3] as List<AttendanceModel>;

      final totalOrganizers = allUsers.where((u) => u.role == AppConstants.roleOrganizer).length;
      final totalAttendees = allUsers.where((u) => u.role == AppConstants.roleAttendee).length;
      final approvedEvents = allEvents.where((e) => e.isApproved).length;
      final pendingEvents = allEvents.where((e) => e.isPending).length;

      final totalRegistrations = allEvents.fold<int>(0, (sum, e) => sum + e.registeredCount);
      final totalCheckIns = allAttendance.length;

      double avgRating = 0.0;
      if (allFeedback.isNotEmpty) {
        final sum = allFeedback.fold<int>(0, (prev, f) => prev + f.rating);
        avgRating = sum / allFeedback.length;
      }

      // Sort popular events by registered count
      final sortedEvents = List<EventModel>.from(allEvents)
        ..sort((a, b) => b.registeredCount.compareTo(a.registeredCount));
      final popular = sortedEvents.take(5).toList();

      _statistics = AdminStatistics(
        totalUsers: allUsers.length,
        totalOrganizers: totalOrganizers,
        totalAttendees: totalAttendees,
        totalEvents: allEvents.length,
        totalApprovedEvents: approvedEvents,
        totalPendingApprovals: pendingEvents,
        totalRegistrations: totalRegistrations,
        totalCheckIns: totalCheckIns,
        averageSystemRating: avgRating,
        popularEvents: popular,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to compute statistics: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
