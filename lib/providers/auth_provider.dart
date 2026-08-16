import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

/// State management for authentication, user session, and role checking
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;
  final StorageService _storageService;
  final NotificationService _notificationService;

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthProvider({
    AuthService? authService,
    UserRepository? userRepository,
    StorageService? storageService,
    NotificationService? notificationService,
  })  : _authService = authService ?? AuthService(),
        _userRepository = userRepository ?? UserRepository(),
        _storageService = storageService ?? StorageService(),
        _notificationService = notificationService ?? NotificationService() {
    _init();
  }

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  String get role => _currentUser?.role ?? '';
  bool get isOrganizerPending => _currentUser?.role == 'organizer_pending';
  bool get isAttendee => _currentUser?.role == 'attendee';
  bool get isOrganizer => _currentUser?.role == 'organizer';
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> _init() async {
    await _restoreSession();

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      _authService.authStateChanges.listen((firebaseUser) async {
        if (firebaseUser == null) {
          if (_currentUser == null) {
            _status = AuthStatus.unauthenticated;
            notifyListeners();
          }
        } else {
          await refreshUser(firebaseUser.uid);
        }
      });
    } else if (_currentUser == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<SharedPreferences?> _getSafePrefs() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return null;
      }
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await _getSafePrefs();
      if (prefs == null) return;
      final savedUserJson = prefs.getString('auth_current_user');
      final savedUserId = prefs.getString('auth_current_user_id');

      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(savedUserJson);
        final user = UserModel.fromMap(map, savedUserId ?? (map['id'] as String? ?? ''));
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _notificationService.initialize(user.id);
        notifyListeners();
      } else if (savedUserId != null && savedUserId.isNotEmpty) {
        final user = await _userRepository.getUser(savedUserId);
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;
          _notificationService.initialize(user.id);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AuthProvider restoreSession note: $e');
    }
  }

  Future<void> _saveSession(UserModel? user) async {
    try {
      final prefs = await _getSafePrefs();
      if (prefs == null) return;
      if (user == null) {
        await prefs.remove('auth_current_user');
        await prefs.remove('auth_current_user_id');
      } else {
        await prefs.setString('auth_current_user_id', user.id);
        final jsonMap = <String, dynamic>{
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
          'organizerApprovalStatus': user.organizerApprovalStatus,
          'organizerApprovalReason': user.organizerApprovalReason,
          'profileImage': user.profileImage,
          'status': user.status,
          'createdAt': user.createdAt.toIso8601String(),
          'fcmToken': user.fcmToken,
          'notificationPreferences': user.notificationPreferences,
        };
        await prefs.setString('auth_current_user', jsonEncode(jsonMap));
      }
    } catch (e) {
      debugPrint('AuthProvider saveSession error: $e');
    }
  }

  Future<void> refreshUser([String? uid]) async {
    final targetUid = uid ?? _currentUser?.id ?? _authService.currentUser?.uid;
    if (targetUid == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final user = await _userRepository.getUser(targetUid);
      _currentUser = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      if (user != null) {
        await _saveSession(user);
        _notificationService.initialize(user.id);
      }
    } catch (e) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signIn(email: email, password: password);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      await _saveSession(user);
      _notificationService.initialize(user.id);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool applyAsOrganizer = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        applyAsOrganizer: applyAsOrganizer,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      await _saveSession(user);
      _notificationService.initialize(user.id);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        userEmail: _currentUser?.email,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    File? newProfileImageFile,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _clearError();

    try {
      String? imageUrl = _currentUser!.profileImage;
      if (newProfileImageFile != null) {
        imageUrl = await _storageService.uploadProfileImage(
          userId: _currentUser!.id,
          imageFile: newProfileImageFile,
        );
      }

      await _userRepository.updateProfile(
        userId: _currentUser!.id,
        name: name,
        phone: phone,
        profileImage: imageUrl,
      );

      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        profileImage: imageUrl,
      );
      await _saveSession(_currentUser);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> updateNotificationPreferences(Map<String, bool> prefs) async {
    if (_currentUser == null) return;
    try {
      await _userRepository.updateNotificationPreferences(_currentUser!.id, prefs);
      _currentUser = _currentUser!.copyWith(notificationPreferences: prefs);
      await _saveSession(_currentUser);
      notifyListeners();
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> logout() async {
    await _saveSession(null);
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Direct injection method for testing
  void setCurrentUserForTesting(UserModel? user) {
    _currentUser = user;
    _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }
}
