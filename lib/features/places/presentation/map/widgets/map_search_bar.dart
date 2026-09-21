import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../settings/theme_mode_controller.dart';
import '../../../application/place_providers.dart';
import '../../common/floating_surface.dart';

/// The pill-shaped search field at the top of the map, with a clear button
/// and the light/dark toggle.
class MapSearchBar extends ConsumerStatefulWidget {
  const MapSearchBar({super.key, required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  late final _controller = TextEditingController(
    text: ref.read(placeFilterProvider).query,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // Show or hide the clear button.
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => ref.read(placeFilterProvider.notifier).setQuery(value),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    ref.read(placeFilterProvider.notifier).setQuery(value);
    widget.onSubmitted();
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {});
    ref.read(placeFilterProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    // Keep the field in sync when the query is cleared elsewhere, e.g. from
    // the "Clear filters" button.
    ref.listen(placeFilterProvider.select((f) => f.query), (_, query) {
      if (query != _controller.text && !(_debounce?.isActive ?? false)) {
        _controller.text = query;
        setState(() {});
      }
    });

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;

    return FloatingSurface(
      radius: 18,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                onSubmitted: _submit,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: 'Search salons, food, pharmacies…',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: muted,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _controller.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      key: const ValueKey('clear'),
                      tooltip: 'Clear search',
                      onPressed: _clear,
                      icon: Icon(Icons.close_rounded, color: muted, size: 20),
                    ),
            ),
            Container(width: 1, height: 24, color: theme.colorScheme.outline),
            IconButton(
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggle(theme.brightness),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: 0.6, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
