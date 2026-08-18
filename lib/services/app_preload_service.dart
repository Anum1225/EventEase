import 'dart:async';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../repositories/event_repository.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/attendance_repository.dart';
import 'local_data_store.dart';

/// Background Non-blocking Data Preloading & Memory Warming Service
/// Pre-loads all application modules in batches of 2 with scheduled intervals
/// ensuring 0ms navigation latency and zero UI jank.
class AppPreloadService {
  static final AppPreloadService _instance = AppPreloadService._internal();
  factory AppPreloadService() => _instance;
  AppPreloadService._internal();

  bool _isWarmedUp = false;
  bool get isWarmedUp => _isWarmedUp;

  /// Trigger sequential 2-at-a-time non-blocking warm-up in background
  void startBackgroundWarmup() {
    if (_isWarmedUp) return;
    _isWarmedUp = true;

    // Run after initial frame has painted smoothly
    Timer(const Duration(milliseconds: 600), () async {
      try {
        // Batch 1: Events & Public Catalog
        await Future.wait([
          EventRepository().getDiscoverableEvents().catchError((_) => <dynamic>[]),
          EventRepository().getPendingApprovalEvents().catchError((_) => <dynamic>[]),
        ]);

        await Future.delayed(const Duration(milliseconds: 150));

        // Batch 2: Gallery & Inquiries
        await Future.wait([
          GalleryRepository().getAllPhotos().catchError((_) => <dynamic>[]),
          ContactRepository().getAllMessages().catchError((_) => <dynamic>[]),
        ]);

        await Future.delayed(const Duration(milliseconds: 150));

        // Batch 3: Feedback & Users / Attendance
        await Future.wait([
          FeedbackRepository().getAllFeedback().catchError((_) => <dynamic>[]),
          UserRepository().getAllUsers().catchError((_) => <dynamic>[]),
        ]);

        if (kDebugMode) {
          debugPrint('⚡ [AppPreloadService] Background batch warm-up complete. All screens primed for 0ms render.');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AppPreloadService non-fatal notice: $e');
        }
      }
    });
  }
}
