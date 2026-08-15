import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../repositories/user_repository.dart';

/// Service managing FCM Push Notifications and background message handling
class NotificationService {
  FirebaseMessaging? _fcm;
  final UserRepository _userRepository;

  NotificationService({
    FirebaseMessaging? fcm,
    UserRepository? userRepository,
  })  : _fcm = fcm,
        _userRepository = userRepository ?? UserRepository();

  FirebaseMessaging? get _safeFcm {
    if (_fcm != null) return _fcm;
    try {
      _fcm = FirebaseMessaging.instance;
      return _fcm;
    } catch (_) {
      return null;
    }
  }

  /// Initialize FCM token registration and notification handlers
  Future<void> initialize(String userId) async {
    try {
      final fcm = _safeFcm;
      if (fcm == null) return;

      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await fcm.getToken();
        if (token != null) {
          await _userRepository.updateFcmToken(userId, token);
        }

        // Listen for token refreshes
        fcm.onTokenRefresh.listen((newToken) {
          _userRepository.updateFcmToken(userId, newToken);
        });
      }

      // Foreground message listener
      try {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Foreground message received: ${message.notification?.title}');
          }
        });
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) {
        print('FCM initialization notice: $e');
      }
    }
  }
}
