import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contact_message_model.dart';
import '../repositories/contact_repository.dart';

/// State management for Contact Us form submission and Organizer attendee inquiry stream
class ContactProvider with ChangeNotifier {
  final ContactRepository _contactRepository;
  StreamSubscription<List<ContactMessageModel>>? _messagesSub;

  List<ContactMessageModel> _messages = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  ContactProvider({ContactRepository? contactRepository})
      : _contactRepository = contactRepository ?? ContactRepository() {
    _messages = _contactRepository.getAllMessagesLocal();
    _subscribeToMessages();
  }

  List<ContactMessageModel> get messages => _messages;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void _subscribeToMessages() {
    _messagesSub?.cancel();
    _messagesSub = _contactRepository.streamAllMessages().listen((list) {
      _messages = list;
      notifyListeners();
    }, onError: (_) {});
  }

  Future<bool> submitMessage({
    String? userId,
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _contactRepository.submitMessage(
        userId: userId,
        name: name,
        email: email,
        subject: subject,
        message: message,
      );
      _messages = _contactRepository.getAllMessagesLocal();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAllMessages() async {
    _messages = _contactRepository.getAllMessagesLocal();
    notifyListeners();
    try {
      _messages = await _contactRepository.getAllMessages();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}
