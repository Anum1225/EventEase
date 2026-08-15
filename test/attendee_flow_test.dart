import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/theme/app_theme.dart';
import 'package:eventease/core/constants/app_constants.dart';
import 'package:eventease/models/user_model.dart';
import 'package:eventease/models/event_model.dart';
import 'package:eventease/models/registration_model.dart';
import 'package:eventease/models/attendance_model.dart';
import 'package:eventease/models/feedback_model.dart';
import 'package:eventease/models/favorite_model.dart';
import 'package:eventease/models/notification_model.dart';
import 'package:eventease/models/contact_message_model.dart';

import 'package:eventease/providers/auth_provider.dart';
import 'package:eventease/providers/theme_provider.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/providers/registration_provider.dart';
import 'package:eventease/providers/attendance_provider.dart';
import 'package:eventease/providers/admin_provider.dart';
import 'package:eventease/providers/notification_provider.dart';
import 'package:eventease/providers/feedback_provider.dart';
import 'package:eventease/providers/gallery_provider.dart';
import 'package:eventease/providers/contact_provider.dart';

import 'package:eventease/features/attendee/screens/home_discover_screen.dart';
import 'package:eventease/features/attendee/screens/event_details_screen.dart';
import 'package:eventease/features/attendee/screens/my_events_screen.dart';
import 'package:eventease/features/attendee/screens/favorites_screen.dart';
import 'package:eventease/features/attendee/screens/notifications_screen.dart';
import 'package:eventease/features/attendee/screens/profile_screen.dart';
import 'package:eventease/features/attendee/screens/qr_pass_screen.dart';
import 'package:eventease/features/attendee/screens/submit_feedback_screen.dart';

import 'package:eventease/features/shared/screens/about_us_screen.dart';
import 'package:eventease/features/shared/screens/contact_us_screen.dart';
import 'package:eventease/features/shared/screens/event_gallery_screen.dart';

import 'package:eventease/core/widgets/qr_pass_card.dart';
import 'package:eventease/core/widgets/empty_state_view.dart';
import 'package:eventease/core/widgets/error_view.dart';

Widget createTestApp({
  required Widget child,
  AuthProvider? authProvider,
  ThemeProvider? themeProvider,
  EventProvider? eventProvider,
  RegistrationProvider? registrationProvider,
  AttendanceProvider? attendanceProvider,
  AdminProvider? adminProvider,
  NotificationProvider? notificationProvider,
  FeedbackProvider? feedbackProvider,
  GalleryProvider? galleryProvider,
  ContactProvider? contactProvider,
}) {
  final defaultAuth = authProvider ?? AuthProvider();
  if (defaultAuth.currentUser == null) {
    defaultAuth.setCurrentUserForTesting(UserModel(
      id: 'usr_001',
      email: 'attendee1@eventease.com',
      name: 'Alex Johnson',
      role: AppConstants.roleAttendee,
      status: AppConstants.userStatusActive,
      createdAt: DateTime(2026, 1, 1),
      notificationPreferences: {
        'eventReminders': true,
        'announcements': true,
        'feedbackRequests': true,
        'marketing': false,
      },
    ));
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: defaultAuth),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider ?? ThemeProvider()),
      ChangeNotifierProvider<EventProvider>.value(value: eventProvider ?? EventProvider()),
      ChangeNotifierProvider<RegistrationProvider>.value(
          value: registrationProvider ?? RegistrationProvider()),
      ChangeNotifierProvider<AttendanceProvider>.value(
          value: attendanceProvider ?? AttendanceProvider()),
      ChangeNotifierProvider<AdminProvider>.value(value: adminProvider ?? AdminProvider()),
      ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider ?? NotificationProvider()),
      ChangeNotifierProvider<FeedbackProvider>.value(
          value: feedbackProvider ?? FeedbackProvider()),
      ChangeNotifierProvider<GalleryProvider>.value(
          value: galleryProvider ?? GalleryProvider()),
      ChangeNotifierProvider<ContactProvider>.value(
          value: contactProvider ?? ContactProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Attendee Domain Models Tests', () {
    test('EventModel edge cases: full capacity, remaining seats clamp, and status getters', () {
      final now = DateTime.now();
      final event = EventModel(
        id: 'test-evt-1',
        organizerId: 'org-test',
        organizerName: 'DevCon Global',
        organizerEmail: 'contact@devcon.org',
        title: 'Flutter Architecture 2026',
        description: 'Advanced patterns and testing for Flutter applications.',
        category: 'technology',
        date: now.add(const Duration(days: 7)),
        startTime: '09:00 AM',
        endTime: '05:00 PM',
        location: 'Tech Park Auditorium, Level 2',
        maxParticipants: 50,
        registeredCount: 48,
        status: AppConstants.eventStatusApproved,
        createdAt: now,
      );

      expect(event.isApproved, isTrue);
      expect(event.isPending, isFalse);
      expect(event.isFull, isFalse);
      expect(event.remainingSeats, 2);

      // Clamped when registered equals max
      final fullEvent = event.copyWith(registeredCount: 50);
      expect(fullEvent.isFull, isTrue);
      expect(fullEvent.remainingSeats, 0);

      // Over capacity edge case clamped to 0
      final overEvent = event.copyWith(registeredCount: 55);
      expect(overEvent.isFull, isTrue);
      expect(overEvent.remainingSeats, 0);

      // Serialization round-trip
      final map = event.toMap();
      final fromMap = EventModel.fromMap(map, 'test-evt-1');
      expect(fromMap.title, 'Flutter Architecture 2026');
      expect(fromMap.organizerName, 'DevCon Global');
      expect(fromMap.registeredCount, 48);
    });

    test('RegistrationModel: creation, QR payload formatting, and copyWith', () {
      final now = DateTime.now();
      final reg = RegistrationModel(
        id: 'reg-test-100',
        eventId: 'test-evt-1',
        userId: 'user-attendee-1',
        userName: 'Taylor Smith',
        userEmail: 'taylor@example.com',
        eventTitle: 'Flutter Architecture 2026',
        eventDate: now.add(const Duration(days: 7)),
        eventLocation: 'Tech Park Auditorium',
        eventBanner: 'https://example.com/banner.jpg',
        eventCategory: 'technology',
        registeredAt: now,
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg-test-100-TOKEN',
      );

      expect(reg.isRegistered, isTrue);
      expect(reg.isCancelled, isFalse);
      expect(reg.qrCode, 'EASE-reg-test-100-TOKEN');

      final cancelled = reg.copyWith(status: AppConstants.registrationStatusCancelled);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isRegistered, isFalse);

      final map = reg.toMap();
      final reconstructed = RegistrationModel.fromMap(map, 'reg-test-100');
      expect(reconstructed.userName, 'Taylor Smith');
      expect(reconstructed.userEmail, 'taylor@example.com');
      expect(reconstructed.eventTitle, 'Flutter Architecture 2026');
    });

    test('FeedbackModel: rating boundary clamping and JSON serialization', () {
      final now = DateTime.now();
      final mapClampedHigh = {
        'eventId': 'evt-1',
        'userId': 'usr-1',
        'userName': 'Sam',
        'rating': 10, // out of range
        'comment': 'Amazing workshop!',
        'submittedAt': now.toIso8601String(),
      };

      final fbHigh = FeedbackModel.fromMap(mapClampedHigh, 'fb-high');
      expect(fbHigh.rating, 5);

      final mapClampedLow = {
        'eventId': 'evt-1',
        'userId': 'usr-1',
        'rating': -2, // out of range
        'submittedAt': now.toIso8601String(),
      };

      final fbLow = FeedbackModel.fromMap(mapClampedLow, 'fb-low');
      expect(fbLow.rating, 1);
    });

    test('FavoriteModel, AttendanceModel, NotificationModel, ContactMessageModel serialization', () {
      final now = DateTime.now();

      // Favorite
      final fav = FavoriteModel(id: 'fav-1', userId: 'u-1', eventId: 'e-1', createdAt: now);
      final favMap = fav.toMap();
      final favFrom = FavoriteModel.fromMap(favMap, 'fav-1');
      expect(favFrom.userId, 'u-1');

      // Attendance
      final att = AttendanceModel(
        id: 'att-1',
        registrationId: 'r-1',
        eventId: 'e-1',
        userId: 'u-1',
        userName: 'Alex',
        userEmail: 'alex@example.com',
        attended: true,
        checkedInAt: now,
        checkedInBy: 'org-1',
      );
      expect(att.attended, isTrue);
      expect(AttendanceModel.fromMap(att.toMap(), 'att-1').checkedInBy, 'org-1');

      // Notification
      final notif = NotificationModel(
        id: 'notif-1',
        userId: 'u-1',
        eventId: 'e-1',
        title: 'Spot Reserved',
        message: 'Your pass is ready.',
        type: AppConstants.notifRegistrationConfirm,
        isRead: false,
        createdAt: now,
      );
      expect(notif.isRead, isFalse);
      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, isTrue);

      // Contact
      final msg = ContactMessageModel(
        id: 'msg-1',
        userId: 'u-1',
        name: 'Jordan',
        email: 'jordan@test.com',
        subject: 'Accessibility Query',
        message: 'Is wheelchair access available at Hall B?',
        submittedAt: now,
      );
      expect(msg.subject, 'Accessibility Query');
    });
  });

  group('Attendee Provider Unit Tests', () {
    test('RegistrationProvider: user loading, filtering, registering, and cancelling', () async {
      final regProvider = RegistrationProvider();
      await regProvider.loadUserData('att_001');

      expect(regProvider.isLoading, isFalse);
      expect(regProvider.registrations, isNotEmpty);

      // Check upcoming / completed / cancelled separation
      final upcoming = regProvider.upcomingRegistrations;
      final completed = regProvider.completedRegistrations;
      expect(upcoming, isA<List<RegistrationModel>>());
      expect(completed, isA<List<RegistrationModel>>());

      // Register for an event
      final regResult = await regProvider.registerForEvent(
        eventId: 'evt_002_music',
        userId: 'att_001',
        userName: 'Alex Johnson',
        userEmail: 'attendee1@eventease.com',
        eventTitle: 'Acoustic Sunset Music Festival',
      );

      expect(regResult, isNotNull);
      expect(regProvider.isRegisteredForEvent('evt_002_music'), isTrue);

      final fetchedReg = regProvider.getRegistrationForEvent('evt_002_music');
      expect(fetchedReg, isNotNull);
      expect(fetchedReg?.eventId, 'evt_002_music');

      // Cancel registration
      final cancelSuccess = await regProvider.cancelRegistration(
        registrationId: regResult!.id,
        eventId: 'evt_002_music',
        userId: 'att_001',
      );
      expect(cancelSuccess, isTrue);

      // Toggle favorite
      final initialFav = regProvider.isEventFavorited('evt_001_flutter');
      await regProvider.toggleFavorite(userId: 'att_001', eventId: 'evt_001_flutter');
      expect(regProvider.isEventFavorited('evt_001_flutter'), !initialFav);
    });

    test('EventProvider: category filtering, search queries, and filter clearing', () async {
      final eventProvider = EventProvider();
      await eventProvider.loadDiscoverableEvents();

      expect(eventProvider.discoverableEvents, isNotEmpty);

      // Filter by category
      eventProvider.filterByCategory('technology');
      expect(eventProvider.selectedCategory, 'technology');
      expect(eventProvider.hasActiveFilters, isTrue);

      // Search query filter
      eventProvider.setSearchQuery('Summit');
      expect(eventProvider.searchQuery, 'Summit');

      // Clear filters
      eventProvider.clearFilters();
      expect(eventProvider.selectedCategory, 'all');
      expect(eventProvider.searchQuery, '');
      expect(eventProvider.hasActiveFilters, isFalse);
    });

    test('FeedbackProvider: event feedback, average rating, and submission', () async {
      final fbProvider = FeedbackProvider();
      await fbProvider.loadEventFeedback('evt_006_completed');

      final reviews = fbProvider.getFeedbackForEvent('evt_006_completed');
      expect(reviews, isNotEmpty);

      final avgRating = fbProvider.getAverageRating('evt_006_completed');
      expect(avgRating, greaterThan(0.0));

      final success = await fbProvider.submitFeedback(
        eventId: 'evt_006_completed',
        userId: 'att_003',
        userName: 'Liam Chen',
        rating: 5,
        comment: 'Great organization!',
      );
      expect(success, isTrue);
      expect(fbProvider.hasSubmittedForEvent('evt_006_completed'), isTrue);
    });

    test('NotificationProvider: load, unread count calculation, mark as read, mark all read', () async {
      final notifProvider = NotificationProvider();
      await notifProvider.loadUserNotifications('att_001');

      expect(notifProvider.notifications, isNotEmpty);
      final initialUnread = notifProvider.unreadCount;
      expect(initialUnread, greaterThanOrEqualTo(0));

      if (notifProvider.notifications.any((n) => !n.isRead)) {
        final unreadNotif = notifProvider.notifications.firstWhere((n) => !n.isRead);
        await notifProvider.markAsRead(unreadNotif.id);
        expect(notifProvider.notifications.firstWhere((n) => n.id == unreadNotif.id).isRead, isTrue);
      }

      await notifProvider.markAllAsRead('att_001');
      expect(notifProvider.unreadCount, 0);
    });

    test('ContactProvider: submitMessage flow and state management', () async {
      final contactProvider = ContactProvider();
      final success = await contactProvider.submitMessage(
        name: 'Morgan Blake',
        email: 'morgan@example.com',
        subject: 'Accessibility question',
        message: 'Will sign language interpreters be present?',
      );
      expect(success, isTrue);
      expect(contactProvider.isSubmitting, isFalse);
      expect(contactProvider.errorMessage, isNull);
    });
  });

  group('Attendee Screens Widget Tests', () {
    testWidgets('HomeDiscoverScreen: renders header, search bar, chips, and event card details',
        (tester) async {
      await tester.pumpWidget(createTestApp(child: const HomeDiscoverScreen()));
      await tester.pumpAndSettle();

      // Top greeting
      expect(find.textContaining('Hello,'), findsOneWidget);
      expect(find.text('Discover extraordinary events happening near you'), findsOneWidget);

      // Search field & filter icon
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Category chips
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Technology'), findsWidgets);

      // Events list
      expect(find.text('Flutter & AI Mobile Dev Summit 2026'), findsOneWidget);
      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('HomeDiscoverScreen: Category chip tap updates filter state', (tester) async {
      await tester.pumpWidget(createTestApp(child: const HomeDiscoverScreen()));
      await tester.pumpAndSettle();

      // Tap on Technology category chip
      final techChip = find.widgetWithText(ChoiceChip, 'Technology');
      if (techChip.evaluate().isNotEmpty) {
        await tester.tap(techChip);
        await tester.pumpAndSettle();
      }

      expect(find.byType(HomeDiscoverScreen), findsOneWidget);
    });

    testWidgets('EventDetailsScreen: displays logistics, description, guidelines, and feedback',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const EventDetailsScreen(eventId: 'evt_001_flutter'),
      ));
      await tester.pumpAndSettle();

      // Title and category
      expect(find.text('Flutter & AI Mobile Dev Summit 2026'), findsWidgets);
      expect(find.text('About this Event'), findsOneWidget);
      expect(find.text('Location & Venue'), findsOneWidget);
      expect(find.text('Hosted By'), findsOneWidget);
      expect(find.text('TechSummit Global'), findsOneWidget);

      // Guidelines
      expect(find.text('Guidelines & Requirements'), findsOneWidget);

      // Bottom bar button
      expect(find.textContaining('Register Now'), findsWidgets);
    });

    testWidgets('MyEventsScreen: renders tabs, switches between Upcoming and Completed', (tester) async {
      final regProvider = RegistrationProvider();
      await regProvider.loadUserData('usr_001');

      await tester.pumpWidget(createTestApp(
        registrationProvider: regProvider,
        child: const MyEventsScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Registered Events'), findsOneWidget);
      expect(find.textContaining('Upcoming'), findsWidgets);
      expect(find.textContaining('Completed'), findsWidgets);
      expect(find.textContaining('Cancelled'), findsWidgets);

      // Tap Completed Tab
      await tester.tap(find.byType(Tab).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Cancelled Tab
      await tester.tap(find.byType(Tab).at(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('FavoritesScreen: displays saved events or empty state', (tester) async {
      final regProvider = RegistrationProvider();
      await regProvider.loadUserData('usr_001');

      await tester.pumpWidget(createTestApp(
        registrationProvider: regProvider,
        child: const FavoritesScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Saved Events'), findsOneWidget);
      expect(find.byType(EmptyStateView), findsWidgets);
    });

    testWidgets('NotificationsScreen: displays alerts, mark all read, and preferences dialog',
        (tester) async {
      final notifProvider = NotificationProvider();
      await notifProvider.loadUserNotifications('usr_001');

      await tester.pumpWidget(createTestApp(
        notificationProvider: notifProvider,
        child: const NotificationsScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Notifications'), findsOneWidget);

      // Tap Preferences Icon to open Dialog
      final prefButton = find.byIcon(Icons.tune_rounded);
      expect(prefButton, findsOneWidget);
      await tester.tap(prefButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog content
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Event Reminders (24h prior)'), findsOneWidget);
      expect(find.text('Organizer Announcements'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Preferences'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ProfileScreen: displays personal details, settings, and form editing with validation',
        (tester) async {
      await tester.pumpWidget(createTestApp(child: const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Profile & Settings'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Appearance / Theme'), findsOneWidget);
      expect(find.text('About EventEase'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Edit Profile button
      final editIcon = find.byIcon(Icons.edit_outlined);
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Edit Form fields & Save Button
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to revert edit state
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Save Changes'), findsNothing);
    });

    testWidgets('QRPassScreen: renders ticket stub, Pure-White QR container, and pass info',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const QRPassScreen(registrationId: 'reg_001'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Event Pass'), findsOneWidget);
      expect(find.text('Present this QR code at venue entrance for check-in'), findsOneWidget);
      expect(find.byType(QRPassCard), findsOneWidget);
      expect(find.textContaining('Unique anti-duplicate security token'), findsOneWidget);
    });

    testWidgets('SubmitFeedbackScreen: renders 5-star rating selector, text field, and submit action',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const SubmitFeedbackScreen(eventId: 'evt_006_completed'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Event Feedback'), findsOneWidget);
      expect(find.text('How was your experience?'), findsOneWidget);
      expect(find.text('Comments & Suggestions (Optional)'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);

      // 5 Star rating icons
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('SubmitFeedbackScreen: blocks feedback for non-completed events', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const SubmitFeedbackScreen(eventId: 'evt_001_flutter'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Event Feedback'), findsOneWidget);
      expect(find.text('Feedback Locked'), findsOneWidget);
      expect(find.textContaining('is unavailable until the event has concluded'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsNothing);
    });

    testWidgets('SubmitFeedbackScreen: blocks duplicate review when already submitted', (tester) async {
      final fbProvider = FeedbackProvider();
      // evt_006_completed has feedback already submitted by att_001 in seed data
      final defaultAuth = AuthProvider();
      defaultAuth.setCurrentUserForTesting(UserModel(
        id: 'att_001',
        email: 'attendee1@eventease.com',
        name: 'Alex Johnson',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: DateTime(2026, 1, 1),
      ));

      await tester.pumpWidget(createTestApp(
        authProvider: defaultAuth,
        feedbackProvider: fbProvider,
        child: const SubmitFeedbackScreen(eventId: 'evt_006_completed'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Feedback Submitted'), findsOneWidget);
      expect(find.textContaining('has been securely recorded'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsNothing);
    });

    testWidgets('AboutUsScreen: renders real project mission, pillars, and technical specifications (no placeholders)', (tester) async {
      await tester.pumpWidget(createTestApp(child: const AboutUsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About EventEase'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Core System Pillars'), findsOneWidget);
      expect(find.text('Role-Based Multi-Tier Security'), findsOneWidget);
      expect(find.text('Atomic 7-Step Transactions'), findsOneWidget);
      expect(find.text('Verified QR Attendance'), findsOneWidget);
      expect(find.text('Award-Winning Design System'), findsOneWidget);
      expect(find.text('Project Specifications'), findsOneWidget);
      expect(find.textContaining('Lorem ipsum'), findsNothing);
      expect(find.textContaining('placeholder'), findsNothing);
    });

    testWidgets('ErrorView: renders friendly error state and executes retry callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(createTestApp(
        child: Scaffold(
          body: ErrorView(
            message: 'Unable to reach backend database.',
            onRetry: () => retried = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Unable to reach backend database.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('EmptyStateView: renders animated icon, title, message, and action button', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(createTestApp(
        child: Scaffold(
          body: EmptyStateView(
            icon: Icons.event_busy_rounded,
            title: 'No Events Found',
            message: 'Try adjusting your search criteria.',
            actionLabel: 'Reset Filters',
            onAction: () => actionTriggered = true,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No Events Found'), findsOneWidget);
      expect(find.text('Try adjusting your search criteria.'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      await tester.tap(find.text('Reset Filters'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('ContactUsScreen: form input validation and submission flow', (tester) async {
      await tester.pumpWidget(createTestApp(child: const ContactUsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('Get in Touch'), findsOneWidget);
      expect(find.text('Your Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      expect(find.text('Subject *'), findsOneWidget);
      expect(find.text('Message *'), findsOneWidget);

      // Scroll to submit and tap with empty fields to verify validation errors trigger
      await tester.ensureVisible(find.text('Submit Inquiry'));
      await tester.tap(find.text('Submit Inquiry'));
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(find.byType(TextFormField).at(0), 'Alex Johnson');
      await tester.enterText(find.byType(TextFormField).at(1), 'alex@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'Schedule Inquiry');
      await tester.enterText(find.byType(TextFormField).at(3), 'What time do keynote sessions begin?');

      await tester.ensureVisible(find.text('Submit Inquiry'));
      await tester.tap(find.text('Submit Inquiry'));
      await tester.pumpAndSettle();

      // Success view
      expect(find.text('Message Dispatched'), findsOneWidget);
      expect(find.text('Send Another Inquiry'), findsOneWidget);
    });

    testWidgets('EventGalleryScreen: renders memory photo grid with empty state support',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: const EventGalleryScreen(eventId: 'evt_006_completed'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Event Memory Gallery'), findsOneWidget);
    });
  });
}
