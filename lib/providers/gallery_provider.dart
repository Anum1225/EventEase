import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/gallery_model.dart';
import '../repositories/gallery_repository.dart';
import '../services/storage_service.dart';

/// State management for Event Photo Memories and Admin Moderation
class GalleryProvider with ChangeNotifier {
  final GalleryRepository _galleryRepository;
  final StorageService _storageService;

  final Map<String, List<GalleryModel>> _eventGalleries = {};
  List<GalleryModel> _adminAllGallery = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  GalleryProvider({
    GalleryRepository? galleryRepository,
    StorageService? storageService,
  })  : _galleryRepository = galleryRepository ?? GalleryRepository(),
        _storageService = storageService ?? StorageService();

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  List<GalleryModel> get adminAllGallery => _adminAllGallery;

  List<GalleryModel> getGalleryForEvent(String eventId) => _eventGalleries[eventId] ?? [];

  Future<void> loadEventGallery(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photos = await _galleryRepository.getEventGallery(eventId);
      _eventGalleries[eventId] = photos;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load photos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto({
    required String eventId,
    required String uploadedBy,
    String? uploaderName,
    File? imageFile,
    Uint8List? imageBytes,
    String? caption,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageUrl = await _storageService.uploadGalleryImage(
        eventId: eventId,
        imageFile: imageFile,
        imageBytes: imageBytes,
        uploaderId: uploadedBy,
      );

      await _galleryRepository.uploadPhoto(
        eventId: eventId,
        uploadedBy: uploadedBy,
        uploaderName: uploaderName,
        imageUrl: imageUrl,
        caption: caption,
      );

      await loadEventGallery(eventId);
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload photo: ${e.toString()}';
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Admin: Load all photos system-wide for moderation
  Future<void> loadAllGalleryForAdmin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _adminAllGallery = await _galleryRepository.getAllGalleryMedia();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load gallery for moderation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin: Delete inappropriate photo
  Future<bool> deleteMedia(String mediaId, {String? eventId}) async {
    try {
      await _galleryRepository.deleteMedia(mediaId);
      _adminAllGallery.removeWhere((g) => g.id == mediaId);
      if (eventId != null && _eventGalleries.containsKey(eventId)) {
        _eventGalleries[eventId]!.removeWhere((g) => g.id == mediaId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete photo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
