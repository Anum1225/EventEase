import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/validators.dart';
import 'package:eventease/features/auth/screens/forgot_password_screen.dart';
import 'package:eventease/providers/auth_provider.dart';
import 'package:eventease/providers/registration_provider.dart';
import 'package:eventease/repositories/favorite_repository.dart';
import 'package:eventease/services/auth_service.dart';
import 'package:eventease/services/local_data_store.dart';

void main() {
  setUp(() {
    LocalDataStore().resetToSeedData();
  });

  group('Authentication & Password Change Tests', () {
    test('Validators validate required fields, emails, and passwords accurately', () {
      expect(Validators.required('', 'Name'), 'Name is required');
      expect(Validators.required('John', 'Name'), isNull);

      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('invalid-email'), 'Please enter a valid email address');
      expect(Validators.email('user@eventease.com'), isNull);

      expect(Validators.password(''), 'Password is required');
      expect(Validators.password('12345'), 'Password must be at least 6 characters long');
      expect(Validators.password('Password123!'), isNull);

      expect(Validators.confirmPassword('pass1', 'pass2'), 'Passwords do not match');
      expect(Validators.confirmPassword('pass1', 'pass1'), isNull);
    });

    test('changePassword updates credentials and invalidates the old password', () async {
      final authService = AuthService();

      // 1. Initial login with seed attendee password
      final initialUser = await authService.signIn(
        email: 'attendee1@eventease.com',
        password: 'AttendeePass2026!',
      );
      expect(initialUser.email, 'attendee1@eventease.com');

      // 2. Change password
      await authService.changePassword(
        currentPassword: 'AttendeePass2026!',
        newPassword: 'NewSecurePass2026#',
        userEmail: 'attendee1@eventease.com',
      );

      // 3. Attempting to sign in with OLD password must fail
      expect(
        () => authService.signIn(
          email: 'attendee1@eventease.com',
          password: 'AttendeePass2026!',
        ),
        throwsA(isA<AuthException>()),
      );

      // 4. Signing in with NEW password must succeed
      final updatedUser = await authService.signIn(
        email: 'attendee1@eventease.com',
        password: 'NewSecurePass2026#',
      );
      expect(updatedUser.id, initialUser.id);
      expect(updatedUser.email, 'attendee1@eventease.com');
    });

    test('changePassword rejects wrong current password and too short new password', () async {
      final authService = AuthService();

      expect(
        () => authService.changePassword(
          currentPassword: 'WrongOldPassword!',
          newPassword: 'ValidNewPass123!',
          userEmail: 'attendee1@eventease.com',
        ),
        throwsA(isA<AuthException>()),
      );

      expect(
        () => authService.changePassword(
          currentPassword: 'AttendeePass2026!',
          newPassword: '123',
          userEmail: 'attendee1@eventease.com',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Newly registered user can change password and old password stops working', () async {
      final authProvider = AuthProvider();

      // Register new user
      final registered = await authProvider.register(
        name: 'Sarah Connor',
        email: 'sarah.connor@example.com',
        password: 'OriginalPass123!',
        phone: '+15551234567',
      );
      expect(registered, isTrue);
      expect(authProvider.currentUser?.email, 'sarah.connor@example.com');

      // Change password
      final changed = await authProvider.changePassword(
        'OriginalPass123!',
        'UpdatedPass456!',
      );
      expect(changed, isTrue);

      // Logout and test login with old and new passwords
      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);

      final failedLogin = await authProvider.login('sarah.connor@example.com', 'OriginalPass123!');
      expect(failedLogin, isFalse);
      expect(authProvider.isAuthenticated, isFalse);

      final successfulLogin = await authProvider.login('sarah.connor@example.com', 'UpdatedPass456!');
      expect(successfulLogin, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.name, 'Sarah Connor');
    });
  });

  group('Registration & Saved Events Auto-Sync Tests', () {
    test('Registering for an event automatically adds it to favoriteEventIds and saved favorites', () async {
      final regProvider = RegistrationProvider();
      const userId = 'att_005';
      const eventId = 'evt_002_music';

      // Load user data initially
      await regProvider.loadUserData(userId);

      // Register for event
      final reg = await regProvider.registerForEvent(
        eventId: eventId,
        userId: userId,
        userName: 'Noah Wilson',
        userEmail: 'attendee5@eventease.com',
        eventTitle: 'Acoustic Sunset Music Festival',
      );

      expect(reg, isNotNull);
      expect(regProvider.isRegisteredForEvent(eventId), isTrue);

      // Verify the event is also automatically in favoriteEventIds
      expect(regProvider.isEventFavorited(eventId), isTrue);
      expect(regProvider.favoriteEventIds.contains(eventId), isTrue);

      // Verify FavoriteRepository / LocalDataStore has it saved
      final favRepo = FavoriteRepository();
      final favs = await favRepo.getUserFavorites(userId);
      expect(favs.any((f) => f.eventId == eventId), isTrue);
    });

    test('loadUserData includes both bookmarked favorites and registered events in favoriteEventIds', () async {
      final store = LocalDataStore();
      const userId = 'att_custom_user';
      const eventId = 'evt_002_music';

      // Create a registration directly in the store
      store.registerForEvent(
        eventId: eventId,
        userId: userId,
        userName: 'Test Attendee',
        userEmail: 'attendee@test.com',
        eventTitle: 'Acoustic Sunset Music Festival',
      );

      final regProvider = RegistrationProvider();
      await regProvider.loadUserData(userId);

      expect(regProvider.isRegisteredForEvent(eventId), isTrue);
      expect(regProvider.isEventFavorited(eventId), isTrue);
    });
  });

  group('ForgotPasswordScreen Responsive & Submission Widget Tests', () {
    testWidgets('ForgotPasswordScreen renders, validates email, and submits successfully', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Submit with empty field
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'attendee1@eventease.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Verify success card is displayed
      expect(find.text('Reset Link Sent'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });
  });
}
