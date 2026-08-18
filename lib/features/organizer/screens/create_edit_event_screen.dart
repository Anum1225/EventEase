import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/map_location_picker_dialog.dart';
import '../../../models/event_model.dart';
import '../../../repositories/event_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';

class CreateEditEventScreen extends StatefulWidget {
  final String? eventId;

  const CreateEditEventScreen({super.key, this.eventId});

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  late TextEditingController _rulesController;
  late TextEditingController _contactController;

  String _selectedCategory = 'technology';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 16, minute: 0);
  File? _pickedBannerFile;
  Uint8List? _pickedBannerBytes;
  String? _existingBannerUrl;

  EventModel? _existingEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _capacityController = TextEditingController(text: '50');
    _rulesController = TextEditingController();
    _contactController = TextEditingController();

    if (widget.eventId != null) {
      _loadExistingEvent();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _rulesController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTimeOfDay(String? timeStr, TimeOfDay fallback) {
    if (timeStr == null || timeStr.trim().isEmpty) return fallback;
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean.contains('AM') || clean.contains('PM')) {
        final isPm = clean.contains('PM');
        final timePart = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = timePart.split(':');
        if (parts.length >= 2) {
          var hour = int.parse(parts[0].trim());
          final minute = int.parse(parts[1].trim());
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      final parts = clean.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> _loadExistingEvent() async {
    setState(() => _isLoading = true);
    try {
      final repo = EventRepository();
      final ev = await repo.getEventById(widget.eventId!);
      if (ev != null && mounted) {
        setState(() {
          _existingEvent = ev;
          _titleController.text = ev.title;
          _descriptionController.text = ev.description;
          _locationController.text = ev.location;
          _capacityController.text = ev.maxParticipants.toString();
          _rulesController.text = ev.rules ?? '';
          _contactController.text = ev.contactInfo ?? '';
          _selectedCategory = ev.category;
          _selectedDate = ev.date;
          _startTime = _parseTimeOfDay(ev.startTime, _startTime);
          _endTime = _parseTimeOfDay(ev.endTime, _endTime);
          _existingBannerUrl = ev.imageUrl;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBanner() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedBannerBytes = bytes;
        if (!kIsWeb) {
          _pickedBannerFile = File(picked.path);
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 50;
    final startTimeStr = _startTime.format(context);
    final endTimeStr = _endTime.format(context);

    if (widget.eventId != null && _existingEvent != null) {
      // Update Event
      final isMaterial = _existingEvent!.date != _selectedDate ||
          _existingEvent!.location != _locationController.text.trim() ||
          _existingEvent!.maxParticipants != capacity;

      final updated = _existingEvent!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        startTime: startTimeStr,
        endTime: endTimeStr,
        location: _locationController.text.trim(),
        maxParticipants: capacity,
        rules: _rulesController.text.trim().isNotEmpty ? _rulesController.text.trim() : null,
        contactInfo: _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : null,
      );

      final success = await eventProvider.updateEvent(
        event: updated,
        newBannerImageFile: _pickedBannerFile,
        newBannerImageBytes: _pickedBannerBytes,
        isMaterialChange: isMaterial,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMaterial
                ? 'Event updated! Material changes sent for admin re-approval.'
                : 'Event updated successfully.'),
          ),
        );
        context.pop();
      }
    } else {
      // Create Event (Always enters pending_approval per SRS)
      final newEvent = EventModel(
        id: '',
        organizerId: user.id,
        organizerName: user.name,
        organizerEmail: user.email,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        startTime: startTimeStr,
        endTime: endTimeStr,
        location: _locationController.text.trim(),
        maxParticipants: capacity,
        registeredCount: 0,
        status: AppConstants.eventStatusPendingApproval,
        rules: _rulesController.text.trim().isNotEmpty ? _rulesController.text.trim() : null,
        contactInfo: _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      final success = await eventProvider.createEvent(
        event: newEvent,
        bannerImageFile: _pickedBannerFile,
        bannerImageBytes: _pickedBannerBytes,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event submitted! It will appear publicly upon administrator approval.'),
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final eventProvider = context.watch<EventProvider>();

    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading event editor...'));
    }

    final isEditing = widget.eventId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Event' : 'Create New Event',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Image Picker Area
              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE9E6DC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      width: 1.2,
                    ),
                  ),
                  child: _pickedBannerBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_pickedBannerBytes!, fit: BoxFit.cover),
                        )
                      : (_pickedBannerFile != null && !kIsWeb)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_pickedBannerFile!, fit: BoxFit.cover),
                            )
                          : (_existingBannerUrl != null && _existingBannerUrl!.isNotEmpty)
                              ? AppNetworkImage(
                                  imageUrl: _existingBannerUrl!,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(16),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 44,
                                      color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload event cover banner',
                                      style: AppTypography.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    Text(
                                      'Recommended 16:9 ratio (JPEG, PNG)',
                                      style: AppTypography.manrope(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                ),
              ),
              const SizedBox(height: 20),

              // Form fields card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Event Title *',
                      hint: 'e.g. Flutter & AI Hackathon 2026',
                      controller: _titleController,
                      validator: (v) => Validators.required(v, 'Title'),
                    ),
                    const SizedBox(height: 16),

                    // Category Selection
                    Text(
                      'Category *',
                      style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.categories.map((cat) {
                        return CategoryChip(
                          category: cat,
                          isSelected: _selectedCategory == cat,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    AppTextField(
                      label: 'Description *',
                      hint: 'Provide comprehensive event details, agenda, and expectations...',
                      controller: _descriptionController,
                      maxLines: 4,
                      validator: (v) => Validators.required(v, 'Description'),
                    ),
                    const SizedBox(height: 16),

                    // Date & Times
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 480;
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateField(context, isDark),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _buildStartTimeField(context, isDark)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildEndTimeField(context, isDark)),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(flex: 4, child: _buildDateField(context, isDark)),
                            const SizedBox(width: 10),
                            Expanded(flex: 3, child: _buildStartTimeField(context, isDark)),
                            const SizedBox(width: 10),
                            Expanded(flex: 3, child: _buildEndTimeField(context, isDark)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Location / Venue Address *',
                          style: AppTypography.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final chosen = await MapLocationPickerDialog.show(
                              context,
                              initialLocation: _locationController.text.trim(),
                            );
                            if (chosen != null && chosen.isNotEmpty) {
                              setState(() {
                                _locationController.text = chosen;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  size: 15,
                                  color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pick on Google Map',
                                  style: AppTypography.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      hint: 'e.g. Convention Centre, Islamabad (or pick on map)',
                      controller: _locationController,
                      prefixIcon: Icons.location_on_outlined,
                      suffix: IconButton(
                        icon: Icon(
                          Icons.pin_drop_rounded,
                          size: 20,
                          color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                        ),
                        tooltip: 'Open Google Maps Picker',
                        onPressed: () async {
                          final chosen = await MapLocationPickerDialog.show(
                            context,
                            initialLocation: _locationController.text.trim(),
                          );
                          if (chosen != null && chosen.isNotEmpty) {
                            setState(() {
                              _locationController.text = chosen;
                            });
                          }
                        },
                      ),
                      validator: (v) => Validators.required(v, 'Location'),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Maximum Capacity (Seats) *',
                      hint: 'e.g. 100',
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.people_outline_rounded,
                      validator: Validators.positiveNumber,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Rules & Guidelines (Optional)',
                      hint: 'e.g. Photo ID required, laptops needed...',
                      controller: _rulesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Organizer Contact Email (Optional)',
                      hint: 'support@yourorg.com',
                      controller: _contactController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.contact_mail_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: isEditing ? 'Save Changes' : 'Submit for Admin Approval',
                variant: AppButtonVariant.organizer,
                onPressed: _submit,
                isLoading: eventProvider.isLoading,
                icon: isEditing ? Icons.save_rounded : Icons.send_rounded,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final todayMidnight = DateTime(now.year, now.month, now.day);
            final firstSafeDate = _selectedDate.isBefore(todayMidnight)
                ? DateTime(_selectedDate.year - 1, 1, 1)
                : todayMidnight;
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: firstSafeDate,
              lastDate: now.add(const Duration(days: 730)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark
                        ? ColorScheme.dark(
                            primary: AppColors.darkOrganizerAccent,
                            onPrimary: Colors.white,
                            surface: AppColors.darkSurfaceElevated,
                            onSurface: AppColors.darkTextPrimary,
                          )
                        : ColorScheme.light(
                            primary: AppColors.lightOrganizerAccent,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.lightTextPrimary,
                          ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    DateFormatter.formatShortDate(_selectedDate),
                    style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartTimeField(BuildContext context, bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Time *',
          style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _startTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark
                        ? ColorScheme.dark(
                            primary: AppColors.darkOrganizerAccent,
                            onPrimary: Colors.white,
                            surface: AppColors.darkSurfaceElevated,
                            onSurface: AppColors.darkTextPrimary,
                          )
                        : ColorScheme.light(
                            primary: AppColors.lightOrganizerAccent,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.lightTextPrimary,
                          ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _startTime = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _startTime.format(context),
                    style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.access_time_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndTimeField(BuildContext context, bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End Time *',
          style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _endTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark
                        ? ColorScheme.dark(
                            primary: AppColors.darkOrganizerAccent,
                            onPrimary: Colors.white,
                            surface: AppColors.darkSurfaceElevated,
                            onSurface: AppColors.darkTextPrimary,
                          )
                        : ColorScheme.light(
                            primary: AppColors.lightOrganizerAccent,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.lightTextPrimary,
                          ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _endTime = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _endTime.format(context),
                    style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.access_time_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
