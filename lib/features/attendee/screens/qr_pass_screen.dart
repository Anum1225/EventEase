import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/qr_pass_card.dart';
import '../../../models/registration_model.dart';
import '../../../models/attendance_model.dart';
import '../../../repositories/registration_repository.dart';
import '../../../repositories/attendance_repository.dart';

class QRPassScreen extends StatefulWidget {
  final String registrationId;

  const QRPassScreen({super.key, required this.registrationId});

  @override
  State<QRPassScreen> createState() => _QRPassScreenState();
}

class _QRPassScreenState extends State<QRPassScreen> {
  final _registrationRepo = RegistrationRepository();
  final _attendanceRepo = AttendanceRepository();

  RegistrationModel? _registration;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPass();
  }

  Future<void> _loadPass() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reg = await _registrationRepo.getRegistrationById(widget.registrationId);
      if (reg != null) {
        _registration = reg;
      } else {
        _errorMessage = 'Ticket pass not found.';
      }
    } catch (e) {
      _errorMessage = 'Failed to load pass: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Event Pass',
          style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/attendee/my-events');
            }
          },
        ),
      ),
      body: _isLoading
          ? const LoadingView(message: 'Generating your ticket pass...')
          : _errorMessage != null || _registration == null
              ? Center(
                  child: Text(_errorMessage ?? 'Pass not available'),
                )
              : StreamBuilder<AttendanceModel?>(
                  stream: _attendanceRepo.streamAttendanceForRegistration(_registration!.id),
                  builder: (context, snapshot) {
                    final attendance = snapshot.data;
                    final hasAttended = attendance != null && attendance.attended;

                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              'Present this QR code at venue entrance for check-in',
                              textAlign: TextAlign.center,
                              style: AppTypography.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // The Signature Ticket Stub Pass Card
                            QRPassCard(
                              eventTitle: _registration!.eventTitle ?? 'Event Pass',
                              bannerUrl: _registration!.eventBanner,
                              eventDate: _registration!.eventDate,
                              location: _registration!.eventLocation,
                              attendeeName: _registration!.userName ?? 'Valued Attendee',
                              qrCodePayload: _registration!.qrCode,
                              registrationId: _registration!.id,
                              hasAttended: hasAttended,
                              checkedInAt: attendance?.checkedInAt,
                              category: _registration!.eventCategory,
                            ),

                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : const Color(0xFFEFECE4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Unique anti-duplicate security token encoded directly into ticket pass QR.',
                                      style: AppTypography.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
