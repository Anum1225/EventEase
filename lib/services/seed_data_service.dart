import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../models/attendance_model.dart';
import '../models/feedback_model.dart';
import '../models/gallery_model.dart';
import 'local_data_store.dart';

/// Seed data service generating full demonstration dataset matching SRS 1.9 checklist
class SeedDataService {
  final FirebaseFirestore _firestore;

  SeedDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Seeds all required demo accounts and realistic event records
  Future<void> seedDatabase() async {
    // 1. Reset Local in-memory repository data
    LocalDataStore().resetToSeedData();

    if (!DefaultFirebaseOptions.isLiveFirebaseConfigured) {
      return;
    }

    try {
      final batch = _firestore.batch();

    // -------------------------------------------------------------
    // 1. DEMO ACCOUNTS (Admin, Organizers, Attendees)
    // -------------------------------------------------------------
    final users = <UserModel>[
      // Admin
      UserModel(
        id: 'admin_001',
        name: 'System Administrator',
        email: 'admin@eventease.com',
        role: AppConstants.roleAdmin,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      // Organizers
      UserModel(
        id: 'org_001',
        name: 'TechSummit Global',
        email: 'organizer1@eventease.com',
        phone: '+1 (555) 234-5678',
        role: AppConstants.roleOrganizer,
        organizerApprovalStatus: 'approved',
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      UserModel(
        id: 'org_002',
        name: 'Creative Workshops Inc.',
        email: 'organizer2@eventease.com',
        phone: '+1 (555) 345-6789',
        role: AppConstants.roleOrganizer,
        organizerApprovalStatus: 'approved',
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        id: 'org_003_pending',
        name: 'Innovate Community Hub',
        email: 'pending_org@eventease.com',
        phone: '+1 (555) 456-7890',
        role: AppConstants.roleOrganizerPending,
        organizerApprovalStatus: 'pending',
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      // Attendees
      UserModel(
        id: 'att_001',
        name: 'Alex Johnson',
        email: 'attendee1@eventease.com',
        phone: '+1 (555) 987-6543',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      UserModel(
        id: 'att_002',
        name: 'Sophia Martinez',
        email: 'attendee2@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      UserModel(
        id: 'att_003',
        name: 'Liam Chen',
        email: 'attendee3@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      UserModel(
        id: 'att_004',
        name: 'Emma Davis',
        email: 'attendee4@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      UserModel(
        id: 'att_005',
        name: 'Noah Wilson',
        email: 'attendee5@eventease.com',
        role: AppConstants.roleAttendee,
        status: AppConstants.userStatusActive,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    for (final user in users) {
      batch.set(_firestore.collection(AppConstants.colUsers).doc(user.id), user.toMap());
    }

    // -------------------------------------------------------------
    // 2. DEMO EVENTS (Approved, Pending, Completed, Cancelled, Rejected)
    // -------------------------------------------------------------
    final now = DateTime.now();
    final events = <EventModel>[
      // 1. Approved - Technology
      EventModel(
        id: 'evt_001_flutter',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'Flutter & AI Mobile Dev Summit 2026',
        description: 'Explore the future of multi-platform engineering, generative UI architectures, and production-scale Flutter apps.',
        category: 'technology',
        date: now.add(const Duration(days: 5)),
        startTime: '10:00 AM',
        endTime: '4:00 PM',
        location: 'Grand Convention Center, Hall B, San Francisco',
        maxParticipants: 100,
        registeredCount: 42,
        status: AppConstants.eventStatusApproved,
        imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1000&q=80',
        rules: 'Bring your laptop, student or government ID. Badges will be issued upon scanning.',
        contactInfo: 'summit@techsummitglobal.io',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      // 2. Approved - Music
      EventModel(
        id: 'evt_002_music',
        organizerId: 'org_002',
        organizerName: 'Creative Workshops Inc.',
        organizerEmail: 'organizer2@eventease.com',
        title: 'Acoustic Sunset Music Festival',
        description: 'An evening of live unplugged acoustic performances, indie musicians, and gourmet food trucks.',
        category: 'music',
        date: now.add(const Duration(days: 8)),
        startTime: '6:00 PM',
        endTime: '11:00 PM',
        location: 'Riverside Amphitheater, Austin, TX',
        maxParticipants: 200,
        registeredCount: 88,
        status: AppConstants.eventStatusApproved,
        imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1000&q=80',
        rules: 'Lawn chairs and blankets allowed. No outside glass containers.',
        contactInfo: 'support@creativesounds.com',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      // 3. Approved - Workshop
      EventModel(
        id: 'evt_003_workshop',
        organizerId: 'org_002',
        organizerName: 'Creative Workshops Inc.',
        organizerEmail: 'organizer2@eventease.com',
        title: 'Mastering Modern UI/UX Prototyping',
        description: 'Hands-on interactive design masterclass on typography hierarchy, design systems, and micro-interactions.',
        category: 'workshop',
        date: now.add(const Duration(days: 12)),
        startTime: '2:00 PM',
        endTime: '5:30 PM',
        location: 'Design Lab Studios, Room 402, Seattle, WA',
        maxParticipants: 30,
        registeredCount: 29, // Near capacity!
        status: AppConstants.eventStatusApproved,
        imageUrl: 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?auto=format&fit=crop&w=1000&q=80',
        rules: 'Figma pre-installed on personal laptop.',
        contactInfo: 'workshops@designlab.com',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      // 4. Approved - Sports
      EventModel(
        id: 'evt_004_sports',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'City Marathon & 5K Charity Fun Run',
        description: 'Annual community marathon supporting regional pediatric healthcare. Open to all runners.',
        category: 'sports',
        date: now.add(const Duration(days: 15)),
        startTime: '7:00 AM',
        endTime: '12:00 PM',
        location: 'Downtown Waterfront Park, Chicago, IL',
        maxParticipants: 500,
        registeredCount: 150,
        status: AppConstants.eventStatusApproved,
        imageUrl: 'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3?auto=format&fit=crop&w=1000&q=80',
        rules: 'Bib pickup starts 6:00 AM. Hydration stations every 1 mile.',
        contactInfo: 'run@citymarathon.org',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      // 5. Pending Approval (For Admin approval testing)
      EventModel(
        id: 'evt_005_pending',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'Cloud Native & DevOps Symposium',
        description: 'Deep dive into Kubernetes architecture, multi-cloud networking, and distributed observability.',
        category: 'conference',
        date: now.add(const Duration(days: 22)),
        startTime: '9:00 AM',
        endTime: '5:00 PM',
        location: 'Tech Hub Auditorium, Boston, MA',
        maxParticipants: 150,
        registeredCount: 0,
        status: AppConstants.eventStatusPendingApproval,
        imageUrl: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      // 6. Completed Event (With real Attendance & Feedback for Reports)
      EventModel(
        id: 'evt_006_completed',
        organizerId: 'org_001',
        organizerName: 'TechSummit Global',
        organizerEmail: 'organizer1@eventease.com',
        title: 'Global Tech Leaders Expo 2026',
        description: 'Keynotes from world-renowned technology innovators and industry founders.',
        category: 'technology',
        date: now.subtract(const Duration(days: 10)),
        startTime: '9:00 AM',
        endTime: '6:00 PM',
        location: 'Moscone Center, San Francisco, CA',
        maxParticipants: 80,
        registeredCount: 65,
        status: AppConstants.eventStatusCompleted,
        imageUrl: 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      // 7. Cancelled Event
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
        cancellationReason: 'Adverse weather forecast and severe storm warnings.',
        imageUrl: 'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      // 8. Rejected Event
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
        rejectionReason: 'Event violates community guidelines regarding financial advisory guarantees.',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=1000&q=80',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    ];

    for (final event in events) {
      batch.set(_firestore.collection(AppConstants.colEvents).doc(event.id), event.toMap());
    }

    // -------------------------------------------------------------
    // 3. DEMO REGISTRATIONS & QR CODES
    // -------------------------------------------------------------
    final registrations = <RegistrationModel>[
      // Alex Johnson (att_001) registered for Flutter Summit
      RegistrationModel(
        id: 'reg_001',
        eventId: 'evt_001_flutter',
        userId: 'att_001',
        userName: 'Alex Johnson',
        userEmail: 'attendee1@eventease.com',
        eventTitle: 'Flutter & AI Mobile Dev Summit 2026',
        eventDate: now.add(const Duration(days: 5)),
        eventLocation: 'Grand Convention Center, Hall B, San Francisco',
        eventBanner: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=1000&q=80',
        eventCategory: 'technology',
        registeredAt: now.subtract(const Duration(days: 4)),
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg_001-DEMOPASS1',
      ),
      // Alex Johnson (att_001) completed registration on Completed Event
      RegistrationModel(
        id: 'reg_002',
        eventId: 'evt_006_completed',
        userId: 'att_001',
        userName: 'Alex Johnson',
        userEmail: 'attendee1@eventease.com',
        eventTitle: 'Global Tech Leaders Expo 2026',
        eventDate: now.subtract(const Duration(days: 10)),
        eventLocation: 'Moscone Center, San Francisco, CA',
        eventBanner: 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&w=1000&q=80',
        eventCategory: 'technology',
        registeredAt: now.subtract(const Duration(days: 35)),
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg_002-CHECKEDIN1',
      ),
      // Sophia Martinez (att_002) completed registration on Completed Event
      RegistrationModel(
        id: 'reg_003',
        eventId: 'evt_006_completed',
        userId: 'att_002',
        userName: 'Sophia Martinez',
        userEmail: 'attendee2@eventease.com',
        eventTitle: 'Global Tech Leaders Expo 2026',
        eventDate: now.subtract(const Duration(days: 10)),
        eventLocation: 'Moscone Center, San Francisco, CA',
        eventBanner: 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&w=1000&q=80',
        eventCategory: 'technology',
        registeredAt: now.subtract(const Duration(days: 34)),
        status: AppConstants.registrationStatusRegistered,
        qrCode: 'EASE-reg_003-CHECKEDIN2',
      ),
    ];

    for (final reg in registrations) {
      batch.set(_firestore.collection(AppConstants.colRegistrations).doc(reg.id), reg.toMap());
    }

    // -------------------------------------------------------------
    // 4. DEMO ATTENDANCE CHECK-INS
    // -------------------------------------------------------------
    final attendanceRecords = <AttendanceModel>[
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

    for (final att in attendanceRecords) {
      batch.set(_firestore.collection(AppConstants.colAttendance).doc(att.id), att.toMap());
    }

    // -------------------------------------------------------------
    // 5. DEMO FEEDBACK (For Statistics calculation)
    // -------------------------------------------------------------
    final feedbacks = <FeedbackModel>[
      FeedbackModel(
        id: 'att_001_evt_006_completed',
        eventId: 'evt_006_completed',
        userId: 'att_001',
        userName: 'Alex Johnson',
        rating: 5,
        comment: 'Incredible speaker lineup and seamless event organization!',
        submittedAt: now.subtract(const Duration(days: 9)),
      ),
      FeedbackModel(
        id: 'att_002_evt_006_completed',
        eventId: 'evt_006_completed',
        userId: 'att_002',
        userName: 'Sophia Martinez',
        rating: 5,
        comment: 'Top quality production. The workshops were extremely practical.',
        submittedAt: now.subtract(const Duration(days: 9, hours: 4)),
      ),
    ];

    for (final fb in feedbacks) {
      batch.set(_firestore.collection(AppConstants.colFeedback).doc(fb.id), fb.toMap());
    }

    // -------------------------------------------------------------
    // 6. DEMO GALLERY MEMORIES
    // -------------------------------------------------------------
    final galleryItems = <GalleryModel>[
      GalleryModel(
        id: 'gal_001',
        eventId: 'evt_006_completed',
        uploadedBy: 'org_001',
        uploaderName: 'TechSummit Global',
        imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1000&q=80',
        caption: 'Opening Keynote on Distributed AI Systems',
        uploadedAt: now.subtract(const Duration(days: 9)),
      ),
      GalleryModel(
        id: 'gal_002',
        eventId: 'evt_006_completed',
        uploadedBy: 'org_001',
        uploaderName: 'TechSummit Global',
        imageUrl: 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?auto=format&fit=crop&w=1000&q=80',
        caption: 'Attendee networking lounge & coffee break',
        uploadedAt: now.subtract(const Duration(days: 9)),
      ),
    ];

    for (final gal in galleryItems) {
      batch.set(_firestore.collection(AppConstants.colGallery).doc(gal.id), gal.toMap());
    }

    // Commit entire seed batch atomically
    await batch.commit();
    } catch (_) {}
  }
}
