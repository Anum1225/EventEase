import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gallery_provider.dart';

class EventGalleryScreen extends StatefulWidget {
  final String eventId;

  const EventGalleryScreen({super.key, required this.eventId});

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadEventGallery(widget.eventId);
    });
  }

  void _showAddPhotoModal(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload photos.')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionController = TextEditingController();
    File? pickedPhoto;
    Uint8List? pickedPhotoBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload Event Memory',
                        style: AppTypography.manrope(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setModalState(() {
                          pickedPhotoBytes = bytes;
                          if (!kIsWeb) {
                            pickedPhoto = File(picked.path);
                          }
                        });
                      }
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF3EFE6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: pickedPhotoBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(pickedPhotoBytes!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded, size: 40, color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to choose photo from device',
                                  style: AppTypography.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: captionController,
                    label: 'Caption / Memory Note (Optional)',
                    hint: 'e.g. Keynote speech moment',
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    text: 'Upload Memory',
                    icon: Icons.cloud_upload_rounded,
                    onPressed: () async {
                      if (pickedPhotoBytes == null && pickedPhoto == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select an image first.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      final success = await context.read<GalleryProvider>().uploadPhoto(
                        eventId: widget.eventId,
                        uploadedBy: user.id,
                        uploaderName: user.name,
                        imageFile: pickedPhoto,
                        imageBytes: pickedPhotoBytes,
                        caption: captionController.text.trim().isNotEmpty ? captionController.text.trim() : null,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Photo added to event gallery! 🎉' : 'Failed to upload photo.'),
                            backgroundColor: success ? AppColors.lightSuccess : AppColors.lightError,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryProvider = context.watch<GalleryProvider>();
    final photos = galleryProvider.getGalleryForEvent(widget.eventId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event Memory Gallery',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded),
            tooltip: 'Add Photo',
            onPressed: () => _showAddPhotoModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPhotoModal(context),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Add Memory'),
      ),
      body: galleryProvider.isLoading
          ? const LoadingView(message: 'Loading photos...')
          : photos.isEmpty
              ? EmptyStateView(
                  icon: Icons.photo_library_outlined,
                  title: 'No Gallery Photos Yet',
                  message: 'Be the first to upload an event photo memory!',
                  actionLabel: 'Upload Photo',
                  onAction: () => _showAddPhotoModal(context),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, idx) {
                    final p = photos[idx];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
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
                                padding: const EdgeInsets.all(8),
                                color: Colors.black.withValues(alpha: 0.65),
                                child: Text(
                                  p.caption!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
