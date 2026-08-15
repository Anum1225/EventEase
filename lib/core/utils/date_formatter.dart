import 'package:intl/intl.dart';

/// Utilities for consistent date, time, and relative timestamp formatting
class DateFormatter {
  DateFormatter._();

  static final DateFormat _eventDateFormat = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

  static String formatDate(DateTime? date) {
    if (date == null) return 'TBA';
    return _shortDateFormat.format(date);
  }

  static String formatEventDate(DateTime? date) {
    if (date == null) return 'TBA';
    return _eventDateFormat.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return 'TBA';
    return _shortDateFormat.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'TBA';
    return _dateTimeFormat.format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return _shortDateFormat.format(date);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatEventSchedule(DateTime? date, String? startTime, String? endTime) {
    final dateStr = formatShortDate(date);
    if (startTime != null && endTime != null && startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$dateStr • $startTime - $endTime';
    } else if (startTime != null && startTime.isNotEmpty) {
      return '$dateStr • $startTime';
    }
    return dateStr;
  }
}
