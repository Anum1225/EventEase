import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../providers/gallery_provider.dart';

class EventGalleryScreen extends StatefulWidget {
  final String eventId;

  const EventGalleryScreen({super.key, required this.eventId});

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadEventGallery(widget.eventId);
    });
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
      ),
      body: galleryProvider.isLoading
          ? const LoadingView(message: 'Loading photos...')
          : photos.isEmpty
              ? const EmptyStateView(
                  icon: Icons.photo_library_outlined,
                  title: 'No Gallery Photos Yet',
                  message: 'The organizer hasn’t uploaded any event photos yet.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
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
