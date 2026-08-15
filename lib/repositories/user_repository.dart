import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../services/local_data_store.dart';

/// Repository managing user profiles and role moderation with cloud & local data fallback
class UserRepository {
  FirebaseFirestore? _firestore;
  final LocalDataStore _localStore = LocalDataStore();

  UserRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

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

  CollectionReference<Map<String, dynamic>>? get _usersCol =>
      _safeFirestore?.collection(AppConstants.colUsers);

  Future<UserModel?> getUser(String userId) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        final doc = await _usersCol!.doc(userId).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromFirestore(doc);
        }
      } catch (_) {}
    }
    return _localStore.getUserById(userId);
  }

  Stream<UserModel?> streamUser(String userId) {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      return _usersCol!.doc(userId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return _localStore.getUserById(userId);
        }
        return UserModel.fromFirestore(doc);
      }).handleError((_) => _localStore.getUserById(userId));
    }
    return Stream.value(_localStore.getUserById(userId));
  }

  Future<void> createUser(UserModel user) async {
    _localStore.updateUser(user);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(user.id).set(user.toMap());
      } catch (_) {}
    }
  }

  Future<void> updateUser(UserModel user) async {
    _localStore.updateUser(user);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(user.id).update(user.toMap());
      } catch (_) {}
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
    String? phone,
    String? profileImage,
  }) async {
    final existing = await getUser(userId);
    if (existing != null) {
      final updated = existing.copyWith(
        name: name,
        phone: phone ?? existing.phone,
        profileImage: profileImage ?? existing.profileImage,
      );
      _localStore.updateUser(updated);
    }
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        final data = <String, dynamic>{'name': name};
        if (phone != null) data['phone'] = phone;
        if (profileImage != null) data['profileImage'] = profileImage;
        await _usersCol!.doc(userId).update(data);
      } catch (_) {}
    }
  }

  Future<void> updateNotificationPreferences(
    String userId,
    Map<String, bool> preferences,
  ) async {
    final existing = await getUser(userId);
    if (existing != null) {
      final updated = existing.copyWith(notificationPreferences: preferences);
      _localStore.updateUser(updated);
    }
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(userId).update({
          'notificationPreferences': preferences,
        });
      } catch (_) {}
    }
  }

  Future<void> updateFcmToken(String userId, String? token) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(userId).update({'fcmToken': token});
      } catch (_) {}
    }
  }

  /// Admin: Fetch all users with optional role and search query
  Future<List<UserModel>> getAllUsers({String? role, String? query}) async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        Query<Map<String, dynamic>> q = _usersCol!.orderBy('createdAt', descending: true);
        if (role != null && role.isNotEmpty) {
          q = q.where('role', isEqualTo: role);
        }
        final snap = await q.get();
        if (snap.docs.isNotEmpty) {
          final users = snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
          if (query != null && query.trim().isNotEmpty) {
            final qLower = query.trim().toLowerCase();
            return users.where((u) =>
                u.name.toLowerCase().contains(qLower) ||
                u.email.toLowerCase().contains(qLower)).toList();
          }
          return users;
        }
      } catch (_) {}
    }
    return _localStore.getAllUsers(role: role, query: query);
  }

  /// Admin: Fetch pending organizer applicants
  Future<List<UserModel>> getPendingOrganizers() async {
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        final snap = await _usersCol!
            .where('role', isEqualTo: AppConstants.roleOrganizerPending)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        }
      } catch (_) {}
    }
    return _localStore.getPendingOrganizers();
  }

  /// Admin: Approve organizer application
  Future<void> approveOrganizer(String userId) async {
    _localStore.approveOrganizer(userId);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(userId).update({
          'role': AppConstants.roleOrganizer,
          'organizerApprovalStatus': 'approved',
        });
      } catch (_) {}
    }
  }

  /// Admin: Reject organizer application
  Future<void> rejectOrganizer(String userId, String reason) async {
    _localStore.rejectOrganizer(userId, reason);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(userId).update({
          'role': AppConstants.roleAttendee,
          'organizerApprovalStatus': 'rejected',
          'organizerApprovalReason': reason,
        });
      } catch (_) {}
    }
  }

  /// Admin: Activate or Deactivate user account
  Future<void> toggleUserStatus(String userId, bool deactivate) async {
    _localStore.toggleUserStatus(userId, deactivate);
    if (DefaultFirebaseOptions.isLiveFirebaseConfigured && _usersCol != null) {
      try {
        await _usersCol!.doc(userId).update({
          'status': deactivate ? AppConstants.userStatusDeactivated : AppConstants.userStatusActive,
        });
      } catch (_) {}
    }
  }
}
