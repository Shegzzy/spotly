import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../location/user_location.dart';
import '../../common/floating_surface.dart';

/// Circular "centre on me" button.
class LocateMeButton extends StatelessWidget {
  const LocateMeButton({
    super.key,
    required this.access,
    required this.busy,
    required this.onPressed,
  });

  final LocationAccess? access;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (access) {
      LocationAccess.granted => Icons.my_location_rounded,
      null => Icons.location_searching_rounded,
      _ => Icons.location_disabled_rounded,
    };

    return Semantics(
      button: true,
      label: 'Show my location',
      excludeSemantics: true,
      child: FloatingSurface(
        radius: 16,
        onTap: busy ? null : onPressed,
        child: SizedBox.square(
          dimension: 50,
          child: Center(
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Icon(icon, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Map data credit required by OpenStreetMap.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      link: true,
      label: 'Map data credits',
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '© OpenStreetMap contributors',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
