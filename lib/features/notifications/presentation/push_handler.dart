import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../places/application/place_providers.dart';
import '../push_providers.dart';
import '../push_service.dart';
import 'notification_banner.dart';

/// Connects push notifications to the app: keeps the followed topic in step
/// with the selected city, opens places from tapped notifications, and
/// shows ones that arrive while the app is open as a banner.
class PushHandler extends ConsumerStatefulWidget {
  const PushHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushHandler> createState() => _PushHandlerState();
}

class _PushHandlerState extends ConsumerState<PushHandler> {
  static const _bannerDuration = Duration(seconds: 6);

  late final PushService _push = ref.read(pushServiceProvider);
  final _subscriptions = <StreamSubscription<PlaceNotification>>[];
  PlaceNotification? _banner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_push.opened.listen(_open))
      ..add(_push.received.listen(_show));
    if (ref.read(placeAlertsProvider)) {
      unawaited(_push.follow(ref.read(selectedCityProvider)));
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _open(PlaceNotification notification) {
    _dismiss();
    selectCityOfPlace(ref, notification.placeId);
    unawaited(ref.read(routerProvider).push('/place/${notification.placeId}'));
  }

  void _show(PlaceNotification notification) {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(_bannerDuration, _dismiss);
    setState(() => _banner = notification);
  }

  void _dismiss() {
    _bannerTimer?.cancel();
    if (mounted && _banner != null) setState(() => _banner = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCityProvider, (_, city) {
      if (ref.read(placeAlertsProvider)) unawaited(_push.follow(city));
    });

    final banner = _banner;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: banner == null
                    ? const SizedBox(width: double.infinity)
                    : NotificationBanner(
                        key: ObjectKey(banner),
                        notification: banner,
                        onTap: () => _open(banner),
                        onDismiss: _dismiss,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
