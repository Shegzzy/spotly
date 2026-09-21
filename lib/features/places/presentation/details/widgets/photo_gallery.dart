import 'package:flutter/material.dart';

import '../../../domain/place.dart';
import '../../common/place_photo.dart';

/// A horizontal strip of a place's photos. Tapping one opens a full-screen
/// viewer.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: place.photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Semantics(
          button: true,
          label: 'Photo ${index + 1} of ${place.photos.length}',
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder<void>(
                opaque: false,
                barrierColor: Colors.black,
                pageBuilder: (_, _, _) =>
                    _PhotoViewer(place: place, initialIndex: index),
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PlacePhoto(
                url: place.photos[index],
                category: place.category,
                width: 168,
                height: 120,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.place, required this.initialIndex});

  final Place place;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.place.photos;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: photos.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: PlacePhoto(
                    url: photos[index],
                    category: widget.place.category,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} / ${photos.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
