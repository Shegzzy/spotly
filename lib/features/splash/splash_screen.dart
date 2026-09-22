import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../notifications/push_providers.dart';
import '../places/application/place_providers.dart';

/// Picks up exactly where the native launch screen leaves off (same colour,
/// same logo at the same size and position), plays a short "pin drop"
/// intro while places load, then hands over to the map, or to a place if a
/// notification launched the app.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const background = Color(0xFF0B0D12);
  static const logoAsset = 'assets/splash/splash_logo.png';

  /// The native splash draws [logoAsset] in a 288pt box, centred.
  static const logoSize = 288.0;

  /// Where the pin's tip sits inside the logo box, measured from the top.
  static const _pinTip = 209.0;

  /// How far the logo rises to make room for the wordmark.
  static const _lift = 60.0;

  static const _intro = Duration(milliseconds: 1100);

  /// The longest we hold the splash waiting for places. The map has its own
  /// loading state, so a slow backend never keeps anyone staring at a logo.
  static const _maxWait = Duration(milliseconds: 2600);

  /// Decodes the logo before the first frame so the native-to-Flutter
  /// hand-off never shows an empty frame.
  static Future<void> precacheLogo() {
    final done = Completer<void>();
    final stream = const AssetImage(
      logoAsset,
    ).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        stream.removeListener(listener);
        done.complete();
      },
      onError: (_, _) {
        stream.removeListener(listener);
        done.complete();
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SplashScreen._intro,
  );

  late final _lift = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 0.6, curve: Curves.easeInOutCubic),
  );
  late final _ping = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
  );
  late final _wordmark = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
  );
  late final _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run(reduceMotion: MediaQuery.disableAnimationsOf(context)));
  }

  Future<void> _run({required bool reduceMotion}) async {
    // Start loading now so the map opens with its pins already in place.
    final places = ref
        .read(placesProvider.future)
        .then<void>((_) {}, onError: (_) {})
        .timeout(SplashScreen._maxWait, onTimeout: () {});
    final notification = ref.read(pushServiceProvider).launchNotification();
    if (reduceMotion) _controller.value = 1;
    final intro = reduceMotion
        ? Future<void>.value()
        : _controller.forward().orCancel.catchError((_) {});
    await Future.wait([intro, places]);
    final placeId = (await notification)?.placeId;
    if (!mounted) return;
    if (placeId == null) {
      context.go('/');
    } else {
      selectCityOfPlace(ref, placeId);
      context.go('/place/$placeId');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const box = SplashScreen.logoSize;
    const tip = SplashScreen._pinTip;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: SplashScreen.background,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Transform.translate(
              offset: Offset(0, -SplashScreen._lift * _lift.value),
              child: SizedBox.square(
                dimension: box,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // A ripple on the "ground" where the pin lands.
                    Positioned(
                      top: tip - 14,
                      child: _PingRing(progress: _ping.value),
                    ),
                    const Image(
                      image: AssetImage(SplashScreen.logoAsset),
                      width: box,
                      height: box,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                    ),
                    Positioned(
                      top: tip + 30,
                      left: -box,
                      right: -box,
                      child: Column(
                        children: [
                          _Reveal(
                            progress: _wordmark.value,
                            child: Text(
                              AppConstants.appName,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _Reveal(
                            progress: _tagline.value,
                            child: Text(
                              AppConstants.tagline,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and rises into place as [progress] goes from 0 to 1.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress,
    child: Transform.translate(
      offset: Offset(0, 14 * (1 - progress)),
      child: child,
    ),
  );
}

/// A flattened ring that spreads out and fades, like a pin hitting a map.
class _PingRing extends StatelessWidget {
  const _PingRing({required this.progress});

  final double progress;

  static const _maxWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    final width = _maxWidth * progress;
    return Opacity(
      opacity: (1 - progress) * 0.9,
      child: SizedBox(
        width: _maxWidth,
        height: 28,
        child: Center(
          child: Container(
            width: width,
            height: width * 0.28,
            decoration: const ShapeDecoration(
              shape: OvalBorder(
                side: BorderSide(color: Color(0xFFF97316), width: 2.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
