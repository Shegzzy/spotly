import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';

/// The familiar blue "you are here" dot with a soft pulse.
class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  static const size = 64.0;

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Your location',
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeOut.transform(_pulse.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 18 + 44 * t,
                  height: 18 + 44 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.userLocation.withValues(
                      alpha: 0.35 * (1 - t),
                    ),
                  ),
                ),
                child!,
              ],
            );
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.userLocation,
              border: Border.all(color: palette.markerRing, width: 3),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
