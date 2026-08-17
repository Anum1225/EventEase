import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/core/utils/event_time_helper.dart';
import 'package:eventease/models/event_model.dart';
import 'package:eventease/core/constants/app_constants.dart';

void main() {
  group('EventTimeHelper Tests', () {
    test('parseTimeString correctly parses 12-hour format with AM/PM', () {
      final t1 = EventTimeHelper.parseTimeString('09:30 AM');
      expect(t1, isNotNull);
      expect(t1!.hour, 9);
      expect(t1.minute, 30);

      final t2 = EventTimeHelper.parseTimeString('05:45 PM');
      expect(t2, isNotNull);
      expect(t2!.hour, 17);
      expect(t2.minute, 45);

      final t3 = EventTimeHelper.parseTimeString('12:00 PM'); // Noon
      expect(t3, isNotNull);
      expect(t3!.hour, 12);
      expect(t3.minute, 0);

      final t4 = EventTimeHelper.parseTimeString('12:30 AM'); // Midnight
      expect(t4, isNotNull);
      expect(t4!.hour, 0);
      expect(t4.minute, 30);
    });

    test('parseTimeString handles 24-hour format fallback', () {
      final t = EventTimeHelper.parseTimeString('18:20');
      expect(t, isNotNull);
      expect(t!.hour, 18);
      expect(t.minute, 20);
    });

    test('getEventEndDateTime calculates exact timestamp', () {
      final date = DateTime(2026, 10, 25);
      final endDateTime = EventTimeHelper.getEventEndDateTime(date, '08:15 PM');

      expect(endDateTime.year, 2026);
      expect(endDateTime.month, 10);
      expect(endDateTime.day, 25);
      expect(endDateTime.hour, 20);
      expect(endDateTime.minute, 15);
    });

    test('hasEventEnded returns true when end time has passed', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final pastEvent = EventModel(
        id: 'ev-past',
        organizerId: 'org-1',
        title: 'Past Expo',
        description: 'Completed conference',
        category: 'technology',
        date: pastDate,
        startTime: '09:00 AM',
        endTime: '11:00 AM',
        location: 'Hall A',
        maxParticipants: 50,
        registeredCount: 30,
        status: AppConstants.eventStatusApproved,
        createdAt: pastDate,
      );

      expect(EventTimeHelper.hasEventEnded(pastEvent), isTrue);

      final futureDate = DateTime.now().add(const Duration(days: 2));
      final futureEvent = EventModel(
        id: 'ev-future',
        organizerId: 'org-1',
        title: 'Upcoming Expo',
        description: 'Future conference',
        category: 'technology',
        date: futureDate,
        startTime: '09:00 AM',
        endTime: '11:00 AM',
        location: 'Hall A',
        maxParticipants: 50,
        registeredCount: 10,
        status: AppConstants.eventStatusApproved,
        createdAt: DateTime.now(),
      );

      expect(EventTimeHelper.hasEventEnded(futureEvent), isFalse);
    });
  });
}
