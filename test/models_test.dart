import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/models/user_model.dart';
import 'package:eventease/models/event_model.dart';
import 'package:eventease/models/registration_model.dart';
import 'package:eventease/models/attendance_model.dart';
import 'package:eventease/models/feedback_model.dart';
import 'package:eventease/core/constants/app_constants.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel serialization and role getters', () {
      final user = UserModel(
        id: 'u-123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        role: AppConstants.roleOrganizer,
        status: AppConstants.userStatusActive,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.isOrganizer, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.isAttendee, isFalse);

      final map = user.toMap();
      expect(map['email'], 'jane@example.com');
      expect(map['role'], 'organizer');

      final fromMap = UserModel.fromMap(map, 'u-123');
      expect(fromMap.name, 'Jane Doe');
      expect(fromMap.id, 'u-123');
    });
  });

  group('EventModel Tests', () {
    test('Event capacity and status helper getters', () {
      final event = EventModel(
        id: 'ev-1',
        organizerId: 'org-1',
        title: 'Tech Summit',
        description: 'Annual flagship conference',
        category: 'technology',
        date: DateTime(2026, 9, 15),
        startTime: '09:00 AM',
        endTime: '05:00 PM',
        location: 'Hall A',
        maxParticipants: 100,
        registeredCount: 95,
        status: AppConstants.eventStatusApproved,
        createdAt: DateTime.now(),
      );

      expect(event.isApproved, isTrue);
      expect(event.isPending, isFalse);
      expect(event.isFull, isFalse);
      expect(event.remainingSeats, 5);

      final fullEvent = event.copyWith(registeredCount: 100);
      expect(fullEvent.isFull, isTrue);
      expect(fullEvent.remainingSeats, 0);
    });

    test('Event serialization to and from map', () {
      final now = DateTime(2026, 8, 20, 10, 0);
      final event = EventModel(
        id: 'ev-2',
        organizerId: 'org-2',
        title: 'Art Showcase',
        description: 'Gallery event',
        category: 'arts_culture',
        date: now,
        startTime: '10:00 AM',
        endTime: '02:00 PM',
        location: 'Downtown Center',
        maxParticipants: 50,
        registeredCount: 12,
        status: AppConstants.eventStatusApproved,
        createdAt: now,
      );

      final map = event.toMap();
      final reconstructed = EventModel.fromMap(map, 'ev-2');

      expect(reconstructed.title, 'Art Showcase');
      expect(reconstructed.maxParticipants, 50);
      expect(reconstructed.category, 'arts_culture');
    });
  });

  group('RegistrationModel Tests', () {
    test('RegistrationModel creates and serializes properly', () {
      final reg = RegistrationModel(
        id: 'reg-001',
        eventId: 'ev-1',
        userId: 'u-123',
        userName: 'Jane Doe',
        userEmail: 'jane@example.com',
        eventTitle: 'Tech Summit',
        qrCode: 'EE:ev-1:reg-001:uuid',
        status: AppConstants.registrationStatusRegistered,
        registeredAt: DateTime.now(),
      );

      expect(reg.isRegistered, isTrue);
      expect(reg.isCancelled, isFalse);

      final map = reg.toMap();
      expect(map['qrCode'], contains('EE:ev-1'));
    });
  });

  group('AttendanceModel Tests', () {
    test('AttendanceModel serialization', () {
      final att = AttendanceModel(
        id: 'att-1',
        registrationId: 'reg-001',
        eventId: 'ev-1',
        userId: 'u-123',
        checkedInBy: 'org-1',
        checkedInAt: DateTime.now(),
        attended: true,
      );

      final map = att.toMap();
      expect(map['attended'], isTrue);
      expect(map['checkedInBy'], 'org-1');
    });
  });

  group('FeedbackModel Tests', () {
    test('FeedbackModel rating and comment assertions', () {
      final fb = FeedbackModel(
        id: 'fb-1',
        eventId: 'ev-1',
        userId: 'u-123',
        userName: 'Jane Doe',
        rating: 5,
        comment: 'Outstanding organization and speakers!',
        submittedAt: DateTime.now(),
      );

      expect(fb.rating, 5);
      expect(fb.comment, contains('Outstanding'));
    });
  });
}
