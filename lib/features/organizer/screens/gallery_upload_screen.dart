import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/gallery_provider.dart';

class GalleryUploadScreen extends StatefulWidget {
  final String? initialEventId;

  const GalleryUploadScreen({super.key, this.initialEventId});

  @override
  State<GalleryUploadScreen> createState() => _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  String? _selectedEventId;
  File? _pickedPhoto;
  Uint8List? _pickedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<EventProvider>().loadOrganizerEvents(user.id, user.email).then((_) {
          if (!mounted) return;
          final events = context.read<EventProvider>().organizerEvents;
          final effectiveId = _getEffectiveEventId(events);
          if (effectiveId != null) {
            setState(() => _selectedEventId = effectiveId);
            context.read<GalleryProvider>().loadEventGallery(effectiveId);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String? _getEffectiveEventId(List<EventModel> events) {
    if (_selectedEventId != null && events.any((e) => e.id == _selectedEventId)) {
      return _selectedEventId;
    }
    if (events.isNotEmpty) {
      return events.first.id;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedPhotoBytes = bytes;
        if (!kIsWeb) {
          _pickedPhoto = File(picked.path);
        }
      });
    }
  }

  void _upload() async {
    final events = context.read<EventProvider>().organizerEvents;
    final effectiveId = _getEffectiveEventId(events);

    if ((_pickedPhotoBytes == null && _pickedPhoto == null) || effectiveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event and pick a photo.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final galleryProvider = context.read<GalleryProvider>();
    final success = await galleryProvider.uploadPhoto(
      eventId: effectiveId,
      uploadedBy: user.id,
      uploaderName: user.name,
      imageFile: _pickedPhoto,
      imageBytes: _pickedPhotoBytes,
      caption: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
    );

    if (success && mounted) {
      setState(() {
        _pickedPhoto = null;
        _pickedPhotoBytes = null;
        _captionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded to event gallery!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final events = context.watch<EventProvider>().organizerEvents;
    final galleryProvider = context.watch<GalleryProvider>();
    final effectiveSelectedId = _getEffectiveEventId(events);
    final photos = effectiveSelectedId != null ? galleryProvider.getGalleryForEvent(effectiveSelectedId) : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event Gallery Upload',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Selector Dropdown
            if (events.isNotEmpty)
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: effectiveSelectedId,
                decoration: const InputDecoration(
                  labelText: 'Select Event',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: events.map((e) {
                  return DropdownMenuItem(
                    value: e.id,
                    child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedEventId = val);
                  if (val != null) {
                    galleryProvider.loadEventGallery(val);
                  }
                },
              ),
            const SizedBox(height: 20),

            // Photo Upload Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEFECE4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                      ),
                      child: _pickedPhotoBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_pickedPhotoBytes!, fit: BoxFit.cover),
                            )
                          : (_pickedPhoto != null && !kIsWeb)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_pickedPhoto!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 40,
                                      color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap to choose memory photo',
                                      style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Caption (Optional)',
                    hint: 'e.g. Keynote Q&A Session',
                    controller: _captionController,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Upload Photo',
                    variant: AppButtonVariant.organizer,
                    onPressed: _upload,
                    isLoading: galleryProvider.isUploading,
                    icon: Icons.cloud_upload_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Existing Photos Grid
            Text(
              'Uploaded Photos (${photos.length})',
              style: AppTypography.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),

            if (galleryProvider.isLoading)
              const LoadingView(message: 'Loading photos...')
            else if (photos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No photos uploaded yet for this event.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: photos.length,
                itemBuilder: (context, idx) {
                  final p = photos[idx];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          imageUrl: p.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        if (p.caption != null && p.caption!.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              color: Colors.black.withValues(alpha: 0.6),
                              child: Text(
                                p.caption!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () async {
                              final confirm = await ConfirmationDialog.show(
                                context,
                                title: 'Delete Photo?',
                                message: 'Are you sure you want to remove this photo from the event gallery?',
                                confirmLabel: 'Delete',
                                isDestructive: true,
                              );
                              if (confirm && context.mounted) {
                                await galleryProvider.deleteMedia(p.id, eventId: effectiveSelectedId);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
