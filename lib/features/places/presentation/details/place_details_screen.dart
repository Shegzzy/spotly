import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/place_providers.dart';
import '../../domain/place.dart';
import '../common/category_visuals.dart';
import '../common/place_card.dart';
import '../common/place_meta.dart';
import '../common/place_photo.dart';
import 'place_actions.dart';
import 'widgets/location_preview.dart';
import 'widgets/opening_hours_table.dart';
import 'widgets/photo_gallery.dart';

class PlaceDetailsScreen extends ConsumerWidget {
  const PlaceDetailsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(placeByIdProvider(placeId))) {
      AsyncData(value: final place?) => _PlaceDetailsView(place: place),
      AsyncData() => const _MessageScaffold(
        icon: Icons.wrong_location_rounded,
        title: 'Place not found',
        message: 'It may have been removed. Head back to the map.',
      ),
      AsyncError() => _MessageScaffold(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load this place',
        message: 'Check your connection and try again.',
        onRetry: () => ref.invalidate(placesProvider),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _PlaceDetailsView extends ConsumerStatefulWidget {
  const _PlaceDetailsView({required this.place});

  final Place place;

  @override
  ConsumerState<_PlaceDetailsView> createState() => _PlaceDetailsViewState();
}

class _PlaceDetailsViewState extends ConsumerState<_PlaceDetailsView> {
  static const _headerHeight = 340.0;
  static const _distance = Distance();

  final _scroll = ScrollController();

  /// True once the photo has scrolled away and the bar is solid.
  final _collapsed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final threshold =
          _headerHeight -
          kToolbarHeight -
          MediaQuery.paddingOf(context).top -
          24;
      _collapsed.value = _scroll.offset > threshold;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);
    final palette = context.palette;
    final categoryColor = palette.category(place.category);
    final now = ref.watch(watNowProvider).value ?? watNow();
    final origin = ref.watch(nearbyOriginProvider(place.city));
    final distance = origin == null
        ? null
        : _distance.as(LengthUnit.Meter, origin, place.location);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: _collapsed,
      builder: (context, collapsed, child) =>
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: collapsed && !isDark
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            child: child!,
          ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: _headerHeight,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _HeaderButton(
                  collapsed: _collapsed,
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              actions: [
                Builder(
                  builder: (context) => _HeaderButton(
                    collapsed: _collapsed,
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Share',
                    onPressed: () => PlaceActions.share(context, place),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              title: ValueListenableBuilder<bool>(
                valueListenable: _collapsed,
                builder: (context, collapsed, _) => AnimatedOpacity(
                  opacity: collapsed ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Text(place.name),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: placePhotoHeroTag(place),
                      child: PlacePhoto(
                        url: place.coverPhoto,
                        category: place.category,
                        iconSize: 64,
                        lowResWidth: PlaceCard.photoWidth,
                      ),
                    ),
                    // Keeps the status bar and buttons legible on bright
                    // photos.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.35, 0.7, 1],
                          colors: [
                            Color(0x8C000000),
                            Color(0x00000000),
                            Color(0x00000000),
                            Color(0x33000000),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CategoryBadge(place: place),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            place.area,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (distance != null) ...[
                          Text(
                            '  ·  ${Formatters.distance(distance)} away',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(place.name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    RatingRow(
                      place: place,
                      style: theme.textTheme.bodyMedium,
                      spellOutReviews: true,
                    ),
                    const SizedBox(height: 8),
                    OpenStatusLabel(
                      place: place,
                      now: now,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.directions_rounded,
                            label: 'Directions',
                            background: categoryColor,
                            foreground: Colors.white,
                            onPressed: () =>
                                PlaceActions.openDirections(context, place),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.call_rounded,
                            label: 'Call',
                            onPressed: place.phone == null
                                ? null
                                : () => PlaceActions.call(context, place),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Builder(
                            builder: (context) => _ActionButton(
                              icon: Icons.ios_share_rounded,
                              label: 'Share',
                              onPressed: () =>
                                  PlaceActions.share(context, place),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (place.description.isNotEmpty)
              _Section(
                title: 'About',
                child: Text(
                  place.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ),
            if (place.tags.isNotEmpty)
              _Section(
                title: 'Highlights',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in place.tags)
                      _TagChip(label: tag, color: categoryColor),
                  ],
                ),
              ),
            _Section(
              title: 'Opening hours',
              trailing: Text(
                '${place.city.label} time',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              child: OpeningHoursTable(
                hours: place.hours,
                today: now.weekday,
                highlight: categoryColor,
              ),
            ),
            _Section(
              title: 'Location',
              child: LocationPreview(
                place: place,
                onOpenDirections: () =>
                    PlaceActions.openDirections(context, place),
                onCopyAddress: () => PlaceActions.copyAddress(context, place),
              ),
            ),
            if (place.photos.length > 1)
              _Section(
                title: 'Photos',
                padChild: false,
                child: PhotoStrip(place: place),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  32,
                  20,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                child: Text(
                  'Sample business listing for demo purposes. '
                  'Photos from Unsplash.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back/share buttons that sit on a dark disc over the photo and blend
/// into the bar once it collapses.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.collapsed,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final ValueNotifier<bool> collapsed;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: collapsed,
      builder: (context, isCollapsed, _) => Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCollapsed
                ? theme.colorScheme.surfaceContainerHigh
                : Colors.black.withValues(alpha: 0.35),
          ),
          child: IconButton(
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            iconSize: 20,
            color: isCollapsed ? theme.colorScheme.onSurface : Colors.white,
            onPressed: onPressed,
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.palette.category(place.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.categoryContainer(
          place.category,
          theme.brightness,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(place.category.icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            place.category.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final bg = background ?? theme.colorScheme.surfaceContainerHigh;
    final fg = foreground ?? theme.colorScheme.onSurface;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
    this.padChild = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  /// Horizontal lists scroll edge to edge, so they skip the side padding.
  final bool padChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidget = trailing;
    return SliverPadding(
      padding: const EdgeInsets.only(top: 30),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  ?trailingWidget,
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (padChild)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = onRetry;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (retry != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: retry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
