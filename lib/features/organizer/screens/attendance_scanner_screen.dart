import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
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
  late final MobileScannerController _scannerController;
  final ImagePicker _picker = ImagePicker();

  String? _selectedEventId;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id);
      }
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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

  Future<void> _pickImageAndScan() async {
    final eventProvider = context.read<EventProvider>();
    final organizerEvents = eventProvider.organizerEvents.where((e) => !e.isCancelled).toList();
    final targetId = _getEffectiveEventId(organizerEvents);

    if (targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active event first.')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (!kIsWeb) {
        try {
          final BarcodeCapture? barcodes = await _scannerController.analyzeImage(image.path);
          if (barcodes != null && barcodes.barcodes.isNotEmpty) {
            final rawValue = barcodes.barcodes.first.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              setState(() => _isProcessing = true);
              _processCode(rawValue, targetId);
              return;
            }
          }
        } catch (_) {}
      }

      // On Web or fallback: open seamless fast pass check-in dialog
      if (mounted) {
        _showManualEntryDialog(initialHint: image.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''));
      }
    } catch (e) {
      if (mounted) {
        _showManualEntryDialog();
      }
    }
  }

  void _showManualEntryDialog({String? initialHint}) {
    final codeController = TextEditingController(text: (initialHint != null && initialHint.contains('EASE')) ? initialHint : '');
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
                'Enter attendee registration ID or raw QR code token:',
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
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppColors.darkTextSecondary : const Color(0xFF4F46E5),
            ),
            child: Text(
              'Cancel',
              style: AppTypography.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4F46E5),
              ),
            ),
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
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Scan QR from Photo',
            onPressed: _pickImageAndScan,
          ),
          IconButton(
            icon: const Icon(Icons.dialpad_rounded),
            tooltip: 'Manual Code Entry',
            onPressed: _showManualEntryDialog,
          ),
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            tooltip: 'Toggle Flashlight',
            onPressed: () async {
              try {
                await _scannerController.toggleTorch();
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
              } catch (_) {}
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Switch Camera',
            onPressed: () async {
              try {
                await _scannerController.switchCamera();
              } catch (_) {}
            },
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
                MobileScanner(
                  controller: _scannerController,
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
                              'Camera Preview Unavailable',
                              style: AppTypography.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ensure camera permissions are enabled, or select a pass screenshot from gallery.',
                              textAlign: TextAlign.center,
                              style: AppTypography.manrope(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                                  label: const Text('Pick Image'),
                                  onPressed: _pickImageAndScan,
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.dialpad_rounded, size: 18),
                                  label: const Text('Manual Entry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _showManualEntryDialog,
                                ),
                              ],
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Gallery QR', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: _pickImageAndScan,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.dialpad_rounded, size: 16),
                            label: const Text('Manual Entry', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: _showManualEntryDialog,
                          ),
                        ],
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
