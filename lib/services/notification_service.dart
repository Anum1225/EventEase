import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../repositories/user_repository.dart';

/// Service managing FCM Push Notifications and background message handling with stream broadcasting
class NotificationService {
  FirebaseMessaging? _fcm;
  final UserRepository _userRepository;
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  NotificationService({
    FirebaseMessaging? fcm,
    UserRepository? userRepository,
  })  : _fcm = fcm,
        _userRepository = userRepository ?? UserRepository();

  Stream<RemoteMessage> get onForegroundMessage => _messageStreamController.stream;

  FirebaseMessaging? get _safeFcm {
    if (_fcm != null) return _fcm;
    try {
      _fcm = FirebaseMessaging.instance;
      return _fcm;
    } catch (_) {
      return null;
    }
  }

  /// Initialize FCM token registration and stream notification handlers
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

      // Foreground message listener streaming into broadcast controller
      try {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('FCM Foreground message stream received: ${message.notification?.title}');
          }
          if (!_messageStreamController.isClosed) {
            _messageStreamController.add(message);
          }
        });
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) {
        print('FCM initialization notice: $e');
      }
    }
  }

  void dispose() {
    _messageStreamController.close();
  }
}
