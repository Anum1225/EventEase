import 'package:flutter/material.dart';
import '../../models/event_model.dart';

/// Helper utility for calculating event schedules, end times, and automatic expiration
class EventTimeHelper {
  EventTimeHelper._();

  /// Parse time string (e.g. '05:00 PM', '5:00pm', '17:00') into TimeOfDay
  static TimeOfDay? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean.contains('AM') || clean.contains('PM')) {
        final isPm = clean.contains('PM');
        final timePart = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = timePart.split(':');
        if (parts.length >= 2) {
          var hour = int.parse(parts[0].trim());
          final minute = int.parse(parts[1].trim());
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      final parts = clean.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  /// Combine event date with its endTime string into a precise DateTime
  static DateTime getEventEndDateTime(DateTime eventDate, String? endTimeStr) {
    final parsedTime = parseTimeString(endTimeStr) ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  /// Combine event date with its startTime string into a precise DateTime
  static DateTime getEventStartDateTime(DateTime eventDate, String? startTimeStr) {
    final parsedTime = parseTimeString(startTimeStr) ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  /// Check whether an event has passed its scheduled end time
  static bool hasEventEnded(EventModel event) {
    if (event.isCompleted) return true;
    if (event.isCancelled || event.isRejected) return false;

    final endDateTime = getEventEndDateTime(event.date, event.endTime);
    return DateTime.now().isAfter(endDateTime);
  }

  /// Check whether an event is currently happening live
  static bool isEventLive(EventModel event) {
    if (event.isCompleted || event.isCancelled || event.isRejected) return false;
    final now = DateTime.now();
    final start = getEventStartDateTime(event.date, event.startTime);
    final end = getEventEndDateTime(event.date, event.endTime);
    return now.isAfter(start) && now.isBefore(end);
  }
}
