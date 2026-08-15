import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/constants/app_constants.dart';
import 'package:eventease/core/theme/app_theme.dart';
import 'package:eventease/providers/admin_provider.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/providers/gallery_provider.dart';
import 'package:eventease/providers/auth_provider.dart';
import 'package:eventease/providers/theme_provider.dart';
import 'package:eventease/services/local_data_store.dart';
import 'package:eventease/features/admin/screens/admin_dashboard_screen.dart';
import 'package:eventease/features/admin/screens/event_approvals_screen.dart';
import 'package:eventease/features/admin/screens/user_management_screen.dart';
import 'package:eventease/features/admin/screens/event_management_screen.dart';
import 'package:eventease/features/admin/screens/gallery_moderation_screen.dart';
import 'package:eventease/features/admin/screens/reports_statistics_screen.dart';

Widget createAdminTestWidget({
  required Widget child,
  AdminProvider? adminProvider,
  EventProvider? eventProvider,
  GalleryProvider? galleryProvider,
  AuthProvider? authProvider,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminProvider>(
        create: (_) => adminProvider ?? AdminProvider(),
      ),
      ChangeNotifierProvider<EventProvider>(
        create: (_) => eventProvider ?? EventProvider(),
      ),
      ChangeNotifierProvider<GalleryProvider>(
        create: (_) => galleryProvider ?? GalleryProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => themeProvider ?? ThemeProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    // Reset in-memory database to seed baseline before each test
    LocalDataStore().resetToSeedData();
  });

  group('Admin Statistics & KPI Analytics Calculation Tests', () {
    test('computeSystemStatistics computes accurate system-wide metrics and aggregates', () async {
      final adminProvider = AdminProvider();
      await adminProvider.computeSystemStatistics();

      final stats = adminProvider.statistics;
      expect(stats, isNotNull);
      expect(stats!.totalUsers, greaterThanOrEqualTo(9));
      expect(stats.totalOrganizers, greaterThanOrEqualTo(2));
      expect(stats.totalAttendees, greaterThanOrEqualTo(5));
      expect(stats.totalEvents, greaterThanOrEqualTo(8));
      expect(stats.totalApprovedEvents, greaterThanOrEqualTo(4));
      expect(stats.totalPendingApprovals, greaterThanOrEqualTo(1));
      expect(stats.totalRegistrations, greaterThan(0));
      expect(stats.totalCheckIns, greaterThan(0));
      expect(stats.averageSystemRating, greaterThan(0.0));
      expect(stats.popularEvents, isNotEmpty);

      // Verify popular events are sorted in descending order of registered count
      for (int i = 0; i < stats.popularEvents.length - 1; i++) {
        expect(
          stats.popularEvents[i].registeredCount >= stats.popularEvents[i + 1].registeredCount,
          isTrue,
        );
      }
    });
  });

  group('Admin User Management Unit Tests', () {
    test('loadUsers filters by role and search query', () async {
      final adminProvider = AdminProvider();

      // Load all users
      await adminProvider.loadUsers();
      final totalAll = adminProvider.users.length;
      expect(totalAll, greaterThanOrEqualTo(9));

      // Filter by organizer
      await adminProvider.loadUsers(role: AppConstants.roleOrganizer);
      expect(adminProvider.users.every((u) => u.role == AppConstants.roleOrganizer), isTrue);

      // Filter by search query
      await adminProvider.loadUsers(query: 'Alex');
      expect(adminProvider.users.any((u) => u.name.contains('Alex')), isTrue);
    });

    test('approveOrganizer promotes pending applicant to organizer and retains filter', () async {
      final adminProvider = AdminProvider();
      await adminProvider.loadPendingOrganizers();
      expect(adminProvider.pendingOrganizers.isNotEmpty, isTrue);

      final pendingUser = adminProvider.pendingOrganizers.first;
      final success = await adminProvider.approveOrganizer(
        pendingUser.id,
        pendingUser.email,
        pendingUser.name,
      );

      expect(success, isTrue);
      await adminProvider.loadUsers();
      final updatedUser = adminProvider.users.firstWhere((u) => u.id == pendingUser.id);
      expect(updatedUser.role, AppConstants.roleOrganizer);
    });

    test('rejectOrganizer demotes pending applicant to attendee with justification reason', () async {
      final adminProvider = AdminProvider();
      await adminProvider.loadPendingOrganizers();
      expect(adminProvider.pendingOrganizers.isNotEmpty, isTrue);

      final pendingUser = adminProvider.pendingOrganizers.first;
      final success = await adminProvider.rejectOrganizer(
        pendingUser.id,
        'Invalid business credentials provided.',
        pendingUser.name,
      );

      expect(success, isTrue);
      await adminProvider.loadUsers();
      final updatedUser = adminProvider.users.firstWhere((u) => u.id == pendingUser.id);
      expect(updatedUser.role, AppConstants.roleAttendee);
      expect(updatedUser.organizerApprovalStatus, 'rejected');
      expect(updatedUser.organizerApprovalReason, 'Invalid business credentials provided.');
    });

    test('toggleUserStatus deactivates and reactivates user account', () async {
      final adminProvider = AdminProvider();
      await adminProvider.loadUsers();

      final attendee = adminProvider.users.firstWhere((u) => u.role == AppConstants.roleAttendee);
      expect(attendee.status, AppConstants.userStatusActive);

      // Deactivate
      final deactSuccess = await adminProvider.toggleUserStatus(attendee.id, true);
      expect(deactSuccess, isTrue);
      final deactUser = adminProvider.users.firstWhere((u) => u.id == attendee.id);
      expect(deactUser.status, AppConstants.userStatusDeactivated);

      // Reactivate
      final reactSuccess = await adminProvider.toggleUserStatus(attendee.id, false);
      expect(reactSuccess, isTrue);
      final reactUser = adminProvider.users.firstWhere((u) => u.id == attendee.id);
      expect(reactUser.status, AppConstants.userStatusActive);
    });
  });

  group('Admin Event Approvals & Governance Unit Tests', () {
    test('approveEvent publishes pending event to discoverable catalog', () async {
      final eventProvider = EventProvider();
      await eventProvider.loadPendingApprovals();
      expect(eventProvider.pendingApprovalEvents.isNotEmpty, isTrue);

      final pendingEvent = eventProvider.pendingApprovalEvents.first;
      final success = await eventProvider.approveEvent(
        pendingEvent.id,
        pendingEvent.organizerId,
        pendingEvent.title,
      );

      expect(success, isTrue);
      expect(eventProvider.pendingApprovalEvents.any((e) => e.id == pendingEvent.id), isFalse);

      await eventProvider.loadAllAdminEvents();
      final approvedEvent = eventProvider.allAdminEvents.firstWhere((e) => e.id == pendingEvent.id);
      expect(approvedEvent.status, AppConstants.eventStatusApproved);
    });

    test('rejectEvent marks pending event as rejected with mandatory reason', () async {
      final eventProvider = EventProvider();
      await eventProvider.loadPendingApprovals();
      expect(eventProvider.pendingApprovalEvents.isNotEmpty, isTrue);

      final pendingEvent = eventProvider.pendingApprovalEvents.first;
      const rejectReason = 'Incomplete emergency medical response plan.';
      final success = await eventProvider.rejectEvent(
        pendingEvent.id,
        rejectReason,
        pendingEvent.organizerId,
        pendingEvent.title,
      );

      expect(success, isTrue);
      expect(eventProvider.pendingApprovalEvents.any((e) => e.id == pendingEvent.id), isFalse);

      await eventProvider.loadAllAdminEvents();
      final rejected = eventProvider.allAdminEvents.firstWhere((e) => e.id == pendingEvent.id);
      expect(rejected.status, AppConstants.eventStatusRejected);
      expect(rejected.rejectionReason, rejectReason);
    });

    test('deleteEvent permanently deletes event record from system', () async {
      final eventProvider = EventProvider();
      await eventProvider.loadAllAdminEvents();
      final initialCount = eventProvider.allAdminEvents.length;

      final targetEvent = eventProvider.allAdminEvents.first;
      final success = await eventProvider.deleteEvent(targetEvent.id);

      expect(success, isTrue);
      expect(eventProvider.allAdminEvents.any((e) => e.id == targetEvent.id), isFalse);
      expect(eventProvider.allAdminEvents.length, initialCount - 1);
    });
  });

  group('Admin Gallery Moderation Unit Tests', () {
    test('deleteMedia removes photo memory from moderation queue', () async {
      final galleryProvider = GalleryProvider();
      await galleryProvider.loadAllGalleryForAdmin();
      expect(galleryProvider.adminAllGallery.isNotEmpty, isTrue);

      final initialCount = galleryProvider.adminAllGallery.length;
      final target = galleryProvider.adminAllGallery.first;

      final success = await galleryProvider.deleteMedia(target.id, eventId: target.eventId);
      expect(success, isTrue);
      expect(galleryProvider.adminAllGallery.any((g) => g.id == target.id), isFalse);
      expect(galleryProvider.adminAllGallery.length, initialCount - 1);
    });
  });

  group('Admin Screens Widget Rendering & Interaction Tests', () {
    testWidgets('AdminDashboardScreen renders header, KPIs, action tiles, and seeder box', (tester) async {
      final adminProvider = AdminProvider();
      final eventProvider = EventProvider();

      await tester.pumpWidget(createAdminTestWidget(
        child: const AdminDashboardScreen(),
        adminProvider: adminProvider,
        eventProvider: eventProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Institutional Admin'), findsOneWidget);
      expect(find.text('Governance Console'), findsOneWidget);
      expect(find.text('System Vital Signs'), findsOneWidget);
      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('Total Events'), findsOneWidget);
      expect(find.text('Registrations'), findsOneWidget);
      expect(find.text('Administrative Tools'), findsOneWidget);
      expect(find.text('Event Approvals Queue'), findsOneWidget);
      expect(find.text('User Management & Roles'), findsOneWidget);
      expect(find.text('SRS Test Dataset Seeder'), findsOneWidget);
    });

    testWidgets('EventApprovalsScreen renders pending submissions with approve and reject buttons', (tester) async {
      final eventProvider = EventProvider();
      await eventProvider.loadPendingApprovals();

      await tester.pumpWidget(createAdminTestWidget(
        child: const EventApprovalsScreen(),
        eventProvider: eventProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Event Approval Queue'), findsOneWidget);
      if (eventProvider.pendingApprovalEvents.isNotEmpty) {
        expect(find.text('Approve & Publish'), findsWidgets);
        expect(find.text('Reject'), findsWidgets);

        // Tap Reject button to open rejection reason dialog
        await tester.tap(find.text('Reject').first);
        await tester.pumpAndSettle();

        expect(find.text('Reject Event Submission'), findsOneWidget);
        expect(find.text('Confirm Rejection'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Reject Event Submission'), findsNothing);
      } else {
        expect(find.text('Queue is Empty'), findsOneWidget);
      }
    });

    testWidgets('UserManagementScreen renders search, role filter chips, and user account cards', (tester) async {
      final adminProvider = AdminProvider();
      await adminProvider.loadUsers();

      await tester.pumpWidget(createAdminTestWidget(
        child: const UserManagementScreen(),
        adminProvider: adminProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('User & Role Directory'), findsOneWidget);
      expect(find.text('All Users'), findsOneWidget);
      expect(find.text('Pending Organizers'), findsOneWidget);
      expect(find.text('Organizers'), findsOneWidget);
      expect(find.text('Attendees'), findsOneWidget);
      expect(find.text('Admins'), findsOneWidget);

      // Verify search input is present
      expect(find.byType(TextField), findsOneWidget);

      // Tap on Organizers filter chip
      await tester.tap(find.text('Organizers'));
      await tester.pumpAndSettle();
      expect(adminProvider.users.every((u) => u.role == AppConstants.roleOrganizer), isTrue);
    });

    testWidgets('EventManagementScreen renders status filters and event cards with view, edit, and delete options', (tester) async {
      final eventProvider = EventProvider();
      await eventProvider.loadAllAdminEvents();

      await tester.pumpWidget(createAdminTestWidget(
        child: const EventManagementScreen(),
        eventProvider: eventProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('System Event Directory'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
      expect(find.text('Approved'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);

      expect(find.text('View'), findsWidgets);
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('GalleryModerationScreen renders media catalog and remove photo button', (tester) async {
      final galleryProvider = GalleryProvider();
      await galleryProvider.loadAllGalleryForAdmin();

      await tester.pumpWidget(createAdminTestWidget(
        child: const GalleryModerationScreen(),
        galleryProvider: galleryProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Media & Gallery Moderation'), findsOneWidget);
      if (galleryProvider.adminAllGallery.isNotEmpty) {
        expect(find.text('Remove'), findsWidgets);
      } else {
        expect(find.text('No Media Uploads'), findsOneWidget);
      }
    });

    testWidgets('ReportsStatisticsScreen renders summary cards, donut chart, and leaderboard', (tester) async {
      final adminProvider = AdminProvider();
      await adminProvider.computeSystemStatistics();

      await tester.pumpWidget(createAdminTestWidget(
        child: const ReportsStatisticsScreen(),
        adminProvider: adminProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Institutional Reports & Analytics'), findsOneWidget);
      expect(find.text('Executive Summary'), findsOneWidget);
      expect(find.text('User Base'), findsOneWidget);
      expect(find.text('Event Pipeline'), findsOneWidget);
      expect(find.text('Engagement'), findsOneWidget);
      expect(find.text('Verified Check-Ins'), findsOneWidget);
      expect(find.text('System Breakdown & Ratio'), findsOneWidget);
      expect(find.text('Popular Events Leaderboard'), findsOneWidget);
    });
  });
}
