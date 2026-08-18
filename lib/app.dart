import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/event_provider.dart';
import 'providers/registration_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/contact_provider.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/organizer_pending_screen.dart';

import 'features/attendee/screens/attendee_shell.dart';
import 'features/attendee/screens/home_discover_screen.dart';
import 'features/attendee/screens/my_events_screen.dart';
import 'features/attendee/screens/favorites_screen.dart';
import 'features/attendee/screens/notifications_screen.dart';
import 'features/attendee/screens/profile_screen.dart';
import 'features/attendee/screens/event_details_screen.dart';
import 'features/attendee/screens/qr_pass_screen.dart';
import 'features/attendee/screens/submit_feedback_screen.dart';

import 'features/organizer/screens/organizer_shell.dart';
import 'features/organizer/screens/organizer_dashboard_screen.dart';
import 'features/organizer/screens/create_edit_event_screen.dart';
import 'features/organizer/screens/attendance_scanner_screen.dart';
import 'features/organizer/screens/participants_screen.dart';
import 'features/organizer/screens/announcements_screen.dart';
import 'features/organizer/screens/gallery_upload_screen.dart';
import 'features/organizer/screens/organizer_feedback_screen.dart';

import 'features/admin/screens/admin_shell.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/event_approvals_screen.dart';
import 'features/admin/screens/user_management_screen.dart';
import 'features/admin/screens/event_management_screen.dart';
import 'features/admin/screens/gallery_moderation_screen.dart';
import 'features/admin/screens/reports_statistics_screen.dart';

import 'features/shared/screens/about_us_screen.dart';
import 'features/shared/screens/contact_us_screen.dart';
import 'features/shared/screens/event_gallery_screen.dart';

/// App Router configuration with role-based route guards
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isAuth = authProvider.isAuthenticated;
    final role = authProvider.role;
    final path = state.uri.path;

    if (path == '/splash') return null;

    final isAuthRoute = path == '/login' || path == '/register' || path == '/forgot-password';

    // Unauthenticated trying to access protected route
    if (!isAuth) {
      final isGuestAllowed = path == '/splash' ||
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path.startsWith('/attendee') ||
          path.startsWith('/event-details/') ||
          path.startsWith('/event/') ||
          path.startsWith('/gallery/') ||
          path == '/about-us' ||
          path == '/contact-us';

      if (!isGuestAllowed) {
        String pageName = 'this feature';
        if (path.startsWith('/organizer')) {
          pageName = 'Organizer Portal';
        } else if (path.startsWith('/admin')) {
          pageName = 'Admin Panel';
        } else if (path.contains('qr-pass') || path.contains('pass')) {
          pageName = 'QR Pass';
        } else if (path.contains('feedback')) {
          pageName = 'Submit Feedback';
        }

        return '/login?reason=${Uri.encodeComponent(pageName)}';
      }
      return null;
    }

    // Authenticated on login/register screen
    if (isAuthRoute) {
      if (role == 'admin') return '/admin';
      if (role == 'organizer') return '/organizer';
      if (role == 'organizer_pending') return '/organizer-pending';
      return '/attendee';
    }

    // Pending Organizer Guard
    if (role == 'organizer_pending' && path.startsWith('/organizer')) {
      return '/organizer-pending';
    }

    // Role-based Access Control
    if (path.startsWith('/admin') && role != 'admin') {
      return '/attendee';
    }
    if (path.startsWith('/organizer') && role != 'organizer' && role != 'admin') {
      return '/attendee';
    }

    return null;
  },
  routes: [
    // Splash Route
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth Stack
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/organizer-pending',
      builder: (context, state) => const OrganizerPendingScreen(),
    ),

    // Attendee Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AttendeeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendee',
              builder: (context, state) => const HomeDiscoverScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendee/my-events',
              builder: (context, state) => const MyEventsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendee/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendee/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendee/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Organizer Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => OrganizerShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer',
              builder: (context, state) => const OrganizerDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/create-event',
              builder: (context, state) => const CreateEditEventScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/scanner',
              builder: (context, state) {
                final eventId = state.uri.queryParameters['eventId'];
                return AttendanceScannerScreen(initialEventId: eventId);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/participants',
              builder: (context, state) {
                final eventId = state.uri.queryParameters['eventId'];
                return ParticipantsScreen(initialEventId: eventId);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/feedback',
              builder: (context, state) {
                final eventId = state.uri.queryParameters['eventId'];
                return OrganizerFeedbackScreen(initialEventId: eventId);
              },
            ),
          ],
        ),
      ],
    ),

    // Admin Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AdminShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/approvals',
              builder: (context, state) => const EventApprovalsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/users',
              builder: (context, state) => const UserManagementScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/events',
              builder: (context, state) => const EventManagementScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/reports',
              builder: (context, state) => const ReportsStatisticsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Non-Shell Feature Routes
    GoRoute(
      path: '/event-details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return EventDetailsScreen(eventId: id);
      },
    ),
    GoRoute(
      path: '/event/:id',
      redirect: (context, state) => '/event-details/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/qr-pass/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return QRPassScreen(registrationId: id);
      },
    ),
    GoRoute(
      path: '/pass/:id',
      redirect: (context, state) => '/qr-pass/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/feedback/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SubmitFeedbackScreen(eventId: id);
      },
    ),
    GoRoute(
      path: '/gallery/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return EventGalleryScreen(eventId: id);
      },
    ),
    GoRoute(
      path: '/about-us',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/contact-us',
      builder: (context, state) => const ContactUsScreen(),
    ),
    GoRoute(
      path: '/organizer/edit-event/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return CreateEditEventScreen(eventId: id);
      },
    ),
    GoRoute(
      path: '/organizer/announcements',
      builder: (context, state) {
        final eventId = state.uri.queryParameters['eventId'];
        return AnnouncementsScreen(initialEventId: eventId);
      },
    ),
    GoRoute(
      path: '/organizer/gallery-upload',
      builder: (context, state) {
        final eventId = state.uri.queryParameters['eventId'];
        return GalleryUploadScreen(initialEventId: eventId);
      },
    ),
    GoRoute(
      path: '/admin/gallery-moderation',
      builder: (context, state) => const GalleryModerationScreen(),
    ),
  ],
);

class AuthNotifier extends ChangeNotifier {
  AuthProvider? _authProvider;

  void update(AuthProvider authProvider) {
    if (_authProvider != authProvider) {
      _authProvider?.removeListener(notifyListeners);
      _authProvider = authProvider;
      _authProvider?.addListener(notifyListeners);
    }
  }
}

final _authNotifier = AuthNotifier();

/// Root Application Widget with MultiProvider hierarchy
class EventEaseApp extends StatelessWidget {
  const EventEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          _authNotifier.update(authProvider);
          return MaterialApp.router(
            title: 'EventEase',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: Duration.zero,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
