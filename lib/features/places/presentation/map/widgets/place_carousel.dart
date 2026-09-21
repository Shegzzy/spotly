import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/place.dart';
import '../../common/place_card.dart';

/// Swipeable cards for the current results, kept in sync with the selected
/// pin: tapping a pin scrolls here, swiping here selects the pin.
class PlaceCarousel extends StatefulWidget {
  const PlaceCarousel({
    super.key,
    required this.places,
    required this.selectedId,
    required this.now,
    required this.origin,
    required this.onSwiped,
    required this.onOpen,
  });

  final List<Place> places;
  final String selectedId;
  final DateTime now;
  final LatLng? origin;
  final ValueChanged<Place> onSwiped;
  final ValueChanged<Place> onOpen;

  @override
  State<PlaceCarousel> createState() => _PlaceCarouselState();
}

class _PlaceCarouselState extends State<PlaceCarousel> {
  static const _distance = Distance();

  late final PageController _pages = PageController(
    viewportFraction: 0.9,
    initialPage: _indexOf(widget.selectedId),
  );

  /// Set while we scroll programmatically, so intermediate pages we pass
  /// through don't count as the user choosing them.
  bool _scrollingToSelection = false;

  int _indexOf(String id) => widget.places
      .indexWhere((p) => p.id == id)
      .clamp(0, widget.places.length - 1);

  @override
  void didUpdateWidget(PlaceCarousel old) {
    super.didUpdateWidget(old);
    if (old.selectedId == widget.selectedId || !_pages.hasClients) return;
    final target = _indexOf(widget.selectedId);
    final current = _pages.page?.round();
    if (current == target) return;

    _scrollingToSelection = true;
    final jump = current == null || (current - target).abs() > 3;
    if (jump) {
      _pages.jumpToPage(target);
      _scrollingToSelection = false;
    } else {
      _pages
          .animateToPage(
            target,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() => _scrollingToSelection = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final origin = widget.origin;
    return SizedBox(
      height: PlaceCard.height,
      child: PageView.builder(
        controller: _pages,
        itemCount: widget.places.length,
        onPageChanged: (index) {
          if (!_scrollingToSelection) widget.onSwiped(widget.places[index]);
        },
        itemBuilder: (context, index) {
          final place = widget.places[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: PlaceCard(
              place: place,
              now: widget.now,
              distanceMeters: origin == null
                  ? null
                  : _distance.as(LengthUnit.Meter, origin, place.location),
              onTap: () => widget.onOpen(place),
            ),
          );
        },
      ),
    );
  }
}
