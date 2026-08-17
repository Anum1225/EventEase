import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/contact_message_model.dart';
import '../services/local_data_store.dart';

/// Repository managing Contact Us form submissions with dual-engine fallback
class ContactRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  ContactRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? get _safeFirestore {
    if (_firestore != null) return _firestore;
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      try {
        _firestore = FirebaseFirestore.instance;
        return _firestore;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _contactCol =>
      _safeFirestore?.collection(AppConstants.colContactMessages);

  Future<void> submitMessage({
    String? userId,
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    _localStore.submitContactMessage(
      userId: userId,
      name: name,
      email: email,
      subject: subject,
      message: message,
    );

    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _contactCol != null) {
      try {
        final docRef = _contactCol!.doc();
        final item = ContactMessageModel(
          id: docRef.id,
          userId: userId,
          name: name,
          email: email,
          subject: subject,
          message: message,
          submittedAt: DateTime.now(),
          status: 'new',
        );
        await docRef.set(item.toMap());
      } catch (_) {}
    }
  }

  Future<List<ContactMessageModel>> getAllMessages() async {
    List<ContactMessageModel> list = [];
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _contactCol != null) {
      try {
        final snap = await _contactCol!.orderBy('submittedAt', descending: true).get().timeout(const Duration(milliseconds: 2000));
        if (snap.docs.isNotEmpty) {
          list = snap.docs.map((d) => ContactMessageModel.fromFirestore(d)).toList();
        }
      } catch (_) {}
    }
    final localList = _localStore.getAllContactMessages();
    for (final loc in localList) {
      if (!list.any((d) => d.id == loc.id)) {
        list.add(loc);
      }
    }
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }
}
