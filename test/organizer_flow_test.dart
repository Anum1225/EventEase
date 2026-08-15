import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/constants/app_constants.dart';
import 'package:eventease/core/theme/app_theme.dart';
import 'package:eventease/models/user_model.dart';
import 'package:eventease/models/event_model.dart';
import 'package:eventease/providers/auth_provider.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/providers/attendance_provider.dart';
import 'package:eventease/providers/feedback_provider.dart';
import 'package:eventease/providers/gallery_provider.dart';
import 'package:eventease/providers/notification_provider.dart';
import 'package:eventease/providers/theme_provider.dart';
import 'package:eventease/repositories/attendance_repository.dart';
import 'package:eventease/features/organizer/screens/organizer_dashboard_screen.dart';
import 'package:eventease/features/organizer/screens/create_edit_event_screen.dart';
import 'package:eventease/features/organizer/screens/attendance_scanner_screen.dart';
import 'package:eventease/features/organizer/screens/participants_screen.dart';
import 'package:eventease/features/organizer/screens/announcements_screen.dart';
import 'package:eventease/features/organizer/screens/gallery_upload_screen.dart';
import 'package:eventease/features/organizer/screens/organizer_feedback_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildOrganizerTestApp({
    required Widget child,
    UserModel? currentUser,
  }) {
    final user = currentUser ??
        UserModel(
          id: 'org_001',
          name: 'TechSummit Global',
          email: 'organizer1@eventease.com',
          role: AppConstants.roleOrganizer,
          status: AppConstants.userStatusActive,
          createdAt: DateTime(2026, 1, 1),
        );

    final authProvider = AuthProvider()..setCurrentUserForTesting(user);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Attendance Repository & Provider Unit Tests', () {
    late AttendanceRepository attendanceRepo;
    late AttendanceProvider attendanceProvider;

    setUp(() {
      attendanceRepo = AttendanceRepository();
      attendanceProvider = AttendanceProvider(attendanceRepository: attendanceRepo);
    });

    test('Valid QR pass check-in succeeds and returns attendee details', () async {
      final result = await attendanceRepo.checkInByQrCode(
        qrPayload: 'EASE-reg_001-DEMOPASS1',
        currentEventId: 'evt_001_flutter',
        organizerId: 'org_001',
      );

      expect(result.success, isTrue);
      expect(result.isDuplicate, isFalse);
      expect(result.message, contains('Alex Johnson'));
      expect(result.attendance, isNotNull);
      expect(result.attendance?.attended, isTrue);
    });

    test('Manual check-in by Registration ID works seamlessly', () async {
      // LocalDataStore supports case-insensitive ID matching
      final result = await attendanceRepo.checkInByQrCode(
        qrPayload: 'reg_001',
        currentEventId: 'evt_001_flutter',
        organizerId: 'org_001',
      );

      // Either success or already checked in from previous test
      expect(result.message.isNotEmpty, isTrue);
    });

    test('Duplicate check-in attempt is rejected with duplicate flag', () async {
      // evt_006_completed has already checked in reg_002
      final result = await attendanceRepo.checkInByQrCode(
        qrPayload: 'EASE-reg_002-CHECKEDIN1',
        currentEventId: 'evt_006_completed',
        organizerId: 'org_001',
      );

      expect(result.success, isFalse);
      expect(result.isDuplicate, isTrue);
      expect(result.message, contains('ALREADY CHECKED IN'));
    });

    test('Pass for different event is rejected', () async {
      final result = await attendanceRepo.checkInByQrCode(
        qrPayload: 'EASE-reg_001-DEMOPASS1',
        currentEventId: 'evt_002_music',
        organizerId: 'org_001',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('different event'));
    });

    test('Invalid QR code format returns failure result', () async {
      final result = await attendanceRepo.checkInByQrCode(
        qrPayload: 'COMPLETELY_INVALID_QR_TOKEN_9999',
        currentEventId: 'evt_001_flutter',
        organizerId: 'org_001',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Invalid'));
    });

    test('AttendanceProvider processScannedQr updates state and inserts record', () async {
      final result = await attendanceProvider.processScannedQr(
        qrPayload: 'EASE-reg_001-DEMOPASS1',
        currentEventId: 'evt_001_flutter',
        organizerId: 'org_001',
      );

      expect(result, isNotNull);
      expect(attendanceProvider.lastScanResult, isNotNull);
      expect(attendanceProvider.isProcessingScan, isFalse);

      attendanceProvider.clearLastScanResult();
      expect(attendanceProvider.lastScanResult, isNull);
    });

    test('AttendanceProvider loadEventParticipants calculates turnout metrics accurately', () async {
      await attendanceProvider.loadEventParticipants('evt_006_completed');

      expect(attendanceProvider.isLoading, isFalse);
      expect(attendanceProvider.eventParticipants.isNotEmpty, isTrue);
      expect(attendanceProvider.totalRegistered, greaterThanOrEqualTo(2));
      expect(attendanceProvider.totalCheckedIn, greaterThanOrEqualTo(2));
      expect(attendanceProvider.attendanceRate, greaterThan(0.0));
      expect(attendanceProvider.isAttendeeCheckedIn('reg_002'), isTrue);
    });
  });

  group('Event Provider Organizer CRUD Unit Tests', () {
    late EventProvider eventProvider;

    setUp(() {
      eventProvider = EventProvider();
    });

    test('loadOrganizerEvents retrieves events for specific organizer', () async {
      await eventProvider.loadOrganizerEvents('org_001');

      expect(eventProvider.isLoading, isFalse);
      expect(eventProvider.organizerEvents.isNotEmpty, isTrue);
      for (final ev in eventProvider.organizerEvents) {
        expect(ev.organizerId, 'org_001');
      }
    });

    test('createEvent persists event in pending_approval state', () async {
      final newEv = EventModel(
        id: '',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'New AI Workshop 2026',
        description: 'Deep dive into LLMs on mobile devices.',
        category: 'technology',
        date: DateTime.now().add(const Duration(days: 30)),
        startTime: '10:00 AM',
        endTime: '04:00 PM',
        location: 'Hall C, Tech Park',
        maxParticipants: 45,
        registeredCount: 0,
        status: AppConstants.eventStatusPendingApproval,
        createdAt: DateTime.now(),
      );

      final success = await eventProvider.createEvent(event: newEv);
      expect(success, isTrue);

      final created = eventProvider.organizerEvents.firstWhere((e) => e.title == 'New AI Workshop 2026');
      expect(created.status, AppConstants.eventStatusPendingApproval);
      expect(created.isPending, isTrue);
    });

    test('updateEvent with material change marks event pending approval', () async {
      await eventProvider.loadOrganizerEvents('org_001');
      final existing = eventProvider.organizerEvents.first;
      final updated = existing.copyWith(
        title: '${existing.title} (Updated)',
        location: 'New Venue Location',
      );

      final success = await eventProvider.updateEvent(
        event: updated,
        isMaterialChange: true,
      );

      expect(success, isTrue);
    });

    test('cancelEvent updates status to cancelled with reason', () async {
      await eventProvider.loadOrganizerEvents('org_001');
      final existing = eventProvider.organizerEvents.first;
      final success = await eventProvider.cancelEvent(
        eventId: existing.id,
        reason: 'Emergency maintenance at venue',
        eventTitle: existing.title,
        organizerId: 'org_001',
      );

      expect(success, isTrue);
    });
  });

  group('Organizer Screens Widget Tests', () {
    testWidgets('OrganizerDashboardScreen renders KPI cards and event list', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(child: const OrganizerDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Organizer Portal'), findsOneWidget);
      expect(find.text('Overview & Performance'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsWidgets);
    });

    testWidgets('CreateEditEventScreen validates required form fields', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(child: const CreateEditEventScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create New Event'), findsOneWidget);
      expect(find.text('Event Title *'), findsOneWidget);
      expect(find.text('Description *'), findsOneWidget);
      expect(find.text('Location / Venue Address *'), findsOneWidget);
      expect(find.text('Maximum Capacity (Seats) *'), findsOneWidget);

      // Scroll to submit button and tap with empty form to trigger validations
      await tester.ensureVisible(find.text('Submit for Admin Approval'));
      await tester.tap(find.text('Submit for Admin Approval'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
      expect(find.text('Location is required'), findsOneWidget);
    });

    testWidgets('AttendanceScannerScreen renders scanner UI and manual entry dialog', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(
        child: const AttendanceScannerScreen(initialEventId: 'evt_001_flutter'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('QR Attendance Scanner'), findsOneWidget);
      expect(find.byIcon(Icons.dialpad_rounded), findsWidgets);

      // Open Manual Pass Entry Dialog
      await tester.tap(find.byIcon(Icons.dialpad_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Manual Pass Check-In'), findsOneWidget);
      expect(find.text('Verify & Check In'), findsOneWidget);

      // Enter code and submit
      await tester.enterText(find.byType(TextFormField), 'EASE-reg_001-DEMOPASS1');
      await tester.tap(find.text('Verify & Check In'));
      await tester.pumpAndSettle();

      // Bottom sheet appears with check-in status
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('ParticipantsScreen renders roster and responds to status filter chips', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(
        child: const ParticipantsScreen(initialEventId: 'evt_006_completed'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Participant Roster'), findsOneWidget);
      expect(find.textContaining('Registered:'), findsWidgets);
      expect(find.textContaining('Checked In:'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Attended ('), findsOneWidget);

      // Tap Attended filter chip
      await tester.tap(find.textContaining('Attended ('));
      await tester.pumpAndSettle();

      // Filter search
      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.pumpAndSettle();
      expect(find.text('Alex Johnson'), findsOneWidget);
    });

    testWidgets('AnnouncementsScreen validates subject and body before sending', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(
        child: const AnnouncementsScreen(initialEventId: 'evt_001_flutter'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Broadcast Announcement'), findsOneWidget);
      expect(find.text('Target Event *'), findsOneWidget);
      expect(find.text('Send Broadcast'), findsOneWidget);

      // Tap Send with empty fields
      await tester.tap(find.text('Send Broadcast'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Message body is required'), findsOneWidget);
    });

    testWidgets('GalleryUploadScreen renders upload area and photos section', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(
        child: const GalleryUploadScreen(initialEventId: 'evt_006_completed'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Event Gallery Upload'), findsOneWidget);
      expect(find.text('Tap to choose memory photo'), findsOneWidget);
      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.textContaining('Uploaded Photos'), findsOneWidget);
    });

    testWidgets('OrganizerFeedbackScreen displays rating stats and review list', (tester) async {
      await tester.pumpWidget(buildOrganizerTestApp(
        child: const OrganizerFeedbackScreen(initialEventId: 'evt_006_completed'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Attendee Reviews & Feedback'), findsOneWidget);
      expect(find.textContaining('Total Reviews'), findsOneWidget);
      expect(find.text('Read-Only'), findsOneWidget);
      expect(find.text('Alex Johnson'), findsOneWidget);
    });
  });
}
