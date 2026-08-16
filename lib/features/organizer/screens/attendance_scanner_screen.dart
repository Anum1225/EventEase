import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../repositories/attendance_repository.dart';

class AttendanceScannerScreen extends StatefulWidget {
  final String? initialEventId;

  const AttendanceScannerScreen({super.key, this.initialEventId});

  @override
  State<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  String? _selectedEventId;
  bool _isProcessing = false;
  bool _scannerActive = true;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id);
      }
    });
  }

  String? _getEffectiveEventId(List organizerEvents) {
    if (_selectedEventId != null && organizerEvents.any((e) => e.id == _selectedEventId)) {
      return _selectedEventId;
    }
    if (organizerEvents.isNotEmpty) {
      return organizerEvents.first.id;
    }
    return null;
  }

  Future<void> _processCode(String rawValue, String targetEventId) async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final user = authProvider.currentUser;

    if (attendanceProvider.isProcessingScan) return;

    final result = await attendanceProvider.processScannedQr(
      qrPayload: rawValue.trim(),
      currentEventId: targetEventId,
      organizerId: user?.id ?? '',
    );

    if (mounted) {
      _showResultBottomSheet(result);
    } else {
      _isProcessing = false;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final eventProvider = context.read<EventProvider>();
    final organizerEvents = eventProvider.organizerEvents.where((e) => !e.isCancelled).toList();
    final targetId = _getEffectiveEventId(organizerEvents);

    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active event first.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _processCode(rawValue, targetId);
  }

  void _showManualEntryDialog() {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final eventProvider = context.read<EventProvider>();
    final organizerEvents = eventProvider.organizerEvents.where((e) => !e.isCancelled).toList();
    final targetId = _getEffectiveEventId(organizerEvents);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Row(
          children: [
            Icon(
              Icons.dialpad_rounded,
              color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'Manual Pass Check-In',
              style: AppTypography.manrope(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the attendee registration ID or raw QR code token:',
                style: AppTypography.manrope(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: codeController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Registration / QR Code',
                  hintText: 'e.g. reg_001 or EASE-reg_001-...',
                  prefixIcon: Icon(Icons.qr_code_rounded, size: 18),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter a pass code or ID'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final code = codeController.text.trim();
              Navigator.pop(ctx);
              if (targetId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an active event first.')),
                );
                return;
              }
              _processCode(code, targetId);
            },
            child: const Text('Verify & Check In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultBottomSheet(CheckInResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: result.success
                      ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.15)
                      : result.isDuplicate
                          ? (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.success
                      ? Icons.check_circle_rounded
                      : result.isDuplicate
                          ? Icons.warning_rounded
                          : Icons.cancel_rounded,
                  size: 48,
                  color: result.success
                      ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                      : result.isDuplicate
                          ? (isDark ? AppColors.darkWarning : AppColors.lightWarning)
                          : (isDark ? AppColors.darkError : AppColors.lightError),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.success
                    ? 'Check-In Confirmed!'
                    : result.isDuplicate
                        ? 'Duplicate Check-In'
                        : 'Invalid QR Pass',
                style: AppTypography.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: AppTypography.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              if (result.registration != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF3EFE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        result.registration!.userName ?? 'Attendee',
                        style: AppTypography.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        result.registration!.userEmail ?? '',
                        style: AppTypography.manrope(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                text: 'Scan Next Pass',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AttendanceProvider>().clearLastScanResult();
                  setState(() {
                    _isProcessing = false;
                    // Force rebuild the scanner widget
                    _scannerActive = false;
                  });
                  Future.microtask(() {
                    if (mounted) {
                      setState(() => _scannerActive = true);
                    }
                  });
                },
                icon: Icons.qr_code_scanner_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventProvider = context.watch<EventProvider>();
    final organizerEvents = eventProvider.organizerEvents.where((e) => !e.isCancelled).toList();
    final effectiveSelectedId = _getEffectiveEventId(organizerEvents);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Attendance Scanner',
          style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dialpad_rounded),
            tooltip: 'Manual Code Entry',
            onPressed: _showManualEntryDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Event Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : const Color(0xFFF3EFE6),
            child: Row(
              children: [
                const Icon(Icons.event_seat_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: effectiveSelectedId,
                      hint: const Text('Select Event to Scan'),
                      items: organizerEvents.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEventId = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Camera Viewport
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // NO controller passed — widget manages its own camera lifecycle
                // This is the most reliable pattern for mobile_scanner on Android
                if (_scannerActive)
                  MobileScanner(
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.no_photography_rounded,
                                size: 48,
                                color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Camera Not Available',
                                style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Error: ${error.errorDetails?.message ?? error.errorCode.name}\n\nPlease grant camera permission in Settings, then reopen this screen.',
                                textAlign: TextAlign.center,
                                style: AppTypography.manrope(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.dialpad_rounded, size: 18),
                                label: const Text('Enter Pass Code Manually'),
                                onPressed: _showManualEntryDialog,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Viewfinder Target Overlay
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Align QR code inside target box',
                          style: AppTypography.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.dialpad_rounded, size: 16),
                        label: const Text('Manual Entry', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _showManualEntryDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
