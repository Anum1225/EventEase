import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/registration_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/registration_repository.dart';

/// State management for Organizer Attendance Scanner and Participant Rosters
class AttendanceProvider with ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final RegistrationRepository _registrationRepository;

  List<RegistrationModel> _eventParticipants = [];
  List<AttendanceModel> _eventAttendance = [];
  CheckInResult? _lastScanResult;
  bool _isProcessingScan = false;
  bool _isLoading = false;
  String? _errorMessage;

  AttendanceProvider({
    AttendanceRepository? attendanceRepository,
    RegistrationRepository? registrationRepository,
  })  : _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _registrationRepository = registrationRepository ?? RegistrationRepository();

  List<RegistrationModel> get eventParticipants => _eventParticipants;
  List<AttendanceModel> get eventAttendance => _eventAttendance;
  CheckInResult? get lastScanResult => _lastScanResult;
  bool get isProcessingScan => _isProcessingScan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalRegistered => _eventParticipants.where((p) => p.isRegistered).length;
  int get totalCheckedIn => _eventAttendance.length;
  double get attendanceRate => totalRegistered > 0 ? (totalCheckedIn / totalRegistered) * 100 : 0.0;

  bool isAttendeeCheckedIn(String registrationId) {
    return _eventAttendance.any((a) => a.registrationId == registrationId);
  }

  /// Load participants and attendance records for an organizer event
  Future<void> loadEventParticipants(String eventId, [List<String>? organizerEventIds]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final participantsFuture = _registrationRepository.getEventParticipants(eventId, organizerEventIds);
      final attendanceFuture = _attendanceRepository.getEventAttendance(eventId);

      final results = await Future.wait([participantsFuture, attendanceFuture]);
      _eventParticipants = results[0] as List<RegistrationModel>;
      _eventAttendance = results[1] as List<AttendanceModel>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load participants: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process camera QR code scan
  Future<CheckInResult> processScannedQr({
    required String qrPayload,
    required String currentEventId,
    required String organizerId,
  }) async {
    if (_isProcessingScan) {
      return const CheckInResult(
        success: false,
        message: 'Processing previous scan...',
      );
    }

    _isProcessingScan = true;
    notifyListeners();

    try {
      final result = await _attendanceRepository.checkInByQrCode(
        qrPayload: qrPayload,
        currentEventId: currentEventId,
        organizerId: organizerId,
      );

      _lastScanResult = result;
      if (result.success && result.attendance != null) {
        _eventAttendance.insert(0, result.attendance!);
      }

      _isProcessingScan = false;
      notifyListeners();
      return result;
    } catch (e) {
      final errorResult = CheckInResult(
        success: false,
        message: 'Scanner error: ${e.toString()}',
      );
      _lastScanResult = errorResult;
      _isProcessingScan = false;
      notifyListeners();
      return errorResult;
    }
  }

  void clearLastScanResult() {
    _lastScanResult = null;
    notifyListeners();
  }
}
