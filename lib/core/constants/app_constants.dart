/// Core constants for EventEase application
class AppConstants {
  AppConstants._();

  static const String appName = 'EventEase';
  static const String appTagline = 'Seamless Events, Effortless Management';

  // --- Roles ---
  static const String roleAttendee = 'attendee';
  static const String roleOrganizerPending = 'organizer_pending';
  static const String roleOrganizer = 'organizer';
  static const String roleAdmin = 'admin';

  // --- User Account Statuses ---
  static const String userStatusActive = 'active';
  static const String userStatusDeactivated = 'deactivated';

  // --- Event Statuses ---
  static const String eventStatusPendingApproval = 'pending_approval';
  static const String eventStatusApproved = 'approved';
  static const String eventStatusRejected = 'rejected';
  static const String eventStatusCancelled = 'cancelled';
  static const String eventStatusCompleted = 'completed';

  // --- Registration Statuses ---
  static const String registrationStatusRegistered = 'registered';
  static const String registrationStatusCancelled = 'cancelled';

  // --- Notification Types ---
  static const String notifRegistrationConfirm = 'registration_confirm';
  static const String notifReminder = 'reminder';
  static const String notifEventUpdate = 'event_update';
  static const String notifEventCancelled = 'event_cancelled';
  static const String notifAnnouncement = 'announcement';
  static const String notifFeedbackRequest = 'feedback_request';

  // --- Event Categories ---
  static const List<String> categories = [
    'technology',
    'education',
    'sports',
    'music',
    'business',
    'workshop',
    'conference',
    'community',
  ];

  // --- Firestore Collection Names ---
  static const String colUsers = 'users';
  static const String colEvents = 'events';
  static const String colRegistrations = 'registrations';
  static const String colAttendance = 'attendance';
  static const String colFavorites = 'favorites';
  static const String colNotifications = 'notifications';
  static const String colFeedback = 'feedback';
  static const String colGallery = 'gallery';
  static const String colContactMessages = 'contact_messages';
}
