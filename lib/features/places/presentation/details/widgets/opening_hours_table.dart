import 'package:flutter/material.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/opening_hours.dart';

/// Monday–Sunday hours with today highlighted.
class OpeningHoursTable extends StatelessWidget {
  const OpeningHoursTable({
    super.key,
    required this.hours,
    required this.today,
    required this.highlight,
  });

  final OpeningHours hours;

  /// [DateTime.monday]..[DateTime.sunday].
  final int today;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (hours.isAlwaysOpen) {
      return _Container(
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: highlight, size: 20),
            const SizedBox(width: 10),
            Text('Open 24 hours, every day', style: theme.textTheme.titleSmall),
          ],
        ),
      );
    }

    return _Container(
      child: Column(
        children: [
          for (var weekday = 1; weekday <= 7; weekday++)
            _DayRow(
              day: Formatters.weekdays[weekday - 1],
              range: hours.forWeekday(weekday),
              isToday: weekday == today,
              highlight: highlight,
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.range,
    required this.isToday,
    required this.highlight,
  });

  final String day;
  final TimeRange? range;
  final bool isToday;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = range;
    final base = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
      color: isToday ? theme.colorScheme.onSurface : null,
    );

    return Semantics(
      label:
          '$day${isToday ? ', today' : ''}: '
          '${hours == null ? 'closed' : Formatters.timeRange(hours)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              child: isToday
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: highlight,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            Expanded(child: Text(day, style: base)),
            Text(
              hours == null ? 'Closed' : Formatters.timeRange(hours),
              style: base.copyWith(
                color: hours == null
                    ? theme.colorScheme.onSurfaceVariant
                    : base.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Container extends StatelessWidget {
  const _Container({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
