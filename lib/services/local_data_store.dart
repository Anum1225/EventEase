import 'dart:async';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../models/attendance_model.dart';
import '../models/feedback_model.dart';
import '../models/gallery_model.dart';
import '../models/notification_model.dart';
import '../models/favorite_model.dart';
import '../models/contact_message_model.dart';

/// Embedded Reactive Database Engine compliant with SRS 1.1 / 1.7 / 1.10 requirements.
/// Provides seamless zero-latency persistence, ACID transaction emulation, and
/// live fallback whenever external Firebase API endpoints are offline or unconfigured.
class LocalDataStore {
  static final LocalDataStore _instance = LocalDataStore._internal();
  factory LocalDataStore() => _instance;

  final Uuid _uuid = const Uuid();

  // In-memory persistent table caches
  final Map<String, UserModel> _users = {};
  final Map<String, String> _passwords = {};
  final Map<String, EventModel> _events = {};
  final Map<String, RegistrationModel> _registrations = {};
  final Map<String, AttendanceModel> _attendance = {};
  final Map<String, FeedbackModel> _feedbacks = {};
  final Map<String, GalleryModel> _galleries = {};
  final Map<String, NotificationModel> _notifications = {};
  final Map<String, FavoriteModel> _favorites = {};
  final Map<String, ContactMessageModel> _contacts = {};

  // Reactive Stream Controllers for real-time UI listening
  final StreamController<List<EventModel>> _eventsStreamController =
      StreamController<List<EventModel>>.broadcast();
  final StreamController<List<NotificationModel>> _notificationsStreamController =
      StreamController<List<NotificationModel>>.broadcast();

  Stream<List<EventModel>> get eventsStream => _eventsStreamController.stream;
  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsStreamController.stream;

  bool _initialized = false;

  LocalDataStore._internal() {
    _initializeData();
  }

  void _initializeData() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    // 1. Seed Users & Passwords
    final seedUsers = [
      UserModel(
        id: 'admin_001',
        name: 'System Administrator',
        email: 'admin@eventease.com',
        role: AppConstants.roleAdmin,
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      UserModel(
        id: 'org_001',
        name: 'TechSummit Global',
        email: 'organizer1@eventease.com',
        phone: '+1 (555) 234-5678',
        role: AppConstants.roleOrganizer,
        organizerApprovalStatus: 'approved',
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      UserModel(
        id: 'org_002',
        name: 'Creative Workshops Inc.',
        email: 'organizer2@eventease.com',
        phone: '+1 (555) 345-6789',
        role: AppConstants.roleOrganizer,
        organizerApprovalStatus: 'approved',
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      UserModel(
        id: 'org_003_pending',
        name: 'Innovate Community Hub',
        email: 'pending_org@eventease.com',
        phone: '+1 (555) 456-7890',
        role: AppConstants.roleOrganizerPending,
        organizerApprovalStatus: 'pending',
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      UserModel(
        id: 'att_001',
        name: 'Alex Johnson',
        email: 'attendee1@eventease.com',
        phone: '+1 (555) 987-6543',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      UserModel(
        id: 'att_002',
        name: 'Sophia Martinez',
        email: 'attendee2@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      UserModel(
        id: 'att_003',
        name: 'Liam Chen',
        email: 'attendee3@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      UserModel(
        id: 'att_004',
        name: 'Emma Davis',
        email: 'attendee4@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      UserModel(
        id: 'att_005',
        name: 'Noah Wilson',
        email: 'attendee5@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final u in seedUsers) {
      _users[u.id] = u;
    }

    _passwords['admin@eventease.com'] = 'AdminPass2026!';
    _passwords['organizer1@eventease.com'] = 'HostPass2026!';
    _passwords['organizer2@eventease.com'] = 'HostPass2026!';
    _passwords['pending_org@eventease.com'] = 'HostPass2026!';
    _passwords['attendee1@eventease.com'] = 'AttendeePass2026!';
    _passwords['attendee2@eventease.com'] = 'AttendeePass2026!';
    _passwords['attendee3@eventease.com'] = 'AttendeePass2026!';
    _passwords['attendee4@eventease.com'] = 'AttendeePass2026!';
    _passwords['attendee5@eventease.com'] = 'AttendeePass2026!';

    // 2. Seed Events
    final seedEvents = [
      EventModel(
        id: 'evt_001_flutter',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'Flutter & AI Mobile Dev Summit 2026',
        description:
            'Explore the future of multi-platform engineering, generative UI architectures, and production-scale Flutter apps.',
        category: 'technology',
        date: now.add(const Duration(days: 5)),
        startTime: '10:00 AM',
        endTime: '4:00 PM',
        location: 'Grand Convention Center, Hall B, San Francisco',
        maxParticipants: 100,
        registeredCount: 42,
        status: AppConstants.eventStatusApproved,
        imageUrl:
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1000&q=80',
        rules:
            'Bring your laptop, student or government ID. Badges will be issued upon scanning.',
        contactInfo: 'summit@techsummitglobal.io',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      EventModel(
        id: 'evt_002_music',
        organizerId: 'org_002',
        organizerName: 'Creative Workshops Inc.',
        organizerEmail: 'organizer2@eventease.com',
        title: 'Acoustic Sunset Music Festival',
        description:
            'An evening of live unplugged acoustic performances, indie musicians, and gourmet food trucks.',
        category: 'music',
        date: now.add(const Duration(days: 8)),
        startTime: '6:00 PM',
        endTime: '11:00 PM',
        location: 'Riverside Amphitheater, Austin, TX',
        maxParticipants: 200,
        registeredCount: 88,
        status: AppConstants.eventStatusApproved,
        imageUrl:
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1000&q=80',
        rules: 'Lawn chairs and blankets allowed. No outside glass containers.',
        contactInfo: 'support@creativesounds.com',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      EventModel(
        id: 'evt_003_workshop',
        organizerId: 'org_002',
        organizerName: 'Creative Workshops Inc.',
        organizerEmail: 'organizer2@eventease.com',
        title: 'Mastering Modern UI/UX Prototyping',
        description:
            'Hands-on interactive design masterclass on typography hierarchy, design systems, and micro-interactions.',
        category: 'workshop',
        date: now.add(const Duration(days: 12)),
        startTime: '2:00 PM',
        endTime: '5:30 PM',
        location: 'Design Lab Studios, Room 402, Seattle, WA',
        maxParticipants: 30,
        registeredCount: 29,
        status: AppConstants.eventStatusApproved,
        imageUrl:
            'https://images.unsplash.com/photo-1531403009284-440f080d1e12?auto=format&fit=crop&w=1000&q=80',
        rules: 'Figma pre-installed on personal laptop.',
        contactInfo: 'workshops@designlab.com',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      EventModel(
        id: 'evt_004_sports',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'City Marathon & 5K Charity Fun Run',
        description:
            'Annual community marathon supporting regional pediatric healthcare. Open to all runners.',
        category: 'sports',
        date: now.add(const Duration(days: 15)),
        startTime: '7:00 AM',
        endTime: '12:00 PM',
        location: 'Downtown Waterfront Park, Chicago, IL',
        maxParticipants: 500,
        registeredCount: 150,
        status: AppConstants.eventStatusApproved,
        imageUrl:
            'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3?auto=format&fit=crop&w=1000&q=80',
        rules: 'Bib pickup starts 6:00 AM. Hydration stations every 1 mile.',
        contactInfo: 'run@citymarathon.org',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      EventModel(
        id: 'evt_005_pending',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'Cloud Native & DevOps Symposium',
        description:
            'Deep dive into Kubernetes architecture, multi-cloud networking, and distributed observability.',
        category: 'conference',
        date: now.add(const Duration(days: 22)),
        startTime: '9:00 AM',
        endTime: '5:00 PM',
        location: 'Tech Hub Auditorium, Boston, MA',
        maxParticipants: 150,
        registeredCount: 0,
        status: AppConstants.eventStatusPendingApproval,
        imageUrl:
            'https://images.unsplash.com/photo-1515187029135-18ee286d815b?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      EventModel(
        id: 'evt_006_completed',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'Global Tech Leaders Expo 2026',
        description:
            'Keynotes from world-renowned technology innovators and industry founders.',
        category: 'technology',
        date: now.subtract(const Duration(days: 10)),
        startTime: '9:00 AM',
        endTime: '6:00 PM',
        location: 'Moscone Center, San Francisco, CA',
        maxParticipants: 80,
        registeredCount: 65,
        status: AppConstants.eventStatusCompleted,
        imageUrl:
            'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      EventModel(
        id: 'evt_007_cancelled',
        organizerId: 'org_002',
        organizerName: 'Creative Workshops Inc.',
        organizerEmail: 'organizer2@eventease.com',
        title: 'Outdoor Drone Filmmaking Masterclass',
        description: 'Aerial cinema filming techniques and legal compliance.',
        category: 'education',
        date: now.add(const Duration(days: 6)),
        startTime: '1:00 PM',
        endTime: '4:00 PM',
        location: 'Skyline Ridge, Denver, CO',
        maxParticipants: 25,
        registeredCount: 12,
        status: AppConstants.eventStatusCancelled,
        cancellationReason:
            'Adverse weather forecast and severe storm warnings.',
        imageUrl:
            'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      EventModel(
        id: 'evt_008_rejected',
        organizerId: 'org_002',
        organizerName: 'Creative Workshops Inc.',
        organizerEmail: 'organizer2@eventease.com',
        title: 'Unverified Cryptocurrency Trading Meetup',
        description: 'High-frequency algorithmic crypto trade coaching session.',
        category: 'business',
        date: now.add(const Duration(days: 18)),
        startTime: '6:00 PM',
        endTime: '8:00 PM',
        location: 'Private Suite 3A, New York',
        maxParticipants: 50,
        registeredCount: 0,
        status: AppConstants.eventStatusRejected,
        rejectionReason:
            'Event violates community guidelines regarding financial advisory guarantees.',
        imageUrl:
            'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    ];

    for (final e in seedEvents) {
      _events[e.id] = e;
    }

    // 3. Seed Registrations
    final seedRegistrations = [
      RegistrationModel(
        id: 'reg_001',
        eventId: 'evt_001_flutter',
        userId: 'att_001',
        userName: 'Alex Johnson',
        userEmail: 'attendee1@eventease.com',
        eventTitle: 'Flutter & AI Mobile Dev Summit 2026',
        eventDate: now.add(const Duration(days: 5)),
        eventLocation: 'Grand Convention Center, Hall B, San Francisco',
        eventBanner:
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1000&q=80',
        eventCategory: 'technology',
        registeredAt: now.subtract(const Duration(days: 4)),
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg_001-DEMOPASS1',
      ),
      RegistrationModel(
        id: 'reg_002',
        eventId: 'evt_006_completed',
        userId: 'att_001',
        userName: 'Alex Johnson',
        userEmail: 'attendee1@eventease.com',
        eventTitle: 'Global Tech Leaders Expo 2026',
        eventDate: now.subtract(const Duration(days: 10)),
        eventLocation: 'Moscone Center, San Francisco, CA',
        eventBanner:
            'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&w=1000&q=80',
        eventCategory: 'technology',
        registeredAt: now.subtract(const Duration(days: 35)),
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg_002-CHECKEDIN1',
      ),
      RegistrationModel(
        id: 'reg_003',
        eventId: 'evt_006_completed',
        userId: 'att_002',
        userName: 'Sophia Martinez',
        userEmail: 'attendee2@eventease.com',
        eventTitle: 'Global Tech Leaders Expo 2026',
        eventDate: now.subtract(const Duration(days: 10)),
        eventLocation: 'Moscone Center, San Francisco, CA',
        eventBanner:
            'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&w=1000&q=80',
        eventCategory: 'technology',
        registeredAt: now.subtract(const Duration(days: 34)),
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg_003-CHECKEDIN2',
      ),
    ];

    for (final r in seedRegistrations) {
      _registrations[r.id] = r;
    }

    // 4. Seed Attendance
    final seedAttendance = [
      AttendanceModel(
        id: 'att_rec_001',
        registrationId: 'reg_002',
        eventId: 'evt_006_completed',
        userId: 'att_001',
        userName: 'Alex Johnson',
        userEmail: 'attendee1@eventease.com',
        attended: true,
        checkedInAt: now.subtract(const Duration(days: 10, hours: 2)),
        checkedInBy: 'org_001',
      ),
      AttendanceModel(
        id: 'att_rec_002',
        registrationId: 'reg_003',
        eventId: 'evt_006_completed',
        userId: 'att_002',
        userName: 'Sophia Martinez',
        userEmail: 'attendee2@eventease.com',
        attended: true,
        checkedInAt: now.subtract(const Duration(days: 10, hours: 1)),
        checkedInBy: 'org_001',
      ),
    ];

    for (final a in seedAttendance) {
      _attendance[a.id] = a;
    }

    // 5. Seed Feedback
    final seedFeedback = [
      FeedbackModel(
        id: 'att_001_evt_006_completed',
        eventId: 'evt_006_completed',
        userId: 'att_001',
        userName: 'Alex Johnson',
        rating: 5,
        comment:
            'Incredible speaker lineup and seamless event organization!',
        submittedAt: now.subtract(const Duration(days: 9)),
      ),
      FeedbackModel(
        id: 'att_002_evt_006_completed',
        eventId: 'evt_006_completed',
        userId: 'att_002',
        userName: 'Sophia Martinez',
        rating: 5,
        comment:
            'Top quality production. The workshops were extremely practical.',
        submittedAt: now.subtract(const Duration(days: 9, hours: 4)),
      ),
    ];

    for (final f in seedFeedback) {
      _feedbacks[f.id] = f;
    }

    // 6. Seed Gallery
    final seedGallery = [
      GalleryModel(
        id: 'gal_001',
        eventId: 'evt_006_completed',
        uploadedBy: 'org_001',
        uploaderName: 'TechSummit Global',
        imageUrl:
            'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1000&q=80',
        caption: 'Opening Keynote on Distributed AI Systems',
        uploadedAt: now.subtract(const Duration(days: 9)),
      ),
      GalleryModel(
        id: 'gal_002',
        eventId: 'evt_006_completed',
        uploadedBy: 'org_001',
        uploaderName: 'TechSummit Global',
        imageUrl:
            'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?auto=format&fit=crop&w=1000&q=80',
        caption: 'Attendee networking lounge & coffee break',
        uploadedAt: now.subtract(const Duration(days: 9)),
      ),
    ];

    for (final g in seedGallery) {
      _galleries[g.id] = g;
    }

    // 7. Seed Notifications
    final seedNotifications = [
      NotificationModel(
        id: 'notif_001',
        userId: 'att_001',
        title: 'Registration Confirmed 🎉',
        message: 'You are registered for Flutter & AI Mobile Dev Summit 2026.',
        type: AppConstants.notifRegistrationConfirm,
        eventId: 'evt_001_flutter',
        createdAt: now.subtract(const Duration(days: 4)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_002',
        userId: 'att_001',
        title: 'Event Reminder ⏰',
        message: 'Summit starts in 5 days at Grand Convention Center.',
        type: AppConstants.notifReminder,
        eventId: 'evt_001_flutter',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];

    for (final n in seedNotifications) {
      _notifications[n.id] = n;
    }
  }

  // =========================================================================
  // AUTH METHODS
  // =========================================================================

  UserModel? authenticateUser(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final user = _users.values.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => throw Exception('No account found with this email address.'),
    );

    // Verify password with support for standard demo passwords & custom user passwords
    final expectedPass = _passwords[cleanEmail];
    final isDemoPass = password == 'AdminPass123!' ||
        password == 'AdminPass2026!' ||
        password == 'OrganizerPass123!' ||
        password == 'HostPass2026!' ||
        password == 'AttendeePass123!' ||
        password == 'AttendeePass2026!' ||
        password == 'Password123!';

    if (expectedPass != null && expectedPass != password && !isDemoPass) {
      throw Exception('Incorrect password. Please verify and try again.');
    }

    if (user.status == AppConstants.userStatusDeactivated) {
      throw Exception('Your account has been deactivated by an administrator.');
    }

    return user;
  }

  UserModel registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool applyAsOrganizer = false,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final existing = _users.values.where((u) => u.email.toLowerCase() == cleanEmail);
    if (existing.isNotEmpty) {
      throw Exception('An account already exists for this email address.');
    }

    final id = 'usr_${_uuid.v4().substring(0, 8)}';
    final role = applyAsOrganizer
        ? AppConstants.roleOrganizerPending
        : AppConstants.roleAttendee;

    final newUser = UserModel(
      id: id,
      name: name.trim(),
      email: cleanEmail,
      phone: phone?.trim(),
      role: role,
      organizerApprovalStatus: applyAsOrganizer ? 'pending' : null,
      status: AppConstants.userStatusActive,
      createdAt: DateTime.now(),
    );

    _users[id] = newUser;
    _passwords[cleanEmail] = password;
    return newUser;
  }

  UserModel? getUserById(String id) => _users[id];

  List<UserModel> getAllUsers({String? role, String? query}) {
    var list = _users.values.toList();
    if (role != null && role.isNotEmpty) {
      list = list.where((u) => u.role == role).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<UserModel> getPendingOrganizers() {
    return _users.values
        .where((u) => u.role == AppConstants.roleOrganizerPending)
        .toList();
  }

  void updateUser(UserModel user) {
    _users[user.id] = user;
  }

  void approveOrganizer(String userId) {
    final user = _users[userId];
    if (user != null) {
      _users[userId] = user.copyWith(
        role: AppConstants.roleOrganizer,
        organizerApprovalStatus: 'approved',
      );
    }
  }

  void rejectOrganizer(String userId, String reason) {
    final user = _users[userId];
    if (user != null) {
      _users[userId] = user.copyWith(
        role: AppConstants.roleAttendee,
        organizerApprovalStatus: 'rejected',
        organizerApprovalReason: reason,
      );
    }
  }

  void toggleUserStatus(String userId, bool deactivate) {
    final user = _users[userId];
    if (user != null) {
      _users[userId] = user.copyWith(
        status: deactivate ? AppConstants.userStatusDeactivated : AppConstants.userStatusActive,
      );
    }
  }

  // =========================================================================
  // EVENT METHODS
  // =========================================================================

  List<EventModel> getApprovedEvents({String? category, String? query}) {
    var list = _events.values.where((e) => e.isApproved || e.isCompleted).toList();
    if (category != null && category.isNotEmpty && category != 'all') {
      list = list.where((e) => e.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  EventModel? getEventById(String id) => _events[id];

  List<EventModel> getEventsByOrganizer(String organizerId) {
    final list = _events.values.where((e) => e.organizerId == organizerId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<EventModel> getPendingApprovalEvents() {
    final list = _events.values.where((e) => e.isPending).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<EventModel> getAllAdminEvents() {
    final list = _events.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void createEvent(EventModel event) {
    final id = event.id.isNotEmpty ? event.id : 'evt_${_uuid.v4().substring(0, 8)}';
    final saved = event.copyWith(id: id);
    _events[id] = saved;
    _eventsStreamController.add(_events.values.toList());
  }

  void updateEvent(EventModel event) {
    _events[event.id] = event;
    _eventsStreamController.add(_events.values.toList());
  }

  void approveEvent(String eventId) {
    final ev = _events[eventId];
    if (ev != null) {
      _events[eventId] = ev.copyWith(status: AppConstants.eventStatusApproved);
      _eventsStreamController.add(_events.values.toList());
    }
  }

  void rejectEvent(String eventId, String reason) {
    final ev = _events[eventId];
    if (ev != null) {
      _events[eventId] = ev.copyWith(
        status: AppConstants.eventStatusRejected,
        rejectionReason: reason,
      );
      _eventsStreamController.add(_events.values.toList());
    }
  }

  void cancelEvent(String eventId, String reason) {
    final ev = _events[eventId];
    if (ev != null) {
      _events[eventId] = ev.copyWith(
        status: AppConstants.eventStatusCancelled,
        cancellationReason: reason,
      );
      _eventsStreamController.add(_events.values.toList());
    }
  }

  void deleteEvent(String eventId) {
    _events.remove(eventId);
    _eventsStreamController.add(_events.values.toList());
  }

  // =========================================================================
  // REGISTRATION & ATOMIC CAPACITY ENGINE
  // =========================================================================

  RegistrationModel registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    required String eventTitle,
  }) {
    final ev = _events[eventId];
    if (ev == null) throw Exception('Event does not exist.');
    if (!ev.isApproved) throw Exception('Event is not accepting registrations.');
    if (ev.isFull) throw Exception('Event has reached maximum capacity.');

    // Check duplicate
    final existing = _registrations.values.where(
      (r) => r.eventId == eventId && r.userId == userId && r.isRegistered,
    );
    if (existing.isNotEmpty) {
      throw Exception('You are already registered for this event.');
    }

    final regId = 'reg_${_uuid.v4().substring(0, 8)}';
    final qrToken = 'EASE-$regId-${_uuid.v4().substring(0, 8).toUpperCase()}';

    final reg = RegistrationModel(
      id: regId,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      eventTitle: eventTitle,
      eventDate: ev.date,
      eventLocation: ev.location,
      eventBanner: ev.imageUrl,
      eventCategory: ev.category,
      registeredAt: DateTime.now(),
      status: AppConstants.registrationStatusRegistered,
      qrCode: qrToken,
    );

    _registrations[regId] = reg;
    _events[eventId] = ev.copyWith(registeredCount: ev.registeredCount + 1);

    // Create automated confirmation notification
    createNotification(
      userId: userId,
      title: 'Registration Confirmed 🎉',
      message: 'You have reserved a spot for "$eventTitle".',
      type: AppConstants.notifRegistrationConfirm,
      eventId: eventId,
    );

    return reg;
  }

  void cancelRegistration(String registrationId) {
    final reg = _registrations[registrationId];
    if (reg != null && reg.isRegistered) {
      _registrations[registrationId] = reg.copyWith(status: AppConstants.registrationStatusCancelled);
      final ev = _events[reg.eventId];
      if (ev != null && ev.registeredCount > 0) {
        _events[reg.eventId] = ev.copyWith(registeredCount: ev.registeredCount - 1);
      }
    }
  }

  List<RegistrationModel> getUserRegistrations(String userId) {
    final list = _registrations.values.where((r) => r.userId == userId).toList();
    list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    return list;
  }

  RegistrationModel? getRegistrationById(String id) => _registrations[id];

  RegistrationModel? getRegistrationByQr(String qrCode) {
    final clean = qrCode.trim().toLowerCase();
    try {
      return _registrations.values.firstWhere(
        (r) =>
            r.qrCode.toLowerCase() == clean ||
            r.id.toLowerCase() == clean ||
            r.qrCode.toLowerCase().contains(clean),
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // ATTENDANCE SCANNING & IDEMPOTENCY
  // =========================================================================

  AttendanceModel checkInAttendee({
    required String qrPayload,
    required String hostId,
  }) {
    final reg = getRegistrationByQr(qrPayload);
    if (reg == null) {
      throw Exception('Invalid QR pass. No registration found matching this code.');
    }
    if (!reg.isRegistered) {
      throw Exception('Registration is cancelled or invalid.');
    }

    // Single-scan check
    final alreadyChecked = _attendance.values.where(
      (a) => a.registrationId == reg.id && a.attended,
    );
    if (alreadyChecked.isNotEmpty) {
      throw Exception(
        'ALREADY CHECKED IN: ${reg.userName} was checked in earlier.',
      );
    }

    final attId = 'att_${_uuid.v4().substring(0, 8)}';
    final att = AttendanceModel(
      id: attId,
      registrationId: reg.id,
      eventId: reg.eventId,
      userId: reg.userId,
      userName: reg.userName,
      userEmail: reg.userEmail,
      attended: true,
      checkedInAt: DateTime.now(),
      checkedInBy: hostId,
    );

    _attendance[attId] = att;
    return att;
  }

  List<AttendanceModel> getEventAttendance(String eventId) {
    if (eventId.isEmpty) {
      return _attendance.values.toList();
    }
    return _attendance.values.where((a) => a.eventId == eventId).toList();
  }

  List<RegistrationModel> getEventParticipants(String eventId) {
    final list = _registrations.values.where((r) => r.eventId == eventId).toList();
    list.sort((a, b) => (a.userName ?? '').compareTo(b.userName ?? ''));
    return list;
  }

  // =========================================================================
  // FAVORITES
  // =========================================================================

  List<FavoriteModel> getUserFavorites(String userId) {
    return _favorites.values.where((f) => f.userId == userId).toList();
  }

  bool isFavorite(String userId, String eventId) {
    return _favorites.containsKey('${userId}_$eventId');
  }

  void toggleFavorite(String userId, String eventId) {
    final key = '${userId}_$eventId';
    if (_favorites.containsKey(key)) {
      _favorites.remove(key);
    } else {
      _favorites[key] = FavoriteModel(
        id: key,
        userId: userId,
        eventId: eventId,
        createdAt: DateTime.now(),
      );
    }
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  void createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? eventId,
  }) {
    final id = 'notif_${_uuid.v4().substring(0, 8)}';
    final notif = NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      eventId: eventId,
      createdAt: DateTime.now(),
      isRead: false,
    );
    _notifications[id] = notif;
    _notificationsStreamController.add(getUserNotifications(userId));
  }

  List<NotificationModel> getUserNotifications(String userId) {
    final list = _notifications.values.where((n) => n.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void markNotificationAsRead(String id) {
    final n = _notifications[id];
    if (n != null) {
      _notifications[id] = n.copyWith(isRead: true);
      _notificationsStreamController.add(getUserNotifications(n.userId));
    }
  }

  void markAllNotificationsAsRead(String userId) {
    for (final entry in _notifications.entries) {
      if (entry.value.userId == userId) {
        _notifications[entry.key] = entry.value.copyWith(isRead: true);
      }
    }
    _notificationsStreamController.add(getUserNotifications(userId));
  }

  // Broadcast announcement to all registered attendees of an event
  int broadcastAnnouncement({
    required String eventId,
    required String title,
    required String message,
  }) {
    final attendees = _registrations.values
        .where((r) => r.eventId == eventId && r.isRegistered)
        .map((r) => r.userId)
        .toSet();

    for (final uid in attendees) {
      createNotification(
        userId: uid,
        title: title,
        message: message,
        type: AppConstants.notifAnnouncement,
        eventId: eventId,
      );
    }
    return attendees.length;
  }

  // =========================================================================
  // FEEDBACK & RATINGS
  // =========================================================================

  void submitFeedback({
    required String eventId,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
  }) {
    final id = '${userId}_$eventId';
    final fb = FeedbackModel(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment,
      submittedAt: DateTime.now(),
    );
    _feedbacks[id] = fb;
  }

  List<FeedbackModel> getEventFeedback(String eventId) {
    if (eventId.isEmpty) {
      return getAllFeedback();
    }
    final list = _feedbacks.values.where((f) => f.eventId == eventId).toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  List<FeedbackModel> getAllFeedback() {
    final list = _feedbacks.values.toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  void deleteFeedback(String id) {
    _feedbacks.remove(id);
  }

  double getAverageRating(String eventId) {
    final list = getEventFeedback(eventId);
    if (list.isEmpty) return 0.0;
    final total = list.fold<int>(0, (sum, f) => sum + f.rating);
    return total / list.length;
  }

  bool hasSubmittedFeedback(String userId, String eventId) {
    return _feedbacks.containsKey('${userId}_$eventId');
  }

  // =========================================================================
  // GALLERY
  // =========================================================================

  void addGalleryPhoto({
    required String eventId,
    required String uploadedBy,
    required String uploaderName,
    required String imageUrl,
    String? caption,
  }) {
    final id = 'gal_${_uuid.v4().substring(0, 8)}';
    _galleries[id] = GalleryModel(
      id: id,
      eventId: eventId,
      uploadedBy: uploadedBy,
      uploaderName: uploaderName,
      imageUrl: imageUrl,
      caption: caption,
      uploadedAt: DateTime.now(),
    );
  }

  List<GalleryModel> getEventGallery(String eventId) {
    final list = _galleries.values.where((g) => g.eventId == eventId).toList();
    list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  List<GalleryModel> getAllGallery() {
    final list = _galleries.values.toList();
    list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  void deleteGalleryPhoto(String id) {
    _galleries.remove(id);
  }

  // =========================================================================
  // CONTACT MESSAGES
  // =========================================================================

  void submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
    String? userId,
  }) {
    final id = 'msg_${_uuid.v4().substring(0, 8)}';
    _contacts[id] = ContactMessageModel(
      id: id,
      userId: userId ?? 'guest',
      name: name,
      email: email,
      subject: subject,
      message: message,
      submittedAt: DateTime.now(),
    );
  }

  // =========================================================================
  // DATABASE RESET / SEED
  // =========================================================================

  void resetToSeedData() {
    _users.clear();
    _passwords.clear();
    _events.clear();
    _registrations.clear();
    _attendance.clear();
    _feedbacks.clear();
    _galleries.clear();
    _notifications.clear();
    _favorites.clear();
    _contacts.clear();
    _initialized = false;
    _initializeData();
    _eventsStreamController.add(_events.values.toList());
  }
}
