/// A single opening window, in minutes since midnight.
///
/// A [close] at or before [open] means the window runs past midnight
/// (e.g. a suya spot open 17:00–02:00).
class TimeRange {
  const TimeRange(this.open, this.close);

  /// Parses `"HH:MM-HH:MM"`. `"00:00-24:00"` means open all day.
  factory TimeRange.parse(String value) {
    final parts = value.split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid time range "$value"');
    }
    return TimeRange(_parseMinutes(parts[0]), _parseMinutes(parts[1]));
  }

  final int open;
  final int close;

  static const minutesPerDay = 24 * 60;

  bool get isAllDay => open == 0 && close == minutesPerDay;
  bool get isOvernight => !isAllDay && close <= open;

  static int _parseMinutes(String value) {
    final parts = value.trim().split(':');
    final hours = int.tryParse(parts.first);
    final minutes = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (parts.length != 2 || hours == null || minutes == null) {
      throw FormatException('Invalid time "$value"');
    }
    return hours * 60 + minutes;
  }

  String format() => '${_formatMinutes(open)}-${_formatMinutes(close)}';

  static String _formatMinutes(int value) {
    final h = (value ~/ 60).toString().padLeft(2, '0');
    final m = (value % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  bool operator ==(Object other) =>
      other is TimeRange && other.open == open && other.close == close;

  @override
  int get hashCode => Object.hash(open, close);
}

/// Whether a place is open at a given moment, and when that changes next.
class OpenStatus {
  const OpenStatus({required this.isOpen, this.nextChange});

  final bool isOpen;

  /// When the place next closes (if open) or opens (if closed).
  /// `null` when it never changes: open 24/7 or closed all week.
  final DateTime? nextChange;

  bool closesWithin(Duration window, DateTime now) {
    final change = nextChange;
    return isOpen && change != null && change.difference(now) <= window;
  }
}

/// Weekly opening hours, Monday to Sunday. A `null` day is closed.
class OpeningHours {
  OpeningHours(List<TimeRange?> days) : days = List.unmodifiable(days) {
    if (days.length != 7) {
      throw ArgumentError.value(days.length, 'days', 'Expected 7 days');
    }
  }

  factory OpeningHours.fromJson(List<Object?> json) => OpeningHours([
    for (final day in json) day == null ? null : TimeRange.parse(day as String),
  ]);

  final List<TimeRange?> days;

  List<String?> toJson() => [for (final day in days) day?.format()];

  bool get isAlwaysOpen => days.every((day) => day?.isAllDay ?? false);

  /// The hours for [weekday], using [DateTime.monday]..[DateTime.sunday].
  TimeRange? forWeekday(int weekday) => days[weekday - 1];

  /// Works out the status at [now], a wall-clock time in the place's
  /// time zone.
  OpenStatus statusAt(DateTime now) {
    if (isAlwaysOpen) return const OpenStatus(isOpen: true);

    final minute = now.hour * 60 + now.minute;
    final midnight = _midnightOf(now);
    DateTime at(int dayOffset, int minutes) =>
        midnight.add(Duration(days: dayOffset, minutes: minutes));

    // Still inside last night's late window?
    final yesterday = forWeekday(_shift(now.weekday, -1));
    if (yesterday != null &&
        yesterday.isOvernight &&
        minute < yesterday.close) {
      return OpenStatus(isOpen: true, nextChange: at(0, yesterday.close));
    }

    final today = forWeekday(now.weekday);
    if (today != null) {
      if (today.isAllDay) {
        return OpenStatus(isOpen: true, nextChange: _closingAfterAllDay(now));
      }
      if (today.isOvernight && minute >= today.open) {
        return OpenStatus(isOpen: true, nextChange: at(1, today.close));
      }
      if (minute >= today.open && minute < today.close) {
        return OpenStatus(isOpen: true, nextChange: at(0, today.close));
      }
      if (minute < today.open) {
        return OpenStatus(isOpen: false, nextChange: at(0, today.open));
      }
    }

    for (var offset = 1; offset <= 7; offset++) {
      final day = forWeekday(_shift(now.weekday, offset));
      if (day != null) {
        return OpenStatus(isOpen: false, nextChange: at(offset, day.open));
      }
    }
    return const OpenStatus(isOpen: false);
  }

  /// For an all-day window, the place closes at the end of the last
  /// consecutive all-day day.
  DateTime? _closingAfterAllDay(DateTime now) {
    final midnight = _midnightOf(now);
    for (var offset = 1; offset <= 7; offset++) {
      final day = forWeekday(_shift(now.weekday, offset));
      if (day == null || !day.isAllDay) {
        final closesAt = day != null && day.open == 0
            ? day.close
            : 0; // closes at midnight going into a non-24h day
        return midnight.add(Duration(days: offset, minutes: closesAt));
      }
    }
    return null;
  }

  static DateTime _midnightOf(DateTime time) => time.isUtc
      ? DateTime.utc(time.year, time.month, time.day)
      : DateTime(time.year, time.month, time.day);

  static int _shift(int weekday, int offset) => (weekday - 1 + offset) % 7 + 1;
}
