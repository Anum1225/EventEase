import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/attendance_model.dart';
import '../models/registration_model.dart';
import '../services/local_data_store.dart';

class CheckInResult {
  final bool success;
  final bool isDuplicate;
  final String message;
  final AttendanceModel? attendance;
  final RegistrationModel? registration;

  const CheckInResult({
    required this.success,
    this.isDuplicate = false,
    required this.message,
    this.attendance,
    this.registration,
  });
}

/// Repository managing QR check-in scanning, duplicate prevention, and attendance stats with dual-engine fallback
class AttendanceRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  AttendanceRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? get _safeFirestore {
    if (_firestore != null) return _firestore;
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      try {
        _firestore = FirebaseFirestore.instance;
        return _firestore;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _attendanceCol =>
      _safeFirestore?.collection(AppConstants.colAttendance);

  CollectionReference<Map<String, dynamic>>? get _regCol =>
      _safeFirestore?.collection(AppConstants.colRegistrations);

  /// Performs QR check-in verification for an event
  Future<CheckInResult> checkInByQrCode({
    required String qrPayload,
    required String currentEventId,
    required String organizerId,
  }) async {
    // 1. Try Firestore First if live credentials configured
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _regCol != null && _attendanceCol != null) {
      try {
        var regSnap = await _regCol!
            .where('qrCode', isEqualTo: qrPayload.trim())
            .limit(1)
            .get();

        RegistrationModel? registration;
        if (regSnap.docs.isNotEmpty) {
          registration = RegistrationModel.fromFirestore(regSnap.docs.first);
        } else {
          final docSnap = await _regCol!.doc(qrPayload.trim()).get();
          if (docSnap.exists) {
            registration = RegistrationModel.fromFirestore(docSnap);
          }
        }

        if (registration != null) {
          final regItem = registration;
          if (currentEventId.isNotEmpty && currentEventId != 'all' && regItem.eventId != currentEventId) {
            // Check if organizer owns this event
            final organizerEvents = _localStore.getEventsByOrganizer(organizerId);
            final ownsEvent = organizerEvents.any((e) => e.id == regItem.eventId);
            if (!ownsEvent) {
              return const CheckInResult(
                success: false,
                message: 'This pass belongs to a different organizer/event.',
              );
            }
          }

          if (registration.status == AppConstants.registrationStatusCancelled) {
            return const CheckInResult(
              success: false,
              message: 'This registration was cancelled.',
            );
          }

          final attendanceSnap = await _attendanceCol!
              .where('registrationId', isEqualTo: registration.id)
              .limit(1)
              .get();

          if (attendanceSnap.docs.isNotEmpty) {
            final existing = AttendanceModel.fromFirestore(attendanceSnap.docs.first);
            return CheckInResult(
              success: false,
              isDuplicate: true,
              message: 'Already checked in for this attendee.',
              attendance: existing,
              registration: registration,
            );
          }

          final attDocRef = _attendanceCol!.doc();
          final newAttendance = AttendanceModel(
            id: attDocRef.id,
            registrationId: registration.id,
            eventId: registration.eventId,
            userId: registration.userId,
            userName: registration.userName,
            userEmail: registration.userEmail,
            attended: true,
            checkedInAt: DateTime.now(),
            checkedInBy: organizerId,
          );

          await attDocRef.set(newAttendance.toMap());

          return CheckInResult(
            success: true,
            message: 'Check-in successful! Welcome, ${registration.userName ?? "Attendee"}.',
            attendance: newAttendance,
            registration: registration,
          );
        }
      } catch (_) {}
    }

    // 2. Seamless local check-in engine
    try {
      final reg = _localStore.getRegistrationByQr(qrPayload.trim());
      if (reg == null) {
        return const CheckInResult(
          success: false,
          message: 'Invalid QR Pass. No matching registration found.',
        );
      }

      if (currentEventId.isNotEmpty && currentEventId != 'all' && reg.eventId != currentEventId) {
        final organizerEvents = _localStore.getEventsByOrganizer(organizerId);
        final ownsEvent = organizerEvents.any((e) => e.id == reg.eventId);
        if (!ownsEvent) {
          return const CheckInResult(
            success: false,
            message: 'This pass belongs to a different organizer/event.',
          );
        }
      }

      final att = _localStore.checkInAttendee(
        qrPayload: qrPayload.trim(),
        hostId: organizerId,
      );

      return CheckInResult(
        success: true,
        message: 'Check-in successful! Welcome, ${reg.userName ?? "Attendee"}.',
        attendance: att,
        registration: reg,
      );
    } catch (e) {
      final isDup = e.toString().contains('ALREADY CHECKED IN');
      return CheckInResult(
        success: false,
        isDuplicate: isDup,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Get attendance record for an individual registration
  Future<AttendanceModel?> getAttendanceForRegistration(String registrationId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _attendanceCol != null) {
      try {
        final snap = await _attendanceCol!
            .where('registrationId', isEqualTo: registrationId)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          return AttendanceModel.fromFirestore(snap.docs.first);
        }
      } catch (_) {}
    }

    final all = _localStore.getEventAttendance('');
    final match = all.where((a) => a.registrationId == registrationId);
    return match.isNotEmpty ? match.first : null;
  }

  Stream<AttendanceModel?> streamAttendanceForRegistration(String registrationId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _attendanceCol != null) {
      return _attendanceCol!
          .where('registrationId', isEqualTo: registrationId)
          .snapshots()
          .map((snap) {
        if (snap.docs.isEmpty) return null;
        return AttendanceModel.fromFirestore(snap.docs.first);
      }).handleError((_) => null);
    }
    return Stream.value(null);
  }

  /// Stream all checked-in attendees for an event
  Stream<List<AttendanceModel>> streamEventAttendance(String eventId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _attendanceCol != null) {
      return _attendanceCol!
          .where('eventId', isEqualTo: eventId)
          .orderBy('checkedInAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => AttendanceModel.fromFirestore(d)).toList())
          .handleError((_) => _localStore.getEventAttendance(eventId));
    }
    return Stream.value(_localStore.getEventAttendance(eventId));
  }

  Future<List<AttendanceModel>> getEventAttendance(String eventId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _attendanceCol != null) {
      try {
        final snap = await _attendanceCol!
            .where('eventId', isEqualTo: eventId)
            .orderBy('checkedInAt', descending: true)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getEventAttendance(eventId);
  }

  /// Fetch all attendance records across the entire app for Admin reporting
  Future<List<AttendanceModel>> getAllAttendance() async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _attendanceCol != null) {
      try {
        final snap = await _attendanceCol!.get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getEventAttendance('');
  }
}
