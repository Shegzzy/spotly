import 'package:flutter/material.dart';

import '../../places/presentation/common/floating_surface.dart';
import '../push_service.dart';

/// An in-app version of a push notification, for ones that arrive while
/// the app is open. Tap to open the place, or swipe it away.
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final PlaceNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  static const _brand = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = notification.title;
    final body = notification.body;

    return Dismissible(
      key: const ValueKey('notification-banner'),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Semantics(
        liveRegion: true,
        button: true,
        child: FloatingSurface(
          radius: 20,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _brand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'New place',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (body != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
