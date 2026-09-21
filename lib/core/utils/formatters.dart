import '../../features/places/domain/opening_hours.dart';

abstract final class Formatters {
  /// "850 m", "1.2 km", "14 km".
  static String distance(double meters) {
    if (meters < 1000) {
      final rounded = (meters / 10).round() * 10;
      return '${rounded < 10 ? 10 : rounded} m';
    }
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// "9 AM", "9:30 PM", "Midnight", "Noon".
  static String time(DateTime time) {
    if (time.hour == 0 && time.minute == 0) return 'Midnight';
    if (time.hour == 12 && time.minute == 0) return 'Noon';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    final minutes = time.minute == 0
        ? ''
        : ':${time.minute.toString().padLeft(2, '0')}';
    return '$hour$minutes $suffix';
  }

  /// Formats minutes since midnight, e.g. for a weekly hours table.
  static String minutes(int minutesSinceMidnight) => time(
    DateTime.utc(2024, 1, 1).add(Duration(minutes: minutesSinceMidnight)),
  );

  static String timeRange(TimeRange range) {
    if (range.isAllDay) return 'Open 24 hours';
    return '${minutes(range.open)} – ${minutes(range.close)}';
  }

  /// "₦₦" for a price level of 2.
  static String priceLevel(int level) => '₦' * level.clamp(1, 4);

  /// "312", "1.1k".
  static String compactCount(int count) {
    if (count < 1000) return '$count';
    final thousands = count / 1000;
    return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}k';
  }

  static const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const weekdaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}

enum OpenTone { open, closingSoon, closed }

/// Human wording for an [OpenStatus]: "Open · Closes 9 PM",
/// "Closed · Opens tomorrow 8 AM", "Open 24 hours".
class OpenStatusText {
  const OpenStatusText(this.headline, this.detail, this.tone);

  factory OpenStatusText.describe(OpenStatus status, DateTime now) {
    final change = status.nextChange;
    if (status.isOpen) {
      if (change == null) {
        return const OpenStatusText('Open 24 hours', '', OpenTone.open);
      }
      // Closing times are always within the next day, so the time alone
      // reads naturally, e.g. "Closes 2 AM" for a late-night spot.
      final closing = 'Closes ${_inline(change)}';
      return status.closesWithin(const Duration(hours: 1), now)
          ? OpenStatusText('Closes soon', closing, OpenTone.closingSoon)
          : OpenStatusText('Open', closing, OpenTone.open);
    }
    if (change == null) {
      return const OpenStatusText('Closed', '', OpenTone.closed);
    }
    return OpenStatusText(
      'Closed',
      'Opens ${_opening(change, now)}',
      OpenTone.closed,
    );
  }

  final String headline;
  final String detail;
  final OpenTone tone;

  static String _inline(DateTime time) => switch (Formatters.time(time)) {
    'Midnight' => 'midnight',
    'Noon' => 'noon',
    final other => other,
  };

  static String _opening(DateTime change, DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final day = DateTime.utc(change.year, change.month, change.day);
    final days = day.difference(today).inDays;
    final time = _inline(change);
    if (days <= 0) return time;
    if (days == 1) return 'tomorrow $time';
    return '${Formatters.weekdaysShort[change.weekday - 1]} $time';
  }
}
