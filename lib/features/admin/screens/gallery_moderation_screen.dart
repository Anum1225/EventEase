import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../providers/gallery_provider.dart';

class GalleryModerationScreen extends StatefulWidget {
  const GalleryModerationScreen({super.key});

  @override
  State<GalleryModerationScreen> createState() => _GalleryModerationScreenState();
}

class _GalleryModerationScreenState extends State<GalleryModerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadAllGalleryForAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final galleryProvider = context.watch<GalleryProvider>();
    final mediaList = galleryProvider.adminAllGallery;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Media & Gallery Moderation',
          style: AppTypography.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: galleryProvider.isLoading
          ? const LoadingView(message: 'Loading media catalog...')
          : mediaList.isEmpty
              ? const EmptyStateView(
                  icon: Icons.photo_library_outlined,
                  title: 'No Media Uploads',
                  message: 'No photo uploads currently exist across event galleries.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: mediaList.length,
                  itemBuilder: (context, idx) {
                    final item = mediaList[idx];

                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AppNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.caption ?? 'No caption provided',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor),
                                ),
                                Text(
                                  'By: ${item.uploaderName ?? "User"} • ${DateFormatter.formatShortDate(item.uploadedAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.manrope(fontSize: 10.5, color: secondaryTextColor),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () async {
                                      final confirm = await ConfirmationDialog.show(
                                        context,
                                        title: 'Remove Media?',
                                        message: 'Are you sure you want to permanently delete this photo for policy violation?',
                                        confirmLabel: 'Remove Photo',
                                        isDestructive: true,
                                      );
                                      if (confirm && context.mounted) {
                                        final success = await galleryProvider.deleteMedia(item.id, eventId: item.eventId);
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Photo removed from public gallery.')),
                                          );
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 14, color: isDark ? AppColors.darkError : AppColors.lightError),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Remove',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkError : AppColors.lightError),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
