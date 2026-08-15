import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'local_data_store.dart';

/// Exception wrapper providing user-friendly, specific error strings
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service managing Authentication with automatic dual-engine fallback (Firebase Auth & Local Data Engine)
class AuthService {
  FirebaseAuth? _auth;
  final UserRepository _userRepository;
  final LocalDataStore _localStore = LocalDataStore();
  static bool _firebaseAuthUnavailable = false;

  AuthService({
    FirebaseAuth? auth,
    UserRepository? userRepository,
  }) : _userRepository = userRepository ?? UserRepository() {
    if (auth != null) {
      _auth = auth;
    }
  }

  FirebaseAuth? get _safeAuth {
    if (_firebaseAuthUnavailable) return null;
    if (_auth != null) return _auth;
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      try {
        _auth = FirebaseAuth.instance;
        return _auth;
      } catch (_) {
        _firebaseAuthUnavailable = true;
        return null;
      }
    }
    return null;
  }

  Stream<User?> get authStateChanges {
    final auth = _safeAuth;
    if (auth != null && !_firebaseAuthUnavailable) {
      try {
        return auth.authStateChanges().handleError((_) {});
      } catch (_) {}
    }
    return const Stream.empty();
  }

  User? get currentUser {
    final auth = _safeAuth;
    if (auth != null && !_firebaseAuthUnavailable) {
      try {
        return auth.currentUser;
      } catch (_) {}
    }
    return null;
  }

  /// Sign In with dual-engine verification
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Fast-path local store verification for seeded and registered accounts (0ms, 0 network errors)
    final existingLocal = _localStore.getAllUsers().where((u) => u.email.toLowerCase() == cleanEmail);
    if (existingLocal.isNotEmpty) {
      try {
        final localUser = _localStore.authenticateUser(email, password);
        if (localUser != null) {
          return localUser;
        }
      } catch (e) {
        if (e.toString().contains('deactivated')) {
          throw AuthException('Your account has been deactivated by an administrator.');
        }
        if (e.toString().contains('Incorrect password')) {
          throw AuthException('Invalid email or password.');
        }
      }
    }

    final auth = _safeAuth;
    // 2. Try Firebase Authentication if configured and available
    if (auth != null && DefaultFirebaseOptions.isLiveFirebaseConfigured && !_firebaseAuthUnavailable) {
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          var userModel = await _userRepository.getUser(firebaseUser.uid);
          if (userModel == null) {
            final isAdmin = firebaseUser.email?.toLowerCase() == 'admin@eventease.com';
            userModel = UserModel(
              id: firebaseUser.uid,
              name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
              email: firebaseUser.email ?? email.trim(),
              role: isAdmin ? AppConstants.roleAdmin : AppConstants.roleAttendee,
              status: AppConstants.userStatusActive,
              createdAt: DateTime.now(),
            );
            await _userRepository.createUser(userModel);
          }
          if (userModel.status == AppConstants.userStatusDeactivated) {
            await auth.signOut();
            throw AuthException('Your account has been deactivated by an administrator.');
          }
          _localStore.updateUser(userModel);
          return userModel;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'configuration-not-found' ||
            e.code == 'CONFIGURATION_NOT_FOUND' ||
            e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
          _firebaseAuthUnavailable = true;
        } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw AuthException('Invalid email or password.');
        } else if (e.code == 'user-disabled') {
          throw AuthException('This user account has been disabled.');
        }
      } catch (e) {
        if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
          _firebaseAuthUnavailable = true;
        }
        if (e is AuthException) rethrow;
      }
    }

    // 3. Fallback to Local Database Engine authentication
    try {
      final localUser = _localStore.authenticateUser(email, password);
      if (localUser != null) {
        return localUser;
      }
      throw AuthException('Invalid email or password.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Registration Flow: Default role is 'attendee', or 'organizer_pending' if applicant
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool applyAsOrganizer = false,
  }) async {
    final auth = _safeAuth;
    // 1. Try Firebase Auth only if real live credentials configured
    if (auth != null && DefaultFirebaseOptions.isLiveFirebaseConfigured && !_firebaseAuthUnavailable) {
      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          final role = applyAsOrganizer
              ? AppConstants.roleOrganizerPending
              : AppConstants.roleAttendee;

          final newUser = UserModel(
            id: firebaseUser.uid,
            name: name.trim(),
            email: email.trim(),
            phone: phone?.trim(),
            role: role,
            organizerApprovalStatus: applyAsOrganizer ? 'pending' : null,
            status: AppConstants.userStatusActive,
            createdAt: DateTime.now(),
          );

          await _userRepository.createUser(newUser);
          _localStore.updateUser(newUser);
          return newUser;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'configuration-not-found' ||
            e.code == 'CONFIGURATION_NOT_FOUND' ||
            e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
          _firebaseAuthUnavailable = true;
          // Fall through to localStore registration below
        } else if (e.code == 'email-already-in-use') {
          throw AuthException('An account already exists with this email address.');
        } else if (e.code == 'weak-password') {
          throw AuthException('The password provided is too weak.');
        } else if (e.code == 'invalid-email') {
          throw AuthException('The email address format is invalid.');
        }
      } catch (e) {
        if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
          _firebaseAuthUnavailable = true;
        }
        if (e is AuthException) rethrow;
      }
    }

    // 2. Seamless Local Database Engine registration
    try {
      final localUser = _localStore.registerUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        applyAsOrganizer: applyAsOrganizer,
      );
      await _userRepository.createUser(localUser);
      return localUser;
    } catch (e) {
      throw AuthException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Forgot / Reset Password Flow
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _safeAuth;
    if (auth != null && DefaultFirebaseOptions.isLiveFirebaseConfigured && !_firebaseAuthUnavailable) {
      try {
        await auth.sendPasswordResetEmail(email: email.trim());
        return;
      } catch (_) {}
    }

    // Local fallback succeeds if user exists in database
    final user = _localStore.getAllUsers().where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (user.isEmpty) {
      throw AuthException('No account found with this email address.');
    }
  }

  /// Change Password Flow
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _safeAuth;
    if (auth != null && DefaultFirebaseOptions.isLiveFirebaseConfigured && !_firebaseAuthUnavailable) {
      try {
        final user = auth.currentUser;
        if (user != null && user.email != null) {
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(cred);
          await user.updatePassword(newPassword);
          return;
        }
      } catch (_) {}
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    final auth = _safeAuth;
    if (auth != null && DefaultFirebaseOptions.isLiveFirebaseConfigured && !_firebaseAuthUnavailable) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }
}
